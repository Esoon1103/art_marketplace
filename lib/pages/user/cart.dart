import 'dart:convert';

import 'package:another_flushbar/flushbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:loading_indicator/loading_indicator.dart';
import '../../model/cart_model.dart';
import 'cart_item.dart';
import 'package:http/http.dart' as http;

class Cart extends StatefulWidget {
  const Cart({super.key});

  @override
  State<Cart> createState() => _CartState();
}

class _CartState extends State<Cart> {
  final User? user = FirebaseAuth.instance.currentUser;
  double totalPrice = 0;
  List<CartModel> cart = [];
  Map<String, dynamic>? paymentIntent;

  Stream _getCartItems() {
    if (user != null) {
      Stream<QuerySnapshot<Object?>> snapshot = FirebaseFirestore.instance
          .collection('Users')
          .doc(user?.uid.toString())
          .collection("Cart")
          .snapshots();

      return snapshot;
    } else {
      return const Stream.empty();
    }
  }

  Future<void> payment() async {
    try {
      Map<String, dynamic> body = {"amount": "10000", "currency": "MYR"};

      var response = await http.post(
        Uri.parse("https://api.stripe.com/v1/payment_intents"),
        headers: {
          "Authorization":
              "Bearer sk_test_51O7JIUFC8KYffCidA0PlQzgXgug2AJzn78jwRUYzyFkp6HH47ZJkbI1LWq9sMYOfm7MChKA7FGQJTosqtcOmXWvF00HHU9ofyV",
          "Content-type": "application/x-www-form-urlencoded"
        },
        body: body,
      );
      paymentIntent = json.decode(response.body);
    } catch (e) {
      print(e);
    }
    print(paymentIntent);
    await Stripe.instance
        .initPaymentSheet(
            paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent!["client_secret"],
          style: ThemeMode.light,
          merchantDisplayName: "Artsylane",
        ))
        .then((value) => {});

    try {
      await Stripe.instance
          .presentPaymentSheet()
          .then((value) => {print("Payment Success")});
    } catch (e) {
      print(e);
    }
  }

  Future<double> calculateTotalPrice(List<CartModel> cart) async {
    double totalPrice = 0;

    for (int i = 0; i < cart.length; i++) {
      DocumentSnapshot<Map<String, dynamic>> product = await FirebaseFirestore
          .instance
          .collection('Product')
          .doc(cart[i].productID)
          .get();

      int quantity = int.parse(cart[i].quantity);
      double price = double.parse(product.data()?["Price"]);

      totalPrice += quantity * price;
      print(totalPrice);
    }

    return totalPrice;
  }

  emptyCartDialog() async {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Empty Cart'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure to empty this cart?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, 'Cancel'),
              child: const Text('Cancel'),
            ),
            TextButton(
              child: const Text('EMPTY'),
              onPressed: () async {
                await emptyCart();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  emptyCart() async {
    await FirebaseFirestore.instance
        .collection("Users")
        .doc(user?.uid.toString())
        .collection("Cart")
        .get()
        .then((querySnapshot) {
      for (var doc in querySnapshot.docs) {
        doc.reference.delete();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F8),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        title: const Text(
          "My Cart",
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(
              Icons.delete_rounded,
              size: 28,
              color: Colors.black,
            ),
            onPressed: () {
              if (cart.isEmpty) {
                Flushbar(
                  icon: Icon(
                    Icons.info_outline,
                    size: 28.0,
                    color: Colors.blue[300],
                  ),
                  animationDuration: const Duration(seconds: 1),
                  duration: const Duration(seconds: 1),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 6.0, vertical: 70),
                  flushbarStyle: FlushbarStyle.FLOATING,
                  borderRadius: BorderRadius.circular(12),
                  leftBarIndicatorColor: Colors.blue[300],
                  message: "Cart is Empty!",
                ).show(context);
              } else {
                emptyCartDialog();
              }
            },
          ),
          const SizedBox(width: 8)
        ],
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 30),
            Expanded(
              child: StreamBuilder(
                  stream: _getCartItems(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: SizedBox(
                          width: 50,
                          child: LoadingIndicator(
                            indicatorType: Indicator.ballPulse,
                            colors: [Colors.blueGrey],
                            strokeWidth: 1,
                          ),
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else if (!snapshot.hasData ||
                        snapshot.data!.docs.isEmpty) {
                      return const Text('No products available.');
                    } else {
                      cart = [
                        for (var cartItem in snapshot.data!.docs)
                          CartModel(
                            quantity: cartItem["Quantity"],
                            productID: cartItem["ProductID"],
                          ),
                      ];

                      if (cart.isEmpty) {
                        return const Text('No items in your cart.');
                      }

                      return FutureBuilder<double>(
                        future: calculateTotalPrice(cart),
                        builder: (context, totalPriceSnapshot) {
                          if (totalPriceSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: SizedBox(
                                width: 50,
                                child: LoadingIndicator(
                                  indicatorType: Indicator.ballPulse,
                                  colors: [Colors.blueGrey],
                                  strokeWidth: 1,
                                ),
                              ),
                            );
                          } else if (totalPriceSnapshot.hasError) {
                            return Text(
                              'Error calculating total price: ${totalPriceSnapshot.error}',
                            );
                          } else {
                            totalPrice = totalPriceSnapshot.data ?? 0;

                            return Column(
                              children: [
                                Expanded(
                                  child: ListView.builder(
                                    scrollDirection: Axis.vertical,
                                    shrinkWrap: true,
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: cart.length,
                                    itemBuilder:
                                        (BuildContext context, int index) {
                                      return CartItem(cartItem: cart[index]);
                                    },
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    const Text(
                                      'Total',
                                      style: TextStyle(fontSize: 17),
                                    ),
                                    Text(
                                      'RM ${totalPrice.toString()}',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF5956E9),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 30),
                                Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: MaterialButton(
                                          onPressed: () {
                                            payment();
                                          },
                                          elevation: 0,
                                          height: 50,
                                          splashColor: Colors.white54,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                          color: Colors.black87,
                                          child: const Center(
                                            child: Text(
                                              "Checkout",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ]),
                              ],
                            );
                          }
                        },
                      );
                    }
                  }),
            ),
          ],
        ),
      ),
    );
  }
}
