<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Shift;
use Illuminate\Http\Request;

class ShiftController extends Controller
{
    // POST /api/shifts/open — Open shift
    public function open(Request $request)
    {
        $kasir = $request->user();

        $existing = Shift::where('kasir_id', $kasir->id)
                         ->where('status', 'active')->first();
        if ($existing) {
            return response()->json(['message' => 'Anda sudah memiliki shift aktif.', 'shift' => $existing], 200);
        }

        $shift = Shift::create([
            'kasir_id'     => $kasir->id,
            'start_time'   => now(),
            'opening_cash' => $request->get('opening_cash', 0),
            'status'       => 'active',
        ]);

        return response()->json($shift->load('kasir:id,name'), 201);
    }

    // POST /api/shifts/close — Close current shift
    public function close(Request $request)
    {
        $kasir = $request->user();
        $shift = Shift::where('kasir_id', $kasir->id)
                      ->where('status', 'active')->latest()->first();

        if (!$shift) {
            return response()->json(['message' => 'Tidak ada shift aktif.'], 404);
        }

        $shift->update([
            'end_time'     => now(),
            'closing_cash' => $request->get('closing_cash', 0),
            'notes'        => $request->get('notes'),
            'status'       => 'closed',
        ]);

        return response()->json($shift->load(['kasir:id,name', 'transactions']));
    }

    // GET /api/shifts/current — Get current active shift
    public function current(Request $request)
    {
        $shift = Shift::where('kasir_id', $request->user()->id)
                      ->where('status', 'active')->latest()->first();

        if (!$shift) {
            return response()->json(['message' => 'Tidak ada shift aktif.'], 404);
        }

        return response()->json($shift->load('kasir:id,name'));
    }

    // GET /api/shifts — List shifts (admin)
    public function index(Request $request)
    {
        $query = Shift::with('kasir:id,name,employee_id')->orderBy('created_at', 'desc');
        if ($request->filled('kasir_id')) $query->where('kasir_id', $request->kasir_id);
        if ($request->filled('status'))   $query->where('status', $request->status);
        if ($request->filled('date'))     $query->whereDate('start_time', $request->date);
        return response()->json($query->paginate(20));
    }

    // GET /api/shifts/{id}
    public function show(Shift $shift)
    {
        return response()->json($shift->load(['kasir:id,name', 'transactions.items']));
    }
}
