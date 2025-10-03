import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Thư viện cho PDF và in ấn
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// Thư viện cho SQLite
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

// Bắt đầu ứng dụng Flutter
void main() {
  // Đảm bảo Flutter binding đã được khởi tạo trước khi thao tác với database
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OrderManagementApp());
}

// --- MODELS ---
class Product {
  final String id;
  final String name;
  final double price;

  Product({required this.id, required this.name, required this.price});
  
  // Dùng để chuyển đổi từ Map đọc từ DB
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      price: map['price'],
    );
  }
}

class Order {
  String id;
  String customerName;
  String phoneNumber;
  String address;
  String? note;
  DateTime deliveryDate;
  String paymentMethod;
  List<Product> products;

  Order({
    required this.id,
    required this.customerName,
    required this.phoneNumber,
    required this.address,
    this.note,
    required this.deliveryDate,
    required this.paymentMethod,
    required this.products,
  });

  // Dùng để chuyển đổi object thành Map để ghi vào DB
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerName': customerName,
      'phoneNumber': phoneNumber,
      'address': address,
      'note': note,
      'deliveryDate': deliveryDate.toIso8601String(),
      'paymentMethod': paymentMethod,
    };
  }
}

// --- DATABASE HELPER ---
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('orders.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        customerName TEXT NOT NULL,
        phoneNumber TEXT NOT NULL,
        address TEXT NOT NULL,
        note TEXT,
        deliveryDate TEXT NOT NULL,
        paymentMethod TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE order_products (
        orderId TEXT NOT NULL,
        productId TEXT NOT NULL,
        FOREIGN KEY (orderId) REFERENCES orders (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> insertOrder(Order order) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.insert('orders', order.toMap());
      for (var product in order.products) {
        await txn.insert('order_products', {'orderId': order.id, 'productId': product.id});
      }
    });
  }

  Future<void> updateOrder(Order order) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.update('orders', order.toMap(), where: 'id = ?', whereArgs: [order.id]);
      await txn.delete('order_products', where: 'orderId = ?', whereArgs: [order.id]);
      for (var product in order.products) {
        await txn.insert('order_products', {'orderId': order.id, 'productId': product.id});
      }
    });
  }

  Future<List<Order>> getOrders(List<Product> availableProducts) async {
    final db = await instance.database;
    final orderMaps = await db.query('orders', orderBy: 'deliveryDate DESC');
    
    List<Order> orders = [];
    for (var orderMap in orderMaps) {
      final productMaps = await db.query('order_products', where: 'orderId = ?', whereArgs: [orderMap['id']]);
      List<Product> products = [];
      for (var pMap in productMaps) {
        // Tìm sản phẩm đầy đủ từ danh sách có sẵn dựa trên ID
        final product = availableProducts.firstWhere((p) => p.id == pMap['productId']);
        products.add(product);
      }

      orders.add(Order(
        id: orderMap['id'] as String,
        customerName: orderMap['customerName'] as String,
        phoneNumber: orderMap['phoneNumber'] as String,
        address: orderMap['address'] as String,
        note: orderMap['note'] as String?,
        deliveryDate: DateTime.parse(orderMap['deliveryDate'] as String),
        paymentMethod: orderMap['paymentMethod'] as String,
        products: products,
      ));
    }
    return orders;
  }

  Future<void> deleteOrder(String id) async {
    final db = await instance.database;
    await db.delete('orders', where: 'id = ?', whereArgs: [id]);
    // Do có ON DELETE CASCADE, các dòng trong order_products cũng sẽ tự động bị xóa.
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}

