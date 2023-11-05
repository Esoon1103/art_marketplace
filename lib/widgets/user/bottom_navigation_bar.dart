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
                icon: const Icon(Icons.home, color: Colors.black87,),
                title: const Text("Home", style: TextStyle(color: Colors.black87),),
                selectedColor: Colors.lightBlue[900],
                unselectedColor: Colors.grey,
            ),
            SalomonBottomBarItem(
                icon: const Icon(Icons.place_outlined, color: Colors.black87,),
                title: const Text("Places", style: TextStyle(color: Colors.black87),),
                selectedColor: Colors.lightBlue[900]
            ),
            SalomonBottomBarItem(
                icon: const Icon(Icons.shopping_cart, color: Colors.black87,),
                title: const Text("Cart", style: TextStyle(color: Colors.black87),),
                selectedColor: Colors.lightBlue[900]
            ),
            SalomonBottomBarItem(
                icon: const Icon(Icons.person, color: Colors.black87,),
                title: const Text("Profile", style: TextStyle(color: Colors.black87),),
                selectedColor: Colors.lightBlue[900]
            )
          ],
      ),
      body: pages[_currentIndex],
    );
  }
}
