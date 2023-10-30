import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';
import '../../model/product_model.dart';
import '../../widgets/user/recently_viewed_card.dart';

class RecentlyViewed extends StatefulWidget {
  const RecentlyViewed({super.key});

  @override
  State<RecentlyViewed> createState() => _RecentlyViewedState();
}

class _RecentlyViewedState extends State<RecentlyViewed> {
  final User? user = FirebaseAuth.instance.currentUser;

  Future<List<ProductModel>> getRecentlyViewedProducts() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> querySnapshot =
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(user?.uid.toString())
          .collection("RecentlyViewed")
          .orderBy("Date", descending: true)
          .get();

      List<ProductModel> products = [];

      for (QueryDocumentSnapshot<Map<String, dynamic>> doc in querySnapshot.docs) {
        String productId = doc["ProductID"].toString();

        DocumentSnapshot<Map<String, dynamic>> productDoc =
        await FirebaseFirestore.instance.collection("Product").doc(productId).get();

        if (productDoc.exists) {
          ProductModel product = ProductModel(
            name: productDoc["Name"],
            description: productDoc["Desc"],
            location: productDoc["Location"],
            price: productDoc["Price"],
            uid: productDoc["UID"],
            image: productDoc["Image"],
            image3D: productDoc["3D Image"],
            category: productDoc["Category"],
            inventory: productDoc["Inventory"],
            productID: productDoc["ProductID"],
          );

          products.add(product);
        }
      }

      return products;
    } catch (e) {
      print("Error $e");
      return []; // Return an empty list in case of an error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recently Viewed'),
        backgroundColor: Colors.black87,
      ),
      body: FutureBuilder(
        future: getRecentlyViewedProducts(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              width: 50,
              child: LoadingIndicator(
                indicatorType: Indicator.ballRotateChase,
                colors: [Colors.blueGrey],
                strokeWidth: 1,
              ),
            );
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Text('No products available.');
          } else {
            List<ProductModel> products = snapshot.data!;

            return ListView.builder(
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              itemCount: products.length,
              itemBuilder: (BuildContext context, int index) {
                return RecentlyViewedCard(
                  productModel: products[index],
                );
              },
            );
          }
        },
      ),
    );
  }
}
