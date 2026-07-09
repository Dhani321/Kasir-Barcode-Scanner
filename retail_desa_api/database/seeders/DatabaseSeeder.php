<?php
namespace Database\Seeders;

use App\Models\Product;
use App\Models\Setting;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // ── Admin Account ─────────────────────────────────────
        User::create([
            'name'        => 'Administrator',
            'employee_id' => 'ADM-001',
            'email'       => 'admin@retaildesa.local',
            'password'    => Hash::make('admin123'),
            'pin'         => '1234',
            'role'        => 'admin',
            'is_active'   => true,
        ]);

        // ── Kasir Accounts ────────────────────────────────────
        $kasirs = [
            ['name' => 'Budi Santoso',  'employee_id' => 'KSR-001', 'pin' => '1111'],
            ['name' => 'Siti Rahayu',   'employee_id' => 'KSR-002', 'pin' => '2222'],
            ['name' => 'Ahmad Fauzi',   'employee_id' => 'KSR-003', 'pin' => '3333'],
        ];

        foreach ($kasirs as $k) {
            User::create([
                'name'        => $k['name'],
                'employee_id' => $k['employee_id'],
                'email'       => strtolower(str_replace(' ', '.', $k['name'])) . '@retaildesa.local',
                'password'    => Hash::make($k['pin']),
                'pin'         => $k['pin'],
                'role'        => 'kasir',
                'is_active'   => true,
            ]);
        }

        // ── Products ──────────────────────────────────────────
        $products = [
            ['name' => 'Artisan Dark Roast Coffee', 'sku' => 'COF-DR-250G', 'category' => 'Minuman',      'price' => 18500, 'stock' => 4,   'min_stock' => 10],
            ['name' => 'Volt Energy Drink Citrus',  'sku' => 'BEV-VOL-CIT', 'category' => 'Minuman',      'price' => 7500,  'stock' => 142, 'min_stock' => 20],
            ['name' => 'Organic Raw Almonds 500g',  'sku' => 'SNK-ALM-500', 'category' => 'Snack',        'price' => 25000, 'stock' => 45,  'min_stock' => 10],
            ['name' => 'Tas Belanja Reusable',      'sku' => 'MISC-BAG-01', 'category' => 'Lainnya',      'price' => 5000,  'stock' => 500, 'min_stock' => 20],
            ['name' => 'Mie Instan Goreng',         'sku' => 'FD-MI-GRG',   'category' => 'Makanan',      'price' => 3500,  'stock' => 200, 'min_stock' => 30],
            ['name' => 'Air Mineral 600ml',         'sku' => 'BEV-AIR-600', 'category' => 'Minuman',      'price' => 2500,  'stock' => 300, 'min_stock' => 50],
            ['name' => 'Roti Tawar Gandum',         'sku' => 'FD-RT-GDM',   'category' => 'Makanan',      'price' => 12000, 'stock' => 30,  'min_stock' => 10],
            ['name' => 'Sampo Antiketombe',         'sku' => 'HPC-SMP-AK',  'category' => 'Perawatan',    'price' => 15000, 'stock' => 8,   'min_stock' => 10],
            ['name' => 'Detergen Cair 800ml',       'sku' => 'HPC-DET-800', 'category' => 'Rumah Tangga', 'price' => 22000, 'stock' => 55,  'min_stock' => 15],
            ['name' => 'Keripik Singkong Pedas',    'sku' => 'SNK-KSP-01',  'category' => 'Snack',        'price' => 5000,  'stock' => 120, 'min_stock' => 20],
            ['name' => 'Sabun Mandi Cair',          'sku' => 'HPC-SBN-300', 'category' => 'Perawatan',    'price' => 12000, 'stock' => 75,  'min_stock' => 15],
            ['name' => 'Teh Celup 25 Kantong',      'sku' => 'BEV-TEH-25',  'category' => 'Minuman',      'price' => 8500,  'stock' => 60,  'min_stock' => 15],
            ['name' => 'Beras Pulen 5kg',           'sku' => 'FD-BRS-5KG',  'category' => 'Makanan',      'price' => 65000, 'stock' => 25,  'min_stock' => 10],
            ['name' => 'Minyak Goreng 1L',          'sku' => 'FD-MYK-1L',   'category' => 'Makanan',      'price' => 18000, 'stock' => 40,  'min_stock' => 15],
            ['name' => 'Gula Pasir 1kg',            'sku' => 'FD-GLA-1KG',  'category' => 'Makanan',      'price' => 14000, 'stock' => 50,  'min_stock' => 20],
        ];

        foreach ($products as $p) {
            Product::create(array_merge($p, ['unit' => 'pcs', 'is_active' => true]));
        }

        // ── Default Settings ──────────────────────────────────
        $settings = [
            ['key' => 'store_name',        'value' => 'Retail Desa',           'label' => 'Nama Toko',          'group' => 'general', 'type' => 'string'],
            ['key' => 'store_address',     'value' => 'Jl. Desa Maju No. 1',  'label' => 'Alamat',             'group' => 'general', 'type' => 'string'],
            ['key' => 'store_phone',       'value' => '0812-3456-7890',        'label' => 'No. Telepon',        'group' => 'general', 'type' => 'string'],
            ['key' => 'tax_rate',          'value' => '10',                    'label' => 'Pajak (%)',          'group' => 'general', 'type' => 'number'],
            ['key' => 'print_receipt',     'value' => 'true',                  'label' => 'Cetak Struk',        'group' => 'receipt', 'type' => 'boolean'],
            ['key' => 'email_receipt',     'value' => 'false',                 'label' => 'Email Struk',        'group' => 'receipt', 'type' => 'boolean'],
            ['key' => 'low_stock_alert',   'value' => 'true',                  'label' => 'Alert Stok Rendah', 'group' => 'system',  'type' => 'boolean'],
            ['key' => 'auto_backup',       'value' => 'false',                 'label' => 'Backup Otomatis',   'group' => 'system',  'type' => 'boolean'],
        ];

        foreach ($settings as $s) {
            Setting::create($s);
        }
    }
}
