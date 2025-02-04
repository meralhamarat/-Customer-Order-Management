import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: _themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: CustomerOrderApp(toggleTheme: _toggleTheme),
    );
  }
}

class Customer {
  String id;
  String name;
  List<Order> orders;

  Customer({required this.id, required this.name, this.orders = const []});

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      name: json['name'],
      orders: (json['orders'] as List).map((o) => Order.fromJson(o)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'orders': orders.map((o) => o.toJson()).toList(),
    };
  }
}

class Order {
  String details;
  int quantity;
  String address;

  Order({required this.details, required this.quantity, required this.address});

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      details: json['details'],
      quantity: json['quantity'],
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'details': details,
      'quantity': quantity,
      'address': address,
    };
  }
}

class CustomerOrderApp extends StatefulWidget {
  final VoidCallback toggleTheme;
  CustomerOrderApp({required this.toggleTheme});

  @override
  _CustomerOrderAppState createState() => _CustomerOrderAppState();
}

class _CustomerOrderAppState extends State<CustomerOrderApp> {
  List<Customer> _customers = [];
  final TextEditingController _customerNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _addCustomer(String name) {
    if (name.isNotEmpty) {
      setState(() {
        _customers.add(Customer(id: UniqueKey().toString(), name: name));
      });
      _customerNameController.clear();
      _saveData();
    }
  }

  void _removeCustomer(String customerId) {
    setState(() {
      _customers.removeWhere((customer) => customer.id == customerId);
    });
    _saveData();
  }

  void _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final customerData = jsonEncode(_customers.map((c) => c.toJson()).toList());
    prefs.setString('customers', customerData);
  }

  void _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final customerData = prefs.getString('customers');
    if (customerData != null) {
      setState(() {
        _customers = (jsonDecode(customerData) as List)
            .map((c) => Customer.fromJson(c))
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Customer Management"),
        actions: [
          IconButton(
            icon: Icon(Icons.brightness_6),
            onPressed: widget.toggleTheme,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: TextField(
              controller: _customerNameController,
              decoration: InputDecoration(
                labelText: "Enter Customer Name",
                suffixIcon: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () => _addCustomer(_customerNameController.text),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _customers.length,
              itemBuilder: (context, index) {
                final customer = _customers[index];
                return ListTile(
                  title: Text(customer.name),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeCustomer(customer.id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
