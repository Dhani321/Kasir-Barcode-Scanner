<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class TransactionItem extends Model
{
    protected $fillable = [
        'transaction_id', 'product_id', 'product_name',
        'product_sku', 'price', 'qty', 'subtotal', 'discount',
    ];

    protected $casts = [
        'price'    => 'float',
        'qty'      => 'integer',
        'subtotal' => 'float',
        'discount' => 'float',
    ];

    public function transaction()
    {
        return $this->belongsTo(Transaction::class);
    }

    public function product()
    {
        return $this->belongsTo(Product::class);
    }
}
