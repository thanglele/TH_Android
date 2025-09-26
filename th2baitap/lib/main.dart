import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Hàm main, điểm khởi đầu của ứng dụng
void main() {
  runApp(const MyApp());
}

// Lớp Product để định nghĩa cấu trúc dữ liệu cho một sản phẩm
class Product {
  final String imageUrl;
  final String name;
  final double price;
  final double rating;
  final String views;
  final List<String> tags;

  Product({
    required this.imageUrl,
    required this.name,
    required this.price,
    required this.rating,
    required this.views,
    required this.tags,
  });
}

// Dữ liệu mẫu
final List<Product> sampleProducts = [
  Product(
    imageUrl: 'https://down-vn.img.susercontent.com/file/vn-11134207-7qukw-lhtxujlnd7d114@resize_w450_nl.webp',
    name: 'Ví nam mini đựng thẻ VS22 chất da Saffiano bền đẹp chố...',
    price: 255000,
    rating: 4.0,
    views: '12 views',
    tags: ['HÒA HỒNG', 'XTRA'],
  ),
  Product(
    imageUrl: 'https://down-vn.img.susercontent.com/file/cn-11134207-7ras8-m7v38hpw14tbdd@resize_w450_nl',
    name: 'Túi đeo chéo LEACAT polyester chống thấm nước thời tran...',
    price: 315000,
    rating: 5.0,
    views: '1.3k views',
    tags: [],
  ),
  Product(
    imageUrl: 'https://down-vn.img.susercontent.com/file/d8c652b79cc92b3285a84153afe185b5@resize_w450_nl.webp',
    name: 'Phin cafe Trung Nguyên - Phin nhôm cá nhân cao cấp',
    price: 28000,
    rating: 4.5,
    views: '12.2k views',
    tags: ['HÒA HỒNG', 'XTRA'],
  ),
  Product(
    imageUrl: 'https://down-vn.img.susercontent.com/file/vn-11110105-7r98o-lpf92q9w5y5t52@resize_w82_nl.webp',
    name: 'Ví da cầm tay mềm mại cỡ lớn thiết kế thời trang cho nam',
    price: 610000,
    rating: 5.0,
    views: '56 views',
    tags: ['HÒA HỒNG', 'XTRA'],
  ),
   Product(
    imageUrl: 'https://down-vn.img.susercontent.com/file/vn-11134207-7ras8-mbozw6lq17ribf.webp',
    name: 'Dép nữ đế xuồng cao 5cm quai ngang thời trang',
    price: 189000,
    rating: 4.8,
    views: '2.5k views',
    tags: ['HÒA HỒNG'],
  ),
   Product(
    imageUrl: 'https://down-vn.img.susercontent.com/file/vn-11134207-7ras8-m2q2ixvmcah2cb.webp',
    name: 'Tai nghe Bluetooth M10 TWS không dây cao cấp',
    price: 99000,
    rating: 4.9,
    views: '15k views',
    tags: ['XTRA'],
  ),
];

// Widget gốc của ứng dụng
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter E-commerce UI',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[200],
      ),
      debugShowCheckedModeBanner: false,
      home: const ProductListScreen(),
    );
  }
}

// Màn hình chính hiển thị danh sách sản phẩm
class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lấy chiều rộng màn hình để xác định vị trí nhấn
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'DANH SÁCH SẢN PHẨM',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.blue[700],
        elevation: 0,
      ),
      // ** THAY ĐỔI BẮT ĐẦU TẠI ĐÂY **
      // Dùng GestureDetector để bắt sự kiện nhấn trên toàn bộ body
      body: GestureDetector(
        onTapUp: (details) {
          if (details.globalPosition.dx < screenWidth / 2) {
            // Nhấn bên trái
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã nhấn vào bên trái màn hình danh sách.'),
                duration: Duration(seconds: 1),
              ),
            );
          } else {
            // Nhấn bên phải, chuyển sang màn hình chi tiết
            // Vì chỉ là demo, ta lấy sản phẩm đầu tiên trong danh sách
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ProductDetailScreen(product: sampleProducts.first),
              ),
            );
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GridView.builder(
            // Vô hiệu hóa việc cuộn của GridView để tránh xung đột với GestureDetector
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 cột
              crossAxisSpacing: 8.0, // Khoảng cách ngang
              mainAxisSpacing: 8.0, // Khoảng cách dọc
              childAspectRatio: 0.65, // Tỷ lệ chiều rộng/chiều cao của mỗi item
            ),
            itemCount: sampleProducts.length,
            itemBuilder: (context, index) {
              return ProductCard(product: sampleProducts[index]);
            },
          ),
        ),
      ),
      // ** THAY ĐỔI KẾT THÚC TẠI ĐÂY **
    );
  }
}

