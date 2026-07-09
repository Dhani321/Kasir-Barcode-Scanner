<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use App\Models\Shift;
use App\Models\Transaction;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class TransactionController extends Controller
{
    // GET /api/transactions
    public function index(Request $request)
    {
        $query = Transaction::with(['kasir:id,name,employee_id', 'items'])
            ->orderBy('created_at', 'desc');

        if ($request->filled('kasir_id'))  $query->where('kasir_id', $request->kasir_id);
        if ($request->filled('shift_id'))  $query->where('shift_id', $request->shift_id);
        if ($request->filled('status'))    $query->where('status', $request->status);
        if ($request->filled('date'))      $query->whereDate('created_at', $request->date);
        if ($request->filled('date_from')) $query->whereDate('created_at', '>=', $request->date_from);
        if ($request->filled('date_to'))   $query->whereDate('created_at', '<=', $request->date_to);

        return response()->json($query->paginate($request->get('per_page', 20)));
    }

    // POST /api/transactions
    public function store(Request $request)
    {
        $request->validate([
            'items'          => 'required|array|min:1',
            'items.*.product_id' => 'required|exists:products,id',
            'items.*.qty'    => 'required|integer|min:1',
            'payment_method' => 'required|in:cash,card,digital',
            'payment_amount' => 'required|numeric|min:0',
            'customer_name'  => 'nullable|string',
        ]);

        DB::beginTransaction();
        try {
            $kasir = $request->user();

            // Find active shift
            $shift = Shift::where('kasir_id', $kasir->id)
                          ->where('status', 'active')->latest()->first();

            if (!$shift) {
                DB::rollBack();
                return response()->json(['message' => 'Anda harus membuka shift terlebih dahulu.'], 403);
            }

            $subtotal = 0;
            $itemsData = [];

            foreach ($request->items as $item) {
                $product = Product::findOrFail($item['product_id']);

                if ($product->stock < $item['qty']) {
                    DB::rollBack();
                    return response()->json([
                        'message' => "Stok {$product->name} tidak cukup. Sisa: {$product->stock}",
                    ], 422);
                }

                $lineTotal = $product->price * $item['qty'];
                $subtotal += $lineTotal;

                $itemsData[] = [
                    'product_id'   => $product->id,
                    'product_name' => $product->name,
                    'product_sku'  => $product->sku,
                    'price'        => $product->price,
                    'qty'          => $item['qty'],
                    'subtotal'     => $lineTotal,
                    'discount'     => $item['discount'] ?? 0,
                ];

                // Deduct stock
                $product->decrement('stock', $item['qty']);
            }

            $taxRate = (float) (\App\Models\Setting::get('tax_rate', '10'));
            $tax     = round($subtotal * ($taxRate / 100), 2);
            $total   = $subtotal + $tax;
            $change  = $request->payment_amount - $total;

            $transaction = Transaction::create([
                'transaction_number' => Transaction::generateNumber(),
                'kasir_id'           => $kasir->id,
                'shift_id'           => $shift?->id,
                'subtotal'           => $subtotal,
                'tax'                => $tax,
                'grand_total'        => $total,
                'payment_method'     => $request->payment_method,
                'payment_amount'     => $request->payment_amount,
                'change_amount'      => max(0, $change),
                'status'             => 'completed',
                'customer_name'      => $request->customer_name,
            ]);

            $transaction->items()->createMany($itemsData);

            // Update shift totals
            if ($shift) {
                $shift->increment('total_sales', $total);
                $shift->increment('total_transactions');
            }

            DB::commit();

            return response()->json(
                $transaction->load(['items', 'kasir:id,name,employee_id']),
                201
            );
        } catch (\Throwable $e) {
            DB::rollBack();
            return response()->json(['message' => 'Terjadi kesalahan: ' . $e->getMessage()], 500);
        }
    }

    // GET /api/transactions/{id}
    public function show(Transaction $transaction)
    {
        return response()->json($transaction->load(['items', 'kasir:id,name', 'shift']));
    }

    // PATCH /api/transactions/{id}/void
    public function void(Transaction $transaction)
    {
        if ($transaction->status !== 'completed') {
            return response()->json(['message' => 'Transaksi tidak bisa di-void.'], 422);
        }

        DB::beginTransaction();
        try {
            // Restore stock
            foreach ($transaction->items as $item) {
                Product::find($item->product_id)?->increment('stock', $item->qty);
            }

            $transaction->update(['status' => 'void']);

            // Adjust shift
            if ($transaction->shift_id) {
                $shift = Shift::find($transaction->shift_id);
                $shift?->decrement('total_sales', $transaction->grand_total);
                $shift?->decrement('total_transactions');
            }

            DB::commit();
            return response()->json(['message' => 'Transaksi berhasil di-void.', 'transaction' => $transaction]);
        } catch (\Throwable $e) {
            DB::rollBack();
            return response()->json(['message' => $e->getMessage()], 500);
        }
    }
}
