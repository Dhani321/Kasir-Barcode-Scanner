<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use App\Models\Transaction;
use App\Models\TransactionItem;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ReportController extends Controller
{
    // GET /api/reports/sales  — dashboard summary + transaction list
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
}
