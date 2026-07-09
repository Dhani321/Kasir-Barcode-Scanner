<?php
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ProductController;
use App\Http\Controllers\Api\TransactionController;
use App\Http\Controllers\Api\UserController;
use App\Http\Controllers\Api\ReportController;
use App\Http\Controllers\Api\SettingController;
use App\Http\Controllers\Api\ShiftController;
use Illuminate\Support\Facades\Route;

// ─── Public Routes ────────────────────────────────────────────
Route::prefix('auth')->group(function () {
    Route::post('login', [AuthController::class, 'login']);
});

// ─── Protected Routes (requires Sanctum token) ────────────────
Route::middleware('auth:sanctum')->group(function () {

    // Auth
    Route::post('auth/logout', [AuthController::class, 'logout']);
    Route::get('auth/me',      [AuthController::class, 'me']);

    // Products (Kasir: read-only | Admin: full CRUD)
    Route::get('products/categories', [ProductController::class, 'categories']);
    Route::get('products',            [ProductController::class, 'index']);
    Route::get('products/{product}',  [ProductController::class, 'show']);

    Route::middleware('ability:admin')->group(function () {
        Route::post('products',                      [ProductController::class, 'store']);
        Route::put('products/{product}',             [ProductController::class, 'update']);
        Route::patch('products/{product}/stock',     [ProductController::class, 'adjustStock']);
        Route::delete('products/{product}',          [ProductController::class, 'destroy']);
    });

    // Transactions
    Route::get('transactions',             [TransactionController::class, 'index']);
    Route::post('transactions',            [TransactionController::class, 'store']);
    Route::get('transactions/{transaction}',[TransactionController::class, 'show']);
    Route::patch('transactions/{transaction}/void', [TransactionController::class, 'void']);

    // Shifts
    Route::get('shifts',          [ShiftController::class, 'index']);
    Route::get('shifts/current',  [ShiftController::class, 'current']);
    Route::post('shifts/open',    [ShiftController::class, 'open']);
    Route::post('shifts/close',   [ShiftController::class, 'close']);
    Route::get('shifts/{shift}',  [ShiftController::class, 'show']);

    // Reports (Admin only)
    Route::prefix('reports')->group(function () {
        Route::get('sales',            [ReportController::class, 'sales']);
        Route::get('dashboard',        [ReportController::class, 'dashboard']);
        Route::get('shift/{shiftId}',  [ReportController::class, 'shiftReport']);
    });

    // User Management (Admin only)
    Route::get('users',                         [UserController::class, 'index']);
    Route::post('users',                        [UserController::class, 'store']);
    Route::get('users/{user}',                  [UserController::class, 'show']);
    Route::put('users/{user}',                  [UserController::class, 'update']);
    Route::patch('users/{user}/toggle-active',  [UserController::class, 'toggleActive']);
    Route::delete('users/{user}',               [UserController::class, 'destroy']);

    // Settings
    Route::get('settings',        [SettingController::class, 'index']);
    Route::get('settings/flat',   [SettingController::class, 'flat']);
    Route::put('settings',        [SettingController::class, 'bulkUpdate']);
    Route::put('settings/{key}',  [SettingController::class, 'update']);
});
