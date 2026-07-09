<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Transaction;
use App\Models\TransactionItem;
use App\Models\Product;
use App\Models\User;
use App\Models\Shift;
use Carbon\Carbon;

class DummyTransactionSeeder extends Seeder
{
    public function run()
    {
        $kasir = User::where('role', 'kasir')->first();
        if (!$kasir) return;

        $products = Product::all();
        if ($products->isEmpty()) return;

        $shift = Shift::create([
            'kasir_id' => $kasir->id,
            'start_time' => Carbon::now()->subDays(6)->startOfDay(),
            'end_time' => Carbon::now(),
            'status' => 'closed',
            'opening_cash' => 500000,
            'closing_cash' => 1500000,
        ]);

        for ($i = 0; $i < 20; $i++) {
            $date = Carbon::now()->subDays(rand(0, 6));
            
            $subtotal = 0;
            $items = [];
            $numItems = rand(1, 4);

            for ($j = 0; $j < $numItems; $j++) {
                $p = $products->random();
                $qty = rand(1, 3);
                $st = $p->price * $qty;
                $subtotal += $st;
                
                $items[] = [
                    'product_id' => $p->id,
                    'product_sku' => $p->sku,
                    'product_name' => $p->name,
                    'price' => $p->price,
                    'qty' => $qty,
                    'subtotal' => $st,
                ];
            }

            $tax = $subtotal * 0.1;
            $grandTotal = $subtotal + $tax;

            $txn = Transaction::create([
                'transaction_number' => 'TRX-' . strtoupper(uniqid()),
                'kasir_id' => $kasir->id,
                'shift_id' => $shift->id,
                'subtotal' => $subtotal,
                'tax' => $tax,
                'grand_total' => $grandTotal,
                'payment_method' => ['cash', 'card', 'digital'][rand(0, 2)],
                'payment_amount' => $grandTotal,
                'change_amount' => 0,
                'status' => 'completed',
                'created_at' => $date,
                'updated_at' => $date,
            ]);

            foreach ($items as $item) {
                $txn->items()->create($item);
            }
        }
    }
}
