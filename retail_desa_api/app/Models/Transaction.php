<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Transaction extends Model
{
    protected $fillable = [
        'transaction_number', 'kasir_id', 'shift_id',
        'subtotal', 'tax', 'discount', 'grand_total',
        'payment_method', 'payment_amount', 'change_amount',
        'status', 'customer_name', 'notes',
    ];

    protected $casts = [
        'subtotal'       => 'float',
        'tax'            => 'float',
        'discount'       => 'float',
        'grand_total'    => 'float',
        'payment_amount' => 'float',
        'change_amount'  => 'float',
    ];

    public function kasir()
    {
        return $this->belongsTo(User::class, 'kasir_id');
    }

    public function shift()
    {
        return $this->belongsTo(Shift::class);
    }

    public function items()
    {
        return $this->hasMany(TransactionItem::class);
    }

    // Generate transaction number: TXN-YYYYMMDD-XXXX
    public static function generateNumber(): string
    {
        $date   = now()->format('Ymd');
        $prefix = "TXN-{$date}-";
        $last   = self::where('transaction_number', 'like', "{$prefix}%")
                      ->latest('id')->first();
        $seq = $last ? ((int) substr($last->transaction_number, -4)) + 1 : 1;
        return $prefix . str_pad($seq, 4, '0', STR_PAD_LEFT);
    }
}