// --- UI WIDGETS ---
class OrderManagementApp extends StatelessWidget {
  const OrderManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản lý Đơn hàng',
      // Cấu hình để DatePicker hiển thị tiếng Việt
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi', 'VN'), // Tiếng Việt
        Locale('en', 'US'), // Tiếng Anh
      ],
      locale: const Locale('vi', 'VN'),
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // Gợi ý màu sắc thương mại
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
          accentColor: Colors.orangeAccent,
          cardColor: Colors.white,
          backgroundColor: Colors.grey[100],
          errorColor: Colors.red,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.orangeAccent,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const OrderListPage(),
    );
  }
}

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  // Dữ liệu sản phẩm có sẵn (trong ứng dụng thực tế có thể load từ DB hoặc API)
  final List<Product> _availableProducts = [
    Product(id: 'p1', name: 'Laptop Pro Max', price: 35000000),
    Product(id: 'p2', name: 'Smartphone Galaxy S25', price: 28000000),
    Product(id: 'p3', name: 'Tai nghe Chống ồn X', price: 4500000),
    Product(id: 'p4', name: 'Chuột Gaming RGB', price: 1200000),
    Product(id: 'p5', name: 'Bàn phím cơ Tenkeyless', price: 2100000),
  ];
  
  late Future<List<Order>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _refreshOrders();
  }

  void _refreshOrders() {
    setState(() {
      _ordersFuture = DatabaseHelper.instance.getOrders(_availableProducts);
    });
  }

  void _navigateToOrderForm({Order? order}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderFormScreen(
          availableProducts: _availableProducts,
          order: order,
        ),
      ),
    );

    if (result != null && result is Order) {
      if (order != null) {
        await DatabaseHelper.instance.updateOrder(result);
      } else {
        await DatabaseHelper.instance.insertOrder(result);
      }
      _refreshOrders();
    }
  }
  
  void _navigateToOrderDetail(Order order) async {
     final action = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailScreen(order: order),
      ),
    );

    if (action == 'delete') {
      _deleteOrderWithConfirmation(order);
    } else if (action is Order) {
       _navigateToOrderForm(order: action);
    }
  }

  void _deleteOrderWithConfirmation(Order order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xoá'),
        content: Text('Bạn có chắc muốn xoá đơn hàng của khách "${order.customerName}" không?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Huỷ')),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await DatabaseHelper.instance.deleteOrder(order.id);
               ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã xoá đơn hàng thành công!'), backgroundColor: Colors.green),
              );
              _refreshOrders();
            },
            child: const Text('Xoá', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách Đơn hàng'),
      ),
      body: FutureBuilder<List<Order>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Đã có lỗi xảy ra: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('Chưa có đơn hàng nào', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  const Text('Nhấn nút + để tạo đơn hàng mới.'),
                ],
              ),
            );
          } else {
            final orders = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Giao ngày: ${DateFormat('dd/MM/yyyy').format(order.deliveryDate)}\nThanh toán: ${order.paymentMethod}'),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                      onPressed: () => _deleteOrderWithConfirmation(order),
                    ),
                    onTap: () => _navigateToOrderDetail(order),
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToOrderForm(),
        tooltip: 'Tạo đơn hàng mới',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ... Các màn hình OrderFormScreen và OrderDetailScreen giữ nguyên như cũ ...

// Màn hình 2: Form tạo/chỉnh sửa đơn hàng
class OrderFormScreen extends StatefulWidget {
  final Order? order;
  final List<Product> availableProducts;

  const OrderFormScreen({super.key, this.order, required this.availableProducts});

  @override
  State<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  // Controllers và biến cho các trường input
  late TextEditingController _customerNameController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _addressController;
  late TextEditingController _noteController;
  DateTime _selectedDate = DateTime.now();
  String _paymentMethod = 'Tiền mặt';
  final List<Product> _selectedProducts = [];

  bool get _isEditing => widget.order != null;

  @override
  void initState() {
    super.initState();
    _customerNameController = TextEditingController(text: widget.order?.customerName ?? '');
    _phoneNumberController = TextEditingController(text: widget.order?.phoneNumber ?? '');
    _addressController = TextEditingController(text: widget.order?.address ?? '');
    _noteController = TextEditingController(text: widget.order?.note ?? '');
    if (_isEditing) {
      _selectedDate = widget.order!.deliveryDate;
      _paymentMethod = widget.order!.paymentMethod;
      _selectedProducts.addAll(widget.order!.products);
    }
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _phoneNumberController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // Hiển thị DatePicker
  void _presentDatePicker() {
    showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    ).then((pickedDate) {
      if (pickedDate == null) {
        return;
      }
      setState(() {
        _selectedDate = pickedDate;
      });
    });
  }

