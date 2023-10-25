import 'dart:async';
import 'package:art_marketplace/pages/user/product_view_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:loading_indicator/loading_indicator.dart';
import '../../model/product_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  String? displayName = "";

  Stream _getVisualArtsProducts() {
    if (user != null) {
      Stream<QuerySnapshot<Object?>> snapshot = FirebaseFirestore.instance
          .collection('Product')
          .where("Category", isEqualTo: "Visual Arts")
          .snapshots();

      return snapshot;
    } else {
      return const Stream.empty();
    }
  }

  Stream _getVintageProducts() {
    if (user != null) {
      Stream<QuerySnapshot<Object?>> snapshot = FirebaseFirestore.instance
          .collection('Product')
          .where("Category", isEqualTo: "Vintage")
          .snapshots();

      return snapshot;
    } else {
      return const Stream.empty();
    }
  }

  Stream _getNatureProducts() {
    if (user != null) {
      Stream<QuerySnapshot<Object?>> snapshot = FirebaseFirestore.instance
          .collection('Product')
          .where("Category", isEqualTo: "Nature")
          .snapshots();

      return snapshot;
    } else {
      return const Stream.empty();
    }
  }

  getUsername() async {
    final DocumentSnapshot<Map<String, dynamic>> getUsername =
        await FirebaseFirestore.instance
            .collection("Users")
            .doc(user?.uid.toString())
            .get();
    displayName = getUsername.data()?["Username"].toString();
  }

  updateDisplayName() async {
    await getUsername();
    await FirebaseAuth.instance.currentUser!.updateDisplayName(displayName);
  }

  @override
  Widget build(BuildContext context) {
    updateDisplayName();
    return Scaffold(
        body: NestedScrollView(
            headerSliverBuilder: (context, value) {
              return [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 30,
                        ),
                        FadeInDown(
                          child: Row(
                            children: [
                              Text(
                                "The Art from Penangnites  🔥",
                                style: TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade800,
                                    height: 1.5),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        FadeInDown(
                          delay: const Duration(milliseconds: 200),
                          duration: const Duration(milliseconds: 500),
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8)),
                            child: TextField(
                              cursorColor: Colors.black,
                              decoration: InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: Colors.grey.shade700,
                                  ),
                                  border: InputBorder.none,
                                  hintText: "Classic Style",
                                  hintStyle:
                                      TextStyle(color: Colors.grey.shade500)),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                )
              ];
            },
            body: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  FadeInDown(
                    delay: const Duration(milliseconds: 200),
                    child: TabBar(
                        labelColor: Colors.black,
                        unselectedLabelColor: Colors.grey.shade600,
                        indicatorColor: Colors.black,
                        tabs: const [
                          Tab(
                            text: "Visual Arts",
                          ),
                          Tab(
                            text: "Vintage",
                          ),
                          Tab(
                            text: "Nature",
                          )
                        ]),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        StreamBuilder(
                            stream: _getVisualArtsProducts(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const  SizedBox(
                                  width: 50,
                                  child: LoadingIndicator(
                                    indicatorType: Indicator.ballRotateChase,
                                    colors: [Colors.blueGrey],
                                    strokeWidth: 1,
                                  ),
                                );
                              } else if (snapshot.hasError) {
                                return Text('Error: ${snapshot.error}');
                              } else if (!snapshot.hasData ||
                                  snapshot.data!.docs.isEmpty) {
                                return const Text('No products available.');
                              } else {
                                List<ProductModel> products = [
                                  for (var product in snapshot.data!.docs)
                                    ProductModel(
                                        name: product["Name"],
                                        description: product["Desc"],
                                        location: product["Location"],
                                        price: product["Price"],
                                        uid: product["UID"],
                                        image: product["Image"],
                                        image3D: product["3D Image"],
                                        category: product["Category"],
                                        inventory: product["Inventory"],
                                        productID: product["ProductID"]),
                                ];
                                return MasonryGridView.builder(
                                  padding: const EdgeInsets.all(0.1),
                                  mainAxisSpacing: 1.0,
                                  crossAxisSpacing: 1.0,
                                  gridDelegate:
                                      const SliverSimpleGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                  ),
                                  itemCount: products.length,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    return FadeInUp(
                                      delay: Duration(milliseconds: index * 50),
                                      duration: Duration(
                                          milliseconds: (index * 50) + 500),
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                       ProductViewPage(product: products[index])));
                                        },
                                        child: Container(
                                          color: Colors.black,
                                          child: Image.network(
                                            products[index].image,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }
                            }),
                        StreamBuilder(
                            stream: _getVintageProducts(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const  SizedBox(
                                  width: 50,
                                  child: LoadingIndicator(
                                    indicatorType: Indicator.ballRotateChase,
                                    colors: [Colors.blueGrey],
                                    strokeWidth: 1,
                                  ),
                                );
                              } else if (snapshot.hasError) {
                                return Text('Error: ${snapshot.error}');
                              } else if (!snapshot.hasData ||
                                  snapshot.data!.docs.isEmpty) {
                                return const Text('No products available.');
                              } else {
                                List<ProductModel> products = [
                                  for (var product in snapshot.data!.docs)
                                    ProductModel(
                                        name: product["Name"],
                                        description: product["Desc"],
                                        location: product["Location"],
                                        price: product["Price"],
                                        uid: product["UID"],
                                        image: product["Image"],
                                        image3D: product["3D Image"],
                                        category: product["Category"],
                                        inventory: product["Inventory"],
                                        productID: product["ProductID"]),
                                ];
                                return MasonryGridView.builder(
                                  padding: const EdgeInsets.all(0.1),
                                  mainAxisSpacing: 1.0,
                                  crossAxisSpacing: 1.0,
                                  gridDelegate:
                                  const SliverSimpleGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                  ),
                                  itemCount: products.length,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    return FadeInUp(
                                      delay: Duration(milliseconds: index * 50),
                                      duration: Duration(
                                          milliseconds: (index * 50) + 500),
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      ProductViewPage(product: products[index])));
                                        },
                                        child: Container(
                                          color: Colors.black,
                                          child: Image.network(
                                            products[index].image,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }
                            }),
                        StreamBuilder(
                            stream: _getNatureProducts(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const  SizedBox(
                                  width: 50,
                                  child: LoadingIndicator(
                                    indicatorType: Indicator.ballRotateChase,
                                    colors: [Colors.blueGrey],
                                    strokeWidth: 1,
                                  ),
                                );
                              } else if (snapshot.hasError) {
                                return Text('Error: ${snapshot.error}');
                              } else if (!snapshot.hasData ||
                                  snapshot.data!.docs.isEmpty) {
                                return const Text('No products available.');
                              } else {
                                List<ProductModel> products = [
                                  for (var product in snapshot.data!.docs)
                                    ProductModel(
                                        name: product["Name"],
                                        description: product["Desc"],
                                        location: product["Location"],
                                        price: product["Price"],
                                        uid: product["UID"],
                                        image: product["Image"],
                                        image3D: product["3D Image"],
                                        category: product["Category"],
                                        inventory: product["Inventory"],
                                        productID: product["ProductID"]),
                                ];
                                return MasonryGridView.builder(
                                  padding: const EdgeInsets.all(0.1),
                                  mainAxisSpacing: 1.0,
                                  crossAxisSpacing: 1.0,
                                  gridDelegate:
                                  const SliverSimpleGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                  ),
                                  itemCount: products.length,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    return FadeInUp(
                                      delay: Duration(milliseconds: index * 50),
                                      duration: Duration(
                                          milliseconds: (index * 50) + 500),
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      ProductViewPage(product: products[index])));
                                        },
                                        child: Container(
                                          color: Colors.black,
                                          child: Image.network(
                                            products[index].image,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }
                            }),
                      ],
                    ),
                  )
                ],
              ),
            )));
  }
}
