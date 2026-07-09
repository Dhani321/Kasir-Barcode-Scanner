<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Product extends Model
{
    protected $fillable = [
        'name', 'sku', 'category', 'price', 'stock',
        'min_stock', 'unit', 'image_url', 'is_active',
    ];

    protected $casts = [
        'price'     => 'float',
        'stock'     => 'integer',
        'min_stock' => 'integer',
        'is_active' => 'boolean',
    ];

    public function getIsLowStockAttribute(): bool
    {
        return $this->stock <= $this->min_stock;
    }

    protected $appends = ['is_low_stock'];

    public function transactionItems()
    {
        return $this->hasMany(TransactionItem::class);
    }

    // Scope: active products
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    // Scope: low stock
    public function scopeLowStock($query)
    {
        return $query->whereRaw('stock <= min_stock');
    }
}
