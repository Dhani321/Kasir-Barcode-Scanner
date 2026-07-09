<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class UserController extends Controller
{
    // GET /api/users
    public function index(Request $request)
    {
        $query = User::query();
        if ($request->filled('role'))   $query->where('role', $request->role);
        if ($request->filled('search')) {
            $s = $request->search;
            $query->where(fn($q) => $q->where('name', 'like', "%$s%")
                                      ->orWhere('employee_id', 'like', "%$s%"));
        }
        return response()->json($query->orderBy('name')->get());
    }

    // POST /api/users
    public function store(Request $request)
    {
        $request->validate([
            'name'        => 'required|string|max:255',
            'employee_id' => 'required|string|unique:users',
            'email'       => 'nullable|email|unique:users',
            'password'    => 'required|string|min:4',
            'pin'         => 'nullable|string|min:4|max:6',
            'role'        => 'required|in:admin,kasir',
        ]);

        $user = User::create([
            'name'        => $request->name,
            'employee_id' => $request->employee_id,
            'email'       => $request->email ?? strtolower(str_replace(' ', '.', $request->name)) . '@retail.local',
            'password'    => Hash::make($request->password),
            'pin'         => $request->pin,
            'role'        => $request->role,
            'is_active'   => true,
        ]);

        return response()->json($user, 201);
    }

    // GET /api/users/{id}
    public function show(User $user)
    {
        return response()->json($user->load(['shifts' => fn($q) => $q->latest()->limit(5)]));
    }

    // PUT /api/users/{id}
    public function update(Request $request, User $user)
    {
        $data = $request->validate([
            'name'        => 'string|max:255',
            'employee_id' => ['string', Rule::unique('users')->ignore($user->id)],
            'password'    => 'nullable|string|min:4',
            'pin'         => 'nullable|string|min:4|max:6',
            'role'        => 'in:admin,kasir',
            'is_active'   => 'boolean',
        ]);

        if (!empty($data['password'])) {
            $data['password'] = Hash::make($data['password']);
        } else {
            unset($data['password']);
        }

        $user->update($data);
        return response()->json($user);
    }

    // PATCH /api/users/{id}/toggle-active
    public function toggleActive(User $user)
    {
        $user->update(['is_active' => !$user->is_active]);
        $msg = $user->is_active ? 'diaktifkan' : 'dinonaktifkan';
        return response()->json(['message' => "Akun berhasil {$msg}.", 'user' => $user]);
    }

    // DELETE /api/users/{id}
    public function destroy(User $user)
    {
        if ($user->id === auth()->id()) {
            return response()->json(['message' => 'Tidak dapat menghapus akun sendiri.'], 403);
        }
        $user->tokens()->delete();
        $user->delete();
        return response()->json(['message' => 'Akun berhasil dihapus.']);
    }
}
