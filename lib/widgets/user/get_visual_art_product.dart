import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';

import '../../model/product_model.dart';
import '../../pages/user/product_view_page.dart';
import 'loading_indicator_design.dart';

class GetVisualArtProduct extends StatefulWidget {
  final String productCategory;

  const GetVisualArtProduct({super.key, required this.productCategory});

  @override
  State<GetVisualArtProduct> createState() => _GetVisualArtProductState();
}

class _GetVisualArtProductState extends State<GetVisualArtProduct> {
  final User? user = FirebaseAuth.instance.currentUser;
  String currentDate = DateFormat("yyyy-MM-dd").format(DateTime.now());

  Stream _getVisualArtsProducts() {
    if (user != null) {
      Stream<QuerySnapshot<Object?>> snapshot = FirebaseFirestore.instance
          .collection('Product')
          .where("Category", isEqualTo: widget.productCategory)
          .snapshots();

      return snapshot;
    } else {
      return const Stream.empty();
    }
  }

  Future<void> addRecentlyViewed(ProductModel productModel) async {
    try {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(user?.uid.toString())
          .collection('RecentlyViewed')
          .doc(productModel.productID)
          .set(
        {
          'Date': currentDate.toString(),
          'ProductID': productModel.productID.toString(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: _getVisualArtsProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicatorDesign();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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
            print("object");
            return MasonryGridView.builder(
              padding: const EdgeInsets.all(0.1),
              mainAxisSpacing: 1.0,
              crossAxisSpacing: 1.0,
              gridDelegate:
                  const SliverSimpleGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
              ),
              itemCount: products.length,
              itemBuilder: (BuildContext context, int index) {
                return FadeInUp(
                  delay: Duration(milliseconds: index * 50),
                  duration: Duration(milliseconds: (index * 50) + 500),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  ProductViewPage(product: products[index])));
                      addRecentlyViewed(products[index]);
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
        });
  }
}
