<?php
// app/Http/Controllers/Api/ProductController.php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use App\Models\Product;
use Illuminate\Http\Request;
class ProductController extends Controller
{
 // Lấy danh sách tất cả sản phẩm
 public function index()
 {
 return Product::all();
 }
 // Tạo một sản phẩm mới
 public function store(Request $request)
 {
 $request->validate([
 'name' => 'required|string|max:255',
 'price' => 'required|numeric',
 ]);
 $product = Product::create($request->all());
 return response()->json($product, 201); // 201 Created
 }
 // Lấy thông tin một sản phẩm cụ thể
 public function show(Product $product)
 {
 return $product;
 }
 // Cập nhật thông tin sản phẩm
 public function update(Request $request, Product $product)
 {
 $request->validate([
 'name' => 'string|max:255',
 'price' => 'numeric',
 ]);
 $product->update($request->all());
 return response()->json($product, 200); // 200 OK
 }
 // Xóa một sản phẩm
 public function destroy(Product $product)
 {
 $product->delete();
 return response()->json(null, 204); // 204 No Content
 }
}
