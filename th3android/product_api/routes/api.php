// routes/api.php
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\ProductController;
// Tự động tạo các route cho CRUD: GET, POST, PUT, DELETE,...
Route::apiResource('products', ProductController::class);