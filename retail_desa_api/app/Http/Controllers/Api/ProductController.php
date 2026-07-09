<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
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
    public function store(Request $request)
    {
        $data = $request->validate([
            'name'      => 'required|string|max:255',
            'sku'       => 'required|string|unique:products',
            'category'  => 'required|string|max:100',
            'price'     => 'required|numeric|min:0',
            'stock'     => 'required|integer|min:0',
            'min_stock' => 'integer|min:0',
            'unit'      => 'string|max:20',
            'image_url' => 'nullable|url',
        ]);

        $product = Product::create($data);
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
            'stock'     => 'integer|min:0',
            'min_stock' => 'integer|min:0',
            'unit'      => 'string|max:20',
            'image_url' => 'nullable|url',
            'is_active' => 'boolean',
        ]);

        $product->update($data);
        return response()->json($product);
    }

    // PATCH /api/products/{id}/stock  — adjust stock (+/-)
    public function adjustStock(Request $request, Product $product)
    {
        $request->validate(['adjustment' => 'required|integer']);
        $product->increment('stock', $request->adjustment);
        return response()->json($product->fresh());
    }

    // DELETE /api/products/{id}
    public function destroy(Product $product)
    {
        $product->update(['is_active' => false]); // Soft-disable instead of hard delete
        return response()->json(['message' => 'Produk dinonaktifkan.']);
    }
}
