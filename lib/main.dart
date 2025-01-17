import 'package:flutter/material.dart';

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

  void _addCustomer(String name) {
    if (name.isNotEmpty) {
      setState(() {
        _customers.add(Customer(name: name));
      });
      _customerNameController.clear();
    } else {
      _showErrorDialog('Müşteri adı boş olamaz.');
    }
  }

  void _addOrder(int customerIndex, String details, int quantity, String address) {
    if (details.isEmpty || quantity <= 0 || address.isEmpty) {
      _showErrorDialog('Lütfen tüm sipariş bilgilerini doğru şekilde doldurun.');
      return;
    }
    setState(() {
      _customers[customerIndex].orders.add(
        Order(details: details, quantity: quantity, address: address),
      );
    });
    _orderDetailsController.clear();
    _orderQuantityController.clear();
    _customerAddressController.clear();
  }

  void _removeOrder(int customerIndex, int orderIndex) {
    setState(() {
      _customers[customerIndex].orders.removeAt(orderIndex);
    });
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
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeOrder(index, orderIndex),
                        ),
                      ),
                    );
                  }).toList(),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: _orderDetailsController,
                          decoration: InputDecoration(labelText: 'Sipariş Detayları'),
                        ),
                        TextField(
                          controller: _orderQuantityController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: 'Ürün Miktarı'),
                        ),
                        TextField(
                          controller: _customerAddressController,
                          decoration: InputDecoration(labelText: 'Adres'),
                        ),
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
