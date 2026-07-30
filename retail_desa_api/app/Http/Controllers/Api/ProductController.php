<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use App\Models\ActivityLog;
use Illuminate\Http\Request;

class ProductController extends Controller
{
    // GET /api/products
    public function index(Request $request)
    {
        $query = Product::query();

        if ($request->filled('search')) {
            $s = $request->search;
            $query->where(fn($q) => $q->where('name', 'like', "%$s%")
                                      ->orWhere('sku', 'like', "%$s%"));
        }
        if ($request->filled('category')) {
            $query->where('category', $request->category);
        }
        if ($request->boolean('low_stock')) {
            $query->lowStock();
        }
        if ($request->boolean('active_only', true)) {
            $query->active();
        }

        $products = $query->orderBy('name')->paginate($request->get('per_page', 20));
        return response()->json($products);
    }

    // GET /api/products/check-sku/{sku}
    public function checkSku(Request $request, $sku)
    {
        $product = Product::where('sku', $sku)->first();
        if ($product) {
            return response()->json(['exists' => true, 'product' => $product]);
        }
        return response()->json(['exists' => false]);
    }

    // GET /api/products/categories
    public function categories()
    {
        $dbCats = Product::active()->distinct()->pluck('category')->toArray();
        $settingCats = \App\Models\Setting::where('key', 'product_categories')->value('value');
        $settingCatsArray = $settingCats ? explode(',', $settingCats) : [];
        
        $allCats = collect(array_merge($dbCats, $settingCatsArray))
            ->map(fn($c) => trim($c))
            ->filter()
            ->unique()
            ->sort()
            ->values();

        return response()->json($allCats);
    }

    // POST /api/products
    // If SKU already exists, increment stock instead of failing with duplicate entry
    public function store(Request $request)
    {
        $existingProduct = Product::where('sku', $request->sku)->first();

        if ($existingProduct) {
            // Product with code/SKU already exists -> increment stock
            $request->validate([
                'sku'   => 'required|string',
                'stock' => 'required|integer|min:1',
            ]);

            $oldStock = $existingProduct->stock;
            $addedQty = (int) $request->stock;
            $newStock = $oldStock + $addedQty;

            $existingProduct->stock = $newStock;
            
            // Optionally update price if provided
            if ($request->filled('price') && (float)$request->price > 0) {
                $existingProduct->price = (float)$request->price;
            }
            if ($request->filled('name') && !empty($request->name)) {
                $existingProduct->name = $request->name;
            }
            if (!$existingProduct->is_active) {
                $existingProduct->is_active = true;
            }

            $existingProduct->save();

            $user = $request->user();
            $noteText = $request->filled('note') ? " (Catatan: {$request->note})" : "";
            ActivityLog::log(
                $user,
                'add_stock',
                $existingProduct,
                $addedQty,
                $oldStock,
                $newStock,
                "Penambahan stok produk '{$existingProduct->name}' (Kode: {$existingProduct->sku}) sebanyak +{$addedQty} pcs oleh {$user?->name}{$noteText}"
            );

            return response()->json([
                'message' => "Produk dengan kode '{$existingProduct->sku}' sudah ada. Stok berhasil ditambahkan sebanyak {$addedQty} pcs (Total stok: {$newStock}).",
                'product' => $existingProduct->fresh(),
                'is_existing' => true,
            ], 200);
        }

        // New Product Creation
        $data = $request->validate([
            'name'      => 'required|string|max:255',
            'sku'       => 'required|string|unique:products,sku',
            'category'  => 'required|string|max:100',
            'price'     => 'required|numeric|min:0',
            'stock'     => 'required|integer|min:0',
            'min_stock' => 'integer|min:0',
            'unit'      => 'string|max:20',
            'image_url' => 'nullable|url',
        ]);

        $product = Product::create($data);
        $user = $request->user();
        $noteText = $request->filled('note') ? " (Catatan: {$request->note})" : "";

        ActivityLog::log(
            $user,
            'create_product',
            $product,
            $product->stock,
            0,
            $product->stock,
            "Menambahkan produk baru '{$product->name}' (Kode: {$product->sku}) dengan stok awal {$product->stock} pcs oleh {$user?->name}{$noteText}"
        );

        return response()->json($product, 201);
    }

    // GET /api/products/{id}
    public function show(Product $product)
    {
        return response()->json($product);
    }

    // PUT /api/products/{id}
    public function update(Request $request, Product $product)
    {
        $data = $request->validate([
            'name'      => 'string|max:255',
            'sku'       => "string|unique:products,sku,{$product->id}",
            'category'  => 'string|max:100',
            'price'     => 'numeric|min:0',
            'min_stock' => 'integer|min:0',
            'unit'      => 'string|max:20',
            'image_url' => 'nullable|url',
            'is_active' => 'boolean',
        ]);

        $oldStock = $product->stock;
        $product->update($data);
        $newStock = $product->stock;

        $user = $request->user();

        ActivityLog::log(
            $user,
            'update_product',
            $product,
            0,
            $oldStock,
            $newStock,
            "Memperbarui data produk '{$product->name}' oleh {$user?->name}"
        );

        return response()->json($product);
    }

    // PATCH /api/products/{id}/stock — adjust stock (+/-)
    public function adjustStock(Request $request, Product $product)
    {
        $request->validate([
            'adjustment' => 'required|integer',
            'note'       => 'nullable|string',
        ]);
        
        $oldStock = $product->stock;
        $adj = (int) $request->adjustment;
        $product->increment('stock', $adj);
        $updatedProduct = $product->fresh();
        $newStock = $updatedProduct->stock;

        $user = $request->user();
        $action = $adj >= 0 ? 'add_stock' : 'reduce_stock';
        $symbol = $adj >= 0 ? "+{$adj}" : "{$adj}";
        $noteText = $request->filled('note') ? " (Catatan: {$request->note})" : "";

        ActivityLog::log(
            $user,
            $action,
            $updatedProduct,
            $adj,
            $oldStock,
            $newStock,
            "Penyesuaian stok produk '{$product->name}' ({$symbol} pcs, stok: {$oldStock} -> {$newStock}) oleh {$user?->name}{$noteText}"
        );

        return response()->json($updatedProduct);
    }

    // DELETE /api/products/{id}
    public function destroy(Request $request, Product $product)
    {
        $oldStock = $product->stock;
        $product->update(['is_active' => false]); // Soft-disable

        $user = $request->user();
        $noteText = $request->filled('note') ? " (Catatan: {$request->note})" : "";

        ActivityLog::log(
            $user,
            'delete_product',
            $product,
            0,
            $oldStock,
            $oldStock,
            "Menghapus / menonaktifkan produk '{$product->name}' (Kode: {$product->sku}) oleh {$user?->name}{$noteText}"
        );

        return response()->json(['message' => 'Produk dinonaktifkan.']);
    }
}
