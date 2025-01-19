import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Müşteri ve Sipariş Yönetimi',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      themeMode: ThemeMode.system,
      home: CustomerOrderScreen(),
    );
  }
}

class CustomerOrderScreen extends StatefulWidget {
  @override
  _CustomerOrderScreenState createState() => _CustomerOrderScreenState();
}

class _CustomerOrderScreenState extends State<CustomerOrderScreen>
    with SingleTickerProviderStateMixin {
  final List<Customer> _customers = [];
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _orderDetailsController = TextEditingController();
  final TextEditingController _orderQuantityController =
      TextEditingController();
  final TextEditingController _customerAddressController =
      TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final customerData = _customers
        .map((customer) => {
              'name': customer.name,
              'orders': customer.orders
                  .map((order) => {
                        'details': order.details,
                        'quantity': order.quantity,
                        'address': order.address,
                      })
                  .toList(),
            })
        .toList();
    prefs.setString('customers', jsonEncode(customerData));
  }

  void _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('customers');
    if (data != null) {
      final List<dynamic> decodedData = jsonDecode(data);
      setState(() {
        _customers.clear();
        decodedData.forEach((customer) {
          _customers.add(Customer(
            name: customer['name'],
            orders: (customer['orders'] as List<dynamic>)
                .map((order) => Order(
                      details: order['details'],
                      quantity: order['quantity'],
                      address: order['address'],
                    ))
                .toList(),
          ));
        });
      });
    }
  }

  void _addCustomer(String name) {
    if (name.isNotEmpty) {
      setState(() {
        _customers.add(Customer(name: name));
        _animationController.forward(from: 0.0);
      });
      _customerNameController.clear();
      _saveData();
    } else {
      _showErrorDialog('Müşteri adı boş olamaz.');
    }
  }

  void _removeCustomer(int index) {
    setState(() {
      _customers.removeAt(index);
    });
    _saveData();
  }

  void _addOrder(
      int customerIndex, String details, int quantity, String address) {
    if (details.isEmpty || quantity <= 0 || address.isEmpty) {
      _showErrorDialog(
          'Lütfen tüm sipariş bilgilerini doğru şekilde doldurun.');
      return;
    }
    setState(() {
      _customers[customerIndex]
          .orders
          .add(Order(details: details, quantity: quantity, address: address));
      _animationController.forward(from: 0.0);
    });
    _orderDetailsController.clear();
    _orderQuantityController.clear();
    _customerAddressController.clear();
    _saveData();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hata'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerList() {
    final filteredCustomers = _customers
        .where((customer) =>
            customer.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return filteredCustomers.isEmpty
        ? Center(child: Text('Hiç müşteri bulunamadı.'))
        : ListView.builder(
            itemCount: filteredCustomers.length,
            itemBuilder: (context, index) {
              final customer = filteredCustomers[index];
              return FadeTransition(
                opacity: _animation,
                child: Card(
                  margin: EdgeInsets.all(8.0),
                  child: ExpansionTile(
                    title: Text(customer.name),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeCustomer(index),
                    ),
                    children: customer.orders.map((order) {
                      return ListTile(
                        title: Text('Sipariş Detayları: ${order.details}'),
                        subtitle: Text(
                            'Ürün Miktarı: ${order.quantity}, Adres: ${order.address}'),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Müşteri ve Sipariş Yönetimi'),
        actions: [
          IconButton(
            icon: Icon(Icons.brightness_6),
            onPressed: () {
              ThemeMode themeMode =
                  Theme.of(context).brightness == Brightness.dark
                      ? ThemeMode.light
                      : ThemeMode.dark;
              MyApp();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Müşteri Ara',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: _buildCustomerList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addCustomer(_customerNameController.text),
        child: Icon(Icons.add),
      ),
    );
  }
}

class Customer {
  String name;
  List<Order> orders = [];

  Customer({required this.name});
}

class Order {
  String details;
  int quantity;
  String address;

  Order({required this.details, required this.quantity, required this.address});
}
