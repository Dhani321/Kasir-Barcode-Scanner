<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use App\Models\Transaction;
use App\Models\TransactionItem;
use App\Models\ActivityLog;
use App\Models\Shift;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ReportController extends Controller
{
    // GET /api/reports/sales — dashboard summary + transaction list
    public function sales(Request $request)
    {
        $dateFrom = $request->get('date_from', now()->toDateString());
        $dateTo   = $request->get('date_to', now()->toDateString());

        $transactions = Transaction::with(['kasir:id,name,employee_id', 'items'])
            ->where('status', 'completed')
            ->whereBetween(DB::raw('DATE(created_at)'), [$dateFrom, $dateTo])
            ->orderBy('created_at', 'desc')
            ->get();

        $totalSales        = $transactions->sum('grand_total');
        $totalTransactions = $transactions->count();
        $avgTransaction    = $totalTransactions > 0
                           ? $totalSales / $totalTransactions : 0;

        // Top products
        $topProducts = TransactionItem::select('product_name', DB::raw('SUM(qty) as total_qty'),
                           DB::raw('SUM(subtotal) as total_revenue'))
            ->whereIn('transaction_id', $transactions->pluck('id'))
            ->groupBy('product_name')
            ->orderByDesc('total_qty')
            ->limit(5)
            ->get();

        // Sales per payment method
        $byMethod = $transactions->groupBy('payment_method')
            ->map(fn($g) => ['count' => $g->count(), 'total' => $g->sum('grand_total')]);

        // Low stock alerts
        $lowStock = Product::active()->lowStock()
            ->select('id', 'name', 'sku', 'stock', 'min_stock')->get();

        return response()->json([
            'summary' => [
                'total_sales'        => $totalSales,
                'total_transactions' => $totalTransactions,
                'avg_transaction'    => round($avgTransaction, 2),
                'low_stock_count'    => $lowStock->count(),
            ],
            'top_products'  => $topProducts,
            'by_method'     => $byMethod,
            'transactions'  => $transactions,
            'low_stock'     => $lowStock,
            'date_from'     => $dateFrom,
            'date_to'       => $dateTo,
        ]);
    }

    // GET /api/reports/shift/{shift_id}
    public function shiftReport(Request $request, $shiftId)
    {
        $shift = Shift::with(['kasir:id,name,employee_id'])->find($shiftId);
        $transactions = Transaction::with('items')
            ->where('shift_id', $shiftId)
            ->where('status', 'completed')
            ->orderBy('created_at', 'desc')
            ->get();

        $totalSales     = $transactions->sum('grand_total');
        $totalItems     = $transactions->flatMap->items->sum('qty');
        $totalCash      = $transactions->where('payment_method', 'cash')->sum('grand_total');
        $totalCard      = $transactions->where('payment_method', 'card')->sum('grand_total');
        $totalDigital   = $transactions->where('payment_method', 'digital')->sum('grand_total');

        return response()->json([
            'shift'   => $shift,
            'summary' => [
                'total_sales'        => $totalSales,
                'total_transactions' => $transactions->count(),
                'total_items'        => $totalItems,
                'cash'               => $totalCash,
                'card'               => $totalCard,
                'digital'            => $totalDigital,
            ],
            'transactions' => $transactions,
        ]);
    }

    // GET /api/reports/dashboard — quick stats for admin dashboard widget
    public function dashboard()
    {
        $today = now()->toDateString();

        $todaySales = Transaction::where('status', 'completed')
            ->whereDate('created_at', $today)->sum('grand_total');
        $todayCount = Transaction::where('status', 'completed')
            ->whereDate('created_at', $today)->count();
        $lowStock   = Product::active()->lowStock()->count();

        // Weekly sales (last 7 days)
        $weekly = Transaction::select(
                DB::raw('DATE(created_at) as date'),
                DB::raw('SUM(grand_total) as total')
            )->where('status', 'completed')
             ->whereBetween(DB::raw('DATE(created_at)'), [
                 now()->subDays(6)->toDateString(), $today
             ])
             ->groupBy('date')
             ->orderBy('date')
             ->get();

        return response()->json([
            'today_sales'        => $todaySales,
            'today_transactions' => $todayCount,
            'low_stock_count'    => $lowStock,
            'weekly_sales'       => $weekly,
        ]);
    }

    // GET /api/reports/stock-movement — Monthly Stock In & Out report
    public function stockMovement(Request $request)
    {
        $month = (int) $request->get('month', date('n'));
        $year  = (int) $request->get('year', date('Y'));

        $logs = ActivityLog::whereYear('created_at', $year)
            ->whereMonth('created_at', $month)
            ->orderBy('created_at', 'desc')
            ->get();

        // Separate into Stock In (qty_change > 0 or create_product/add_stock)
        $stockInLogs = $logs->filter(fn($l) => $l->qty_change > 0 || in_array($l->action, ['create_product', 'add_stock']));
        
        // Separate into Stock Out (qty_change < 0 or sale_stock_out/reduce_stock)
        $stockOutLogs = $logs->filter(fn($l) => $l->qty_change < 0 || in_array($l->action, ['sale_stock_out', 'reduce_stock']));

        $totalStockIn  = $stockInLogs->sum(fn($l) => max(0, $l->qty_change));
        $totalStockOut = $stockOutLogs->sum(fn($l) => abs(min(0, $l->qty_change)));

        return response()->json([
            'month'          => $month,
            'year'           => $year,
            'summary'        => [
                'total_stock_in'  => $totalStockIn,
                'total_stock_out' => $totalStockOut,
                'count_in_logs'   => $stockInLogs->count(),
                'count_out_logs'  => $stockOutLogs->count(),
            ],
            'stock_in_logs'  => $stockInLogs->values(),
            'stock_out_logs' => $stockOutLogs->values(),
            'all_logs'       => $logs->values(),
        ]);
    }

    // GET /api/reports/cashier-shifts — Monthly Cashier Shift Report
    public function cashierShifts(Request $request)
    {
        $month   = (int) $request->get('month', date('n'));
        $year    = (int) $request->get('year', date('Y'));
        $kasirId = $request->get('kasir_id');

        $query = Shift::with(['kasir:id,name,employee_id'])
            ->whereYear('start_time', $year)
            ->whereMonth('start_time', $month)
            ->orderBy('start_time', 'desc');

        if ($kasirId && $kasirId !== 'all') {
            $query->where('kasir_id', $kasirId);
        }

        $shifts = $query->get();

        $totalSales        = $shifts->sum('total_sales');
        $totalTransactions = $shifts->sum('total_transactions');
        $totalShifts       = $shifts->count();
        $avgSalesPerShift  = $totalShifts > 0 ? $totalSales / $totalShifts : 0;

        return response()->json([
            'month'     => $month,
            'year'      => $year,
            'kasir_id'  => $kasirId,
            'summary'   => [
                'total_shifts'        => $totalShifts,
                'total_sales'         => $totalSales,
                'total_transactions'  => $totalTransactions,
                'avg_sales_per_shift' => round($avgSalesPerShift, 2),
            ],
            'shifts'    => $shifts,
        ]);
    }

    // GET /api/reports/item-sales — Monthly sales report per item
    public function itemSales(Request $request)
    {
        $month = (int) $request->get('month', date('n'));
        $year  = (int) $request->get('year', date('Y'));

        $items = TransactionItem::with(['product:id,name,sku,category'])
            ->whereHas('transaction', function ($q) use ($month, $year) {
                $q->where('status', 'completed')
                  ->whereYear('created_at', $year)
                  ->whereMonth('created_at', $month);
            })
            ->select(
                'product_id',
                'product_name',
                'product_sku',
                DB::raw('SUM(qty) as total_qty'),
                DB::raw('AVG(price) as avg_price'),
                DB::raw('SUM(subtotal) as total_revenue')
            )
            ->groupBy('product_id', 'product_name', 'product_sku')
            ->orderByDesc('total_qty')
            ->get();

        $totalRevenue  = $items->sum('total_revenue');
        $totalUnits    = $items->sum('total_qty');
        $distinctCount = $items->count();
        $topSeller     = $items->first();

        return response()->json([
            'month'      => $month,
            'year'       => $year,
            'summary'    => [
                'total_revenue'      => $totalRevenue,
                'total_units_sold'   => $totalUnits,
                'distinct_items'     => $distinctCount,
                'top_selling_item'   => $topSeller ? [
                    'name'      => $topSeller->product_name,
                    'sku'       => $topSeller->product_sku,
                    'total_qty' => (int) $topSeller->total_qty,
                    'revenue'   => (float) $topSeller->total_revenue,
                ] : null,
            ],
            'items'      => $items->map(function ($i) {
                return [
                    'product_id'   => $i->product_id,
                    'product_name' => $i->product_name,
                    'product_sku'  => $i->product_sku,
                    'category'     => $i->product?->category ?? 'Umum',
                    'total_qty'    => (int) $i->total_qty,
                    'price'        => (float) $i->avg_price,
                    'total_revenue'=> (float) $i->total_revenue,
                ];
            }),
        ]);
    }
}
