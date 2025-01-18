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
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: CustomerOrderScreen(),
    );
  }
}

class CustomerOrderScreen extends StatefulWidget {
  @override
  _CustomerOrderScreenState createState() => _CustomerOrderScreenState();
}

class _CustomerOrderScreenState extends State<CustomerOrderScreen> {
  final List<Customer> _customers = [];
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _orderDetailsController = TextEditingController();
  final TextEditingController _orderQuantityController = TextEditingController();
  final TextEditingController _customerAddressController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final customerData = _customers.map((customer) => {
          'name': customer.name,
          'orders': customer.orders.map((order) => {
                'details': order.details,
                'quantity': order.quantity,
                'address': order.address,
              }).toList(),
        }).toList();
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
            orders: (customer['orders'] as List<dynamic>).map((order) => Order(
                  details: order['details'],
                  quantity: order['quantity'],
                  address: order['address'],
                )).toList(),
          ));
        });
      });
    }
  }

  void _addCustomer(String name) {
    if (name.isNotEmpty) {
      setState(() {
        _customers.add(Customer(name: name));
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

  void _addOrder(int customerIndex, String details, int quantity, String address) {
    if (details.isEmpty || quantity <= 0 || address.isEmpty) {
      _showErrorDialog('Lütfen tüm sipariş bilgilerini doğru şekilde doldurun.');
      return;
    }
    setState(() {
      _customers[customerIndex].orders.add(Order(details: details, quantity: quantity, address: address));
    });
    _orderDetailsController.clear();
    _orderQuantityController.clear();
    _customerAddressController.clear();
    _saveData();
  }

  void _updateOrder(int customerIndex, int orderIndex, String newDetails, int newQuantity, String newAddress) {
    if (newDetails.isNotEmpty && newQuantity > 0 && newAddress.isNotEmpty) {
      setState(() {
        _customers[customerIndex].orders[orderIndex] = Order(
          details: newDetails,
          quantity: newQuantity,
          address: newAddress,
        );
      });
      _saveData();
    } else {
      _showErrorDialog('Lütfen tüm bilgileri doldurun.');
    }
  }

  void _removeOrder(int customerIndex, int orderIndex) {
    setState(() {
      _customers[customerIndex].orders.removeAt(orderIndex);
    });
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

  void _showUpdateOrderDialog(int customerIndex, int orderIndex, Order order) {
    TextEditingController detailsController = TextEditingController(text: order.details);
    TextEditingController quantityController = TextEditingController(text: order.quantity.toString());
    TextEditingController addressController = TextEditingController(text: order.address);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Sipariş Güncelle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: detailsController, decoration: InputDecoration(labelText: 'Sipariş Detayları')),
            TextField(controller: quantityController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Ürün Miktarı')),
            TextField(controller: addressController, decoration: InputDecoration(labelText: 'Adres')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              _updateOrder(customerIndex, orderIndex, detailsController.text,
                  int.tryParse(quantityController.text) ?? 0, addressController.text);
              Navigator.of(ctx).pop();
            },
            child: Text('Güncelle'),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerList() {
    final filteredCustomers = _customers
        .where((customer) => customer.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return filteredCustomers.isEmpty
        ? Center(child: Text('Hiç müşteri bulunamadı.'))
        : ListView.builder(
            itemCount: filteredCustomers.length,
            itemBuilder: (context, index) {
              final customer = filteredCustomers[index];
              return ExpansionTile(
                title: Text(customer.name),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeCustomer(index),
                ),
                children: [
                  ...customer.orders.map((order) {
                    int orderIndex = customer.orders.indexOf(order);
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: ListTile(
                        title: Text('Sipariş Detayları: ${order.details}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Ürün Miktarı: ${order.quantity}'),
                            Text('Adres: ${order.address}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.orange),
                              onPressed: () => _showUpdateOrderDialog(index, orderIndex, order),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeOrder(index, orderIndex),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        TextField(controller: _orderDetailsController, decoration: InputDecoration(labelText: 'Sipariş Detayları')),
                        TextField(controller: _orderQuantityController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Ürün Miktarı')),
                        TextField(controller: _customerAddressController, decoration: InputDecoration(labelText: 'Adres')),
                        SizedBox(height: 8.0),
                        ElevatedButton(
                          onPressed: () => _addOrder(
                            _customers.indexOf(customer),
                            _orderDetailsController.text,
                            int.tryParse(_orderQuantityController.text) ?? 0,
                            _customerAddressController.text,
                          ),
                          child: Text('Sipariş Ekle'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
  }

  Widget _buildSummary() {
    int totalOrders = _customers.fold(0, (sum, customer) => sum + customer.orders.length);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        'Toplam Müşteri: ${_customers.length}, Toplam Sipariş: $totalOrders',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Müşteri ve Sipariş Yönetimi'),
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customerNameController,
                    decoration: InputDecoration(labelText: 'Müşteri Adı'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () => _addCustomer(_customerNameController.text),
                ),
              ],
            ),
          ),
          _buildSummary(),
          Expanded(
            child: _buildCustomerList(),
          ),
        ],
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
