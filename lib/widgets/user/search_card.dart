import 'package:art_marketplace/model/product_model.dart';
import 'package:art_marketplace/pages/user/product_view_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SearchCard extends StatefulWidget {
  ProductModel productModel;

  SearchCard({super.key, required this.productModel});

  @override
  State<SearchCard> createState() => _SearchCardState();
}

class _SearchCardState extends State<SearchCard> {
  final User? user = FirebaseAuth.instance.currentUser;
  String currentDate = DateFormat("yyyy-MM-dd").format(DateTime.now());

  Future<void> addRecentlyViewed() async {
    try {
      await FirebaseFirestore.instance.collection('Users')
          .doc(user?.uid.toString())
          .collection('RecentlyViewed')
          .doc(widget.productModel.productID)
          .set({
        'Date': currentDate.toString(),
        'ProductID': widget.productModel.productID.toString(),
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        await addRecentlyViewed();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductViewPage(
              product: widget.productModel,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Card(
            elevation: 1,
            shadowColor: Colors.black,
            child: Column(
              children: [
                Stack(
                  children: [
                    SizedBox(
                      height: 150,
                      width: MediaQuery.of(context).size.width,
                      child: Image.network(
                        widget.productModel.image,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.productModel.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {},
                            child: Text(
                              "RM${widget.productModel.price}",
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 15,
                                color: Colors.grey,
                              ),
                              Text(
                                widget.productModel.location,
                                style: const TextStyle(
                                  color: Colors.black38,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Category: ${widget.productModel.category}",
                            style: const TextStyle(
                              color: Colors.black38,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
