<?php
namespace App\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, Notifiable;

    protected $fillable = [
        'name', 'employee_id', 'email', 'password', 'pin',
        'role', 'is_active',
    ];

    protected $hidden = ['password', 'pin', 'remember_token'];

    protected $casts = [
        'is_active'         => 'boolean',
        'email_verified_at' => 'datetime',
        'password'          => 'hashed',
    ];

    public function getInitialsAttribute(): string
    {
        $parts = explode(' ', trim($this->name));
        if (count($parts) >= 2) {
            return strtoupper($parts[0][0] . $parts[1][0]);
        }
        return strtoupper(substr($this->name, 0, 2));
    }

    protected $appends = ['initials'];

    public function transactions()
    {
        return $this->hasMany(Transaction::class, 'kasir_id');
    }

    public function shifts()
    {
        return $this->hasMany(Shift::class, 'kasir_id');
    }
}