  // Hiển thị Dialog chọn sản phẩm
  void _showProductSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        // Dùng stateful builder để cập nhật UI trong dialog
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Chọn sản phẩm'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.availableProducts.length,
                  itemBuilder: (context, index) {
                    final product = widget.availableProducts[index];
                    final isSelected = _selectedProducts.any((p) => p.id == product.id);
                    return CheckboxListTile(
                      title: Text(product.name),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            _selectedProducts.add(product);
                          } else {
                            _selectedProducts.removeWhere((p) => p.id == product.id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Cập nhật lại UI chính sau khi dialog đóng
                    setState(() {}); 
                  },
                  child: const Text('Xong'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Xử lý lưu đơn hàng
  void _submitForm() {
    final isValid = _formKey.currentState?.validate() ?? false;
    
    // Kiểm tra sản phẩm
    if (_selectedProducts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Vui lòng chọn ít nhất một sản phẩm.'),
                backgroundColor: Colors.red,
            ),
        );
        return;
    }

    if (!isValid) {
      return;
    }

    _formKey.currentState!.save();
    
    final newOrder = Order(
      id: widget.order?.id ?? _uuid.v4(),
      customerName: _customerNameController.text,
      phoneNumber: _phoneNumberController.text,
      address: _addressController.text,
      note: _noteController.text.isEmpty ? null : _noteController.text,
      deliveryDate: _selectedDate,
      paymentMethod: _paymentMethod,
      products: List.from(_selectedProducts),
    );
    
    Navigator.of(context).pop(newOrder);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Chỉnh sửa Đơn hàng' : 'Tạo Đơn hàng mới'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Thông tin khách hàng'),
              TextFormField(
                controller: _customerNameController,
                decoration: const InputDecoration(labelText: 'Tên khách hàng', prefixIcon: Icon(Icons.person_outline)),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên khách hàng.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneNumberController,
                decoration: const InputDecoration(labelText: 'Số điện thoại', prefixIcon: Icon(Icons.phone_outlined)),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập số điện thoại.';
                  }
                  if (value.length != 10 || !RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                    return 'Số điện thoại phải có 10 chữ số.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Địa chỉ giao hàng', prefixIcon: Icon(Icons.location_on_outlined)),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập địa chỉ giao hàng.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Ghi chú (tuỳ chọn)', prefixIcon: Icon(Icons.note_alt_outlined)),
                maxLines: 2,
              ),