// Widget cho mỗi thẻ sản phẩm trong lưới
class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  // Hàm định dạng tiền tệ
  String _formatCurrency(double price) {
    final format = NumberFormat.currency(locale: 'vi_VN', symbol: 'VND');
    return format.format(price);
  }

  @override
  Widget build(BuildContext context) {
    // ** THAY ĐỔI: ĐÃ BỎ GESTUREDETECTOR KHỎI WIDGET NÀY **
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hình ảnh sản phẩm
          AspectRatio(
            aspectRatio: 1.0, // Tỷ lệ 1:1 cho ảnh
            child: Image.network(
              product.imageUrl,
              fit: BoxFit.cover,
            ),
          ),
          // Thông tin sản phẩm
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Tên sản phẩm
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14.0, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),

                  // Tags
                  if (product.tags.isNotEmpty)
                    Row(
                      children:
                          product.tags.map((tag) => TagWidget(text: tag)).toList(),
                    ),
                  const Spacer(),
                  // Giá
                  Text(
                    _formatCurrency(product.price),
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Đánh giá và lượt xem
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber[600], size: 16),
                          const SizedBox(width: 4),
                          Text(
                            product.rating.toString(),
                            style: TextStyle(
                                fontSize: 12.0, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                      Text(
                        product.views,
                        style:
                            TextStyle(fontSize: 12.0, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget cho các tag nhỏ như 'HÒA HỒNG', 'XTRA'
class TagWidget extends StatelessWidget {
  final String text;
  const TagWidget({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 4.0),
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
      decoration: BoxDecoration(
          color:
              text == 'HÒA HỒNG' ? Colors.orange.shade100 : Colors.blue.shade100,
          borderRadius: BorderRadius.circular(4.0),
          border: Border.all(
              color: text == 'HÒA HỒNG'
                  ? Colors.orange.shade300
                  : Colors.blue.shade300,
              width: 0.5)),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.0,
          fontWeight: FontWeight.bold,
          color:
              text == 'HÒA HỒNG' ? Colors.orange.shade800 : Colors.blue.shade800,
        ),
      ),
    );
  }
}

// Màn hình chi tiết sản phẩm (Màn hình thứ 2)
class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    // Lấy chiều rộng màn hình để xác định vị trí nhấn
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Rich Text Example'),
        backgroundColor: Colors.blue[700],
      ),
      // Dùng GestureDetector để bắt sự kiện nhấn trên toàn bộ body
      body: GestureDetector(
        onTapUp: (details) {
          // Kiểm tra vị trí nhấn theo trục X
          if (details.globalPosition.dx < screenWidth / 2) {
            // Nếu nhấn vào nửa bên trái, quay lại màn hình trước
            Navigator.pop(context);
          } else {
            // Nếu nhấn vào nửa bên phải, hiển thị một SnackBar
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã nhấn vào bên phải màn hình.'),
                duration: Duration(seconds: 1),
              ),
            );
          }
        },
        // Thêm behavior để GestureDetector bắt sự kiện trên cả vùng trống
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              // Dùng RichText để hiển thị văn bản với nhiều style khác nhau
              child: RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context)
                      .style
                      .copyWith(fontSize: 16, height: 1.5, color: Colors.black87),
                  children: <TextSpan>[
                    const TextSpan(
                      text: 'Flutter',
                      style: TextStyle(
                          color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(
                      text:
                          ' is an open-source UI software development kit created by Google. It is used to develop cross platform applications for Android, iOS, Linux, macOS, Windows, Google Fuchsia, and the web from a single codebase. First described in 2015, ',
                    ),
                    const TextSpan(
                      text: 'Flutter',
                      style: TextStyle(
                          color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(text: ' was released in May 2017.\n\n'),
                    const TextSpan(text: 'Contact on '),
                    TextSpan(
                        text: '+910000210056',
                        style: const TextStyle(color: Colors.red),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            // Thêm sự kiện khi nhấn vào số điện thoại
                          }),
                    const TextSpan(text: '. Our email address is '),
                    TextSpan(
                        text: 'test@exampleemail.org',
                        style: const TextStyle(color: Colors.red),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            // Thêm sự kiện khi nhấn vào email
                          }),
                    const TextSpan(text: '.\nFor more details check '),
                    TextSpan(
                        text: 'https://www.google.com',
                        style: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            // Thêm sự kiện khi nhấn vào link
                          }),
                    const TextSpan(text: '.\n'),
                    TextSpan(
                        text: 'Read less',
                        style: const TextStyle(
                            color: Colors.red, fontWeight: FontWeight.bold),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            // Thêm sự kiện khi nhấn vào 'Read less'
                          }),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}