<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    // POST /api/auth/login
    public function login(Request $request)
    {
        $request->validate([
            'username' => 'required|string',
            'password' => 'required|string',
        ]);

        // Find by employee_id or email
        $user = User::where('employee_id', $request->username)
                    ->orWhere('email', $request->username)
                    ->first();

        if (!$user || !$user->is_active) {
            return response()->json([
                'message' => 'Akun tidak ditemukan atau tidak aktif.',
            ], 401);
        }

        // Check password or PIN
        $valid = Hash::check($request->password, $user->password)
               || ($user->pin && $request->password === $user->pin);

        if (!$valid) {
            return response()->json(['message' => 'Password atau PIN salah.'], 401);
        }

        // Revoke old tokens, issue new one
        $user->tokens()->delete();
        $token = $user->createToken('retail-desa-' . $user->role, [$user->role])->plainTextToken;

        return response()->json([
            'token' => $token,
            'user'  => $user->only(['id', 'name', 'employee_id', 'email', 'role', 'initials']),
        ]);
    }

    // POST /api/auth/logout
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();
        return response()->json(['message' => 'Berhasil keluar.']);
    }

    // GET /api/auth/me
    public function me(Request $request)
    {
        return response()->json($request->user());
    }
}
