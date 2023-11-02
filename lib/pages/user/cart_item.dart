import 'package:another_flushbar/flushbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../model/cart_model.dart';
import '../../model/product_model.dart';

class CartItem extends StatefulWidget {
  final CartModel cartItem;

  const CartItem({
    Key? key,
    required this.cartItem,
  }) : super(key: key);

  @override
  State<CartItem> createState() => _CartItemState();
}

class _CartItemState extends State<CartItem> {
  final User? user = FirebaseAuth.instance.currentUser;
  int latestInventory = 0;
  int quantity = 0;

  final ButtonStyle style = ElevatedButton.styleFrom(
    textStyle: const TextStyle(fontSize: 14),
    backgroundColor: const Color(0xFF7DCCEC),
    padding: const EdgeInsets.all(0),
    minimumSize: const Size(22, 22),
    maximumSize: const Size(22, 22),
    elevation: 0,
  );

  @override
  initState() {
    quantity = int.parse(widget.cartItem.quantity);
    getInventory();
    super.initState();
  }

  Future<ProductModel?> fetchProductDetails(String productID) async {
    if (user != null) {
      try {
        DocumentSnapshot<Map<String, dynamic>> product = await FirebaseFirestore
            .instance
            .collection('Product')
            .doc(productID)
            .get();

        if (product.exists) {
          return ProductModel(
            name: product["Name"],
            description: product["Desc"],
            location: product["Location"],
            price: product["Price"],
            uid: product["UID"],
            image: product["Image"],
            image3D: product["3D Image"],
            category: product["Category"],
            inventory: product["Inventory"],
            productID: product["ProductID"],
          );
        } else {
          return null;
        }
      } catch (e) {
        print("Error fetching product details: $e");
        return null;
      }
    } else {
      return null;
    }
  }

  getInventory() async {
    //retrieve current product id
    final DocumentSnapshot<Map<String, dynamic>> inventory =
        await FirebaseFirestore.instance
            .collection("Product")
            .doc(widget.cartItem.productID)
            .get();

    latestInventory = inventory.data()?["Inventory"];

    if (latestInventory == 0) {
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(user?.uid.toString())
          .collection("Cart")
          .doc(widget.cartItem.productID)
          .delete();
    }
  }

  Future<void> decrement() async {
    await getInventory();

    if (quantity > 1) {
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(user?.uid.toString())
          .collection("Cart")
          .doc(widget.cartItem.productID)
          .update({
        "Quantity": (quantity - 1).toString(),
      });
    } else if (quantity == 1 || quantity == 0) {
      //Delete the product from cart if the current number is 1 or 0
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(user?.uid.toString())
          .collection("Cart")
          .doc(widget.cartItem.productID)
          .delete();
    }
  }

  Future<void> increment() async {
    await getInventory();

    if (quantity == latestInventory) {
      //if current quantity is same as stock, stop the increment
      Flushbar(
        icon: Icon(
          Icons.info_outline,
          size: 28.0,
          color: Colors.blue[300],
        ),
        animationDuration: const Duration(seconds: 1),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(6.0),
        flushbarStyle: FlushbarStyle.FLOATING,
        borderRadius: BorderRadius.circular(12),
        leftBarIndicatorColor: Colors.blue[300],
        message: "You have reached the maximum of product stock!",
      ).show(context);
      return;
    } else {
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(user?.uid.toString())
          .collection("Cart")
          .doc(widget.cartItem.productID)
          .update({
        "Quantity": (quantity + 1).toString(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProductModel?>(
      future: fetchProductDetails(widget.cartItem.productID),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData) {
          return const Text('Loading product details...');
        } else {
          ProductModel productDetails = snapshot.data!;

          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 15),
            child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(children: [
                  Image.network(
                    productDetails.image,
                    width: 80,
                    height: 105,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        productDetails.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "RM ${productDetails.price}",
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Color(0xFF5956E9)),
                      ),
                      Row(
                        children: [
                          const Text('Quantity'),
                          ElevatedButton(
                            style: style,
                            onPressed: () {
                              decrement();
                            },
                            child: const Text('-'),
                          ),
                          Text(
                            widget.cartItem.quantity.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          ElevatedButton(
                            style: style,
                            onPressed: () {
                              increment();
                            },
                            child: const Text('+'),
                          ),
                        ],
                      ),
                      latestInventory <= 5
                          ? Text(
                              "\t${latestInventory.toString()} items remaining",
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            )
                          : const SizedBox(),
                    ],
                  )
                ])),
          );
        }
      },
    );
  }
}
