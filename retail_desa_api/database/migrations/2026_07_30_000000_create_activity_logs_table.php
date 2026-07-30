<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('activity_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('user_name')->nullable();
            $table->string('user_role')->nullable();
            $table->string('action'); // create_product, add_stock, reduce_stock, update_product, delete_product, sale_stock_out
            $table->foreignId('product_id')->nullable()->constrained('products')->nullOnDelete();
            $table->string('product_name')->nullable();
            $table->string('sku')->nullable();
            $table->integer('qty_change')->default(0);
            $table->integer('old_stock')->nullable();
            $table->integer('new_stock')->nullable();
            $table->text('description')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void {
        Schema::dropIfExists('activity_logs');
    }
};
