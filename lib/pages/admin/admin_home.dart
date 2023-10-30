import 'package:art_marketplace/pages/admin/admin_login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'admin_articles.dart';
import 'admin_seller_list.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  void signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminLogin(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: InkWell(
            onTap: () => Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const AdminHome())),
            child: const Text('Artsylane Admin')),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => signOut(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AdminArticles()),
                );
              },
              child: Container(
                width: 200,
                height: 150,
                color: Colors.blue,
                child: const Center(
                  child: Text(
                    'Heritage Places',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AdminSellerList()),
                );
              },
              child: Container(
                width: 200,
                height: 150,
                color: Colors.green,
                child: const Center(
                  child: Text(
                    'Review Seller List',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
