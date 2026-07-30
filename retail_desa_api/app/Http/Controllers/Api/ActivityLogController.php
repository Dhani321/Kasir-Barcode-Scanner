<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ActivityLog;
use Illuminate\Http\Request;

class ActivityLogController extends Controller
{
    // GET /api/activity-logs
    public function index(Request $request)
    {
        $query = ActivityLog::with(['user:id,name,role', 'product:id,name,sku'])
            ->orderBy('created_at', 'desc');

        if ($request->filled('search')) {
            $s = $request->search;
            $query->where(function ($q) use ($s) {
                $q->where('product_name', 'like', "%$s%")
                  ->orWhere('sku', 'like', "%$s%")
                  ->orWhere('user_name', 'like', "%$s%")
                  ->orWhere('description', 'like', "%$s%");
            });
        }

        if ($request->filled('action')) {
            $query->where('action', $request->action);
        }

        if ($request->filled('user_id')) {
            $query->where('user_id', $request->user_id);
        }

        if ($request->filled('date_from')) {
            $query->whereDate('created_at', '>=', $request->date_from);
        }

        if ($request->filled('date_to')) {
            $query->whereDate('created_at', '<=', $request->date_to);
        }

        $logs = $query->paginate($request->get('per_page', 30));

        return response()->json($logs);
    }
}
