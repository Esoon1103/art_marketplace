import 'package:flutter/material.dart';

class SellerManageOrder extends StatefulWidget {
  const SellerManageOrder({super.key});

  @override
  State<SellerManageOrder> createState() => _SellerManageOrderState();
}

class _SellerManageOrderState extends State<SellerManageOrder> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Orders'),
        backgroundColor: Colors.black87,
      ),
    );
  }
}