              _buildSectionTitle('Thông tin đơn hàng'),
              // Ngày giao
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ngày giao dự kiến: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Chọn ngày'),
                    onPressed: _presentDatePicker,
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              // Chọn sản phẩm
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      title: const Text('Danh sách sản phẩm'),
                      trailing: const Icon(Icons.arrow_drop_down),
                      onTap: _showProductSelectionDialog,
                    ),
                    if (_selectedProducts.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Wrap(
                          spacing: 8.0,
                          runSpacing: 4.0,
                          children: _selectedProducts
                              .map((p) => Chip(label: Text(p.name)))
                              .toList(),
                        ),
                      ),
                  ],
                ),
              ),

              _buildSectionTitle('Phương thức thanh toán'),
              RadioListTile<String>(
                title: const Text('Tiền mặt'),
                value: 'Tiền mặt',
                groupValue: _paymentMethod,
                onChanged: (value) {
                  setState(() {
                    _paymentMethod = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('Chuyển khoản'),
                value: 'Chuyển khoản',
                groupValue: _paymentMethod,
                onChanged: (value) {
                  setState(() {
                    _paymentMethod = value!;
                  });
                },
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save_alt_outlined),
                  label: Text(_isEditing ? 'Cập nhật đơn hàng' : 'Lưu đơn hàng'),
                  onPressed: _submitForm,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget phụ để tạo tiêu đề cho các phần
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}

// Màn hình 3: Chi tiết đơn hàng
class OrderDetailScreen extends StatelessWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  // TÍNH NĂNG MỚI: Hàm tạo và in PDF
  Future<void> _generateAndPrintPdf(BuildContext context) async {
    // Hiển thị loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final doc = pw.Document();

    // Tải font chữ đã thêm vào assets
    final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);
    final boldFontData = await rootBundle.load("assets/fonts/Roboto-Bold.ttf");
    final boldTtf = pw.Font.ttf(boldFontData);

    // Định nghĩa các kiểu chữ
    final baseStyle = pw.TextStyle(font: ttf, fontSize: 11);
    final boldStyle = pw.TextStyle(font: boldTtf, fontSize: 11);
    final titleStyle = pw.TextStyle(font: boldTtf, fontSize: 18);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Hóa Đơn Bán Lẻ', style: titleStyle),
                  pw.Text('Ngày: ${DateFormat('dd/MM/yyyy').format(order.deliveryDate)}', style: baseStyle),
                ],
              ),
            ),
            pw.Divider(),
            pw.SizedBox(height: 20),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 2,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Mã đơn hàng:', style: boldStyle),
                      pw.Text(order.id.substring(0, 8), style: baseStyle),
                      pw.SizedBox(height: 10),
                      pw.Text('Khách hàng:', style: boldStyle),
                      pw.Text(order.customerName, style: baseStyle),
                      pw.SizedBox(height: 10),
                      pw.Text('Số điện thoại:', style: boldStyle),
                      pw.Text(order.phoneNumber, style: baseStyle),
                    ],
                  ),
                ),
                pw.Expanded(
                  flex: 3,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Địa chỉ giao hàng:', style: boldStyle),
                      pw.Text(order.address, style: baseStyle),
                      pw.SizedBox(height: 10),
                      pw.Text('Phương thức thanh toán:', style: boldStyle),
                      pw.Text(order.paymentMethod, style: baseStyle),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 30),
            // Bảng danh sách sản phẩm
            pw.Table.fromTextArray(
              headers: ['STT', 'Tên sản phẩm', 'Đơn giá'],
              data: List<List<String>>.generate(
                order.products.length,
                (index) => [
                  (index + 1).toString(),
                  order.products[index].name,
                  NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(order.products[index].price),
                ],
              ),
              headerStyle: boldStyle,
              cellStyle: baseStyle,
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerRight,
              },
              border: pw.TableBorder.all(),
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text('Tổng cộng: ', style: pw.TextStyle(font: boldTtf, fontSize: 14)),
                pw.Text(
                  NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(order.products.fold<double>(0, (sum, item) => sum + item.price)),
                  style: pw.TextStyle(font: boldTtf, fontSize: 14),
                ),
              ],
            ),
            pw.SizedBox(height: 40),
            pw.Text('Cảm ơn quý khách!', style: baseStyle),
          ];
        },
      ),
    );

    // Ẩn loading indicator
    Navigator.of(context, rootNavigator: true).pop();

    // Dùng thư viện printing để hiển thị giao diện In/Lưu/Chia sẻ file PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết Đơn hàng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note),
            tooltip: 'Chỉnh sửa',
            onPressed: () {
              Navigator.of(context).pop(order);
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'Mã đơn hàng: ${order.id.substring(0, 8)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 14, fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(context, Icons.person, 'Khách hàng', order.customerName),
                    _buildDetailRow(context, Icons.phone, 'Số điện thoại', order.phoneNumber),
                    _buildDetailRow(context, Icons.location_on, 'Địa chỉ', order.address),
                    if (order.note != null && order.note!.isNotEmpty)
                      _buildDetailRow(context, Icons.note, 'Ghi chú', order.note!),
                  ],
                ),
              ),
            ),
             Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(context, Icons.calendar_today, 'Ngày giao', DateFormat('dd/MM/yyyy').format(order.deliveryDate)),
                    _buildDetailRow(context, Icons.payment, 'Thanh toán', order.paymentMethod),
                    const Divider(height: 24),
                    Text("Danh sách sản phẩm:", style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...order.products.map((p) => ListTile(
                          leading: const Icon(Icons.shopping_bag_outlined),
                          title: Text(p.name),
                          trailing: Text(NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(p.price)),
                        )).toList(),
                    const Divider(),
                    ListTile(
                      title: const Text('Tổng cộng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      trailing: Text(
                        NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(order.products.fold<double>(0, (sum, item) => sum + item.price)),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue)
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                label: const Text('Xoá Đơn hàng', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                   padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                    // Trả về 'delete' để màn hình list biết cần thực hiện xoá
                    Navigator.of(context).pop('delete');
                },
              ),
            ),
          ],
        ),
      ),
      // THÊM NÚT IN/XUẤT PDF
      floatingActionButton: FloatingActionButton(
        onPressed: () => _generateAndPrintPdf(context),
        tooltip: 'In/Xuất PDF',
        child: const Icon(Icons.print_outlined),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}