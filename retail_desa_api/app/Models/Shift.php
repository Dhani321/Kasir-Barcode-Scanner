<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Shift extends Model
{
    protected $fillable = [
        'kasir_id', 'start_time', 'end_time',
        'opening_cash', 'closing_cash',
        'total_sales', 'total_transactions', 'status', 'notes',
    ];

    protected $casts = [
        'start_time'         => 'datetime',
        'end_time'           => 'datetime',
        'opening_cash'       => 'float',
        'closing_cash'       => 'float',
        'total_sales'        => 'float',
        'total_transactions' => 'integer',
    ];

    public function kasir()
    {
        return $this->belongsTo(User::class, 'kasir_id');
    }

    public function transactions()
    {
        return $this->hasMany(Transaction::class);
    }
}
