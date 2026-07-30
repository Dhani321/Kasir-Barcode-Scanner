<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ActivityLog extends Model
{
    protected $fillable = [
        'user_id',
        'user_name',
        'user_role',
        'action',
        'product_id',
        'product_name',
        'sku',
        'qty_change',
        'old_stock',
        'new_stock',
        'description',
    ];

    protected $casts = [
        'qty_change' => 'integer',
        'old_stock'  => 'integer',
        'new_stock'  => 'integer',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function product()
    {
        return $this->belongsTo(Product::class);
    }

    /**
     * Helper to log activity
     */
    public static function log($user, string $action, ?Product $product = null, int $qtyChange = 0, ?int $oldStock = null, ?int $newStock = null, ?string $description = null)
    {
        return static::create([
            'user_id'      => $user?->id,
            'user_name'    => $user?->name ?? 'Sistem',
            'user_role'    => $user?->role ?? 'system',
            'action'       => $action,
            'product_id'   => $product?->id,
            'product_name' => $product?->name,
            'sku'          => $product?->sku,
            'qty_change'   => $qtyChange,
            'old_stock'    => $oldStock,
            'new_stock'    => $newStock,
            'description'  => $description,
        ]);
    }
}
