import 'package:art_marketplace/pages/user/home_page.dart';
import 'package:art_marketplace/pages/user/settings.dart';
import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

import '../../pages/user/cart.dart';
import '../../pages/user/articles.dart';

class BottomNavigationBar extends StatefulWidget {
  final int pageNum;

  const BottomNavigationBar({super.key, required this.pageNum});

  @override
  State<BottomNavigationBar> createState() => _BottomNavigationBarState();
}

class _BottomNavigationBarState extends State<BottomNavigationBar> {
  int _currentIndex = 0;

  List pages = const [
    HomePage(),
    Articles(),
    Cart(),
    Settings(),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: SalomonBottomBar(
          currentIndex: _currentIndex,
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: [
            SalomonBottomBarItem(
                icon: const Icon(Icons.home),
                title: const Text("Home"),
                selectedColor: Colors.purple
            ),
            SalomonBottomBarItem(
                icon: const Icon(Icons.place_outlined),
                title: const Text("Places"),
                selectedColor: Colors.pink
            ),
            SalomonBottomBarItem(
                icon: const Icon(Icons.shopping_cart),
                title: const Text("Cart"),
                selectedColor: Colors.orange
            ),
            SalomonBottomBarItem(
                icon: const Icon(Icons.person),
                title: const Text("Profile"),
                selectedColor: Colors.teal
            )
          ],
      ),
      body: pages[_currentIndex],
    );
  }
}
