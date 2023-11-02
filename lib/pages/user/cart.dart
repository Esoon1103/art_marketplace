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
import 'package:intl/intl.dart';

class Cart extends StatefulWidget {
  const Cart({super.key});

  @override
  State<Cart> createState() => _CartState();
}

class _CartState extends State<Cart> {
  final User? user = FirebaseAuth.instance.currentUser;
  double totalPrice = 0;
  List<CartModel> cart = [];
  int quantity = 0;
  String address = "";
  String addressValue = "";
  Map<String, dynamic>? paymentIntent;
  String currentDate = DateFormat("yyyy-MM-dd").format(DateTime.now());
  TextEditingController addressController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    addressController.dispose();
    super.dispose();
  }

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

  showAddressDialog(String? address) async {
    addressController.text = address!;
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Form(
          key: _formKey,
          child: AlertDialog(
            title: address == ""
                ? const Text('Please Update your Address')
                : const Text('Confirm your Address'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Address  cannot be empty!';
                      } else if (addressValue.length <= 15) {
                        return "Please make sure your address is detailed!";
                      }
                      return null;
                    },
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: "Address",
                      hintStyle: TextStyle(
                        color: Color(0xFF8391A1),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        addressValue = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  addressController.clear();
                  Navigator.pop(context, 'Cancel');
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                child: const Text('Confirm'),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await FirebaseFirestore.instance
                        .collection("Users")
                        .doc(user?.uid.toString())
                        .update({"Address": addressValue});
                    payment(totalPrice, cart);
                    addressController.clear();
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  checkUserAddress() async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> addressData =
          await FirebaseFirestore.instance
              .collection("Users")
              .doc(user?.uid.toString())
              .get();

      if (addressData.exists) {
        final address = addressData.data()?["Address"] ?? "";

        showAddressDialog(address);
        print("User address: $address");
        print("USERID: ${user?.uid}");

      } else {
        print("User address data does not exist.");
      }
    } catch (e) {
      print("Error fetching user address: $e");
    }
  }

  Future<void> payment(double amount, List<CartModel> cartModel) async {
    try {
      int amountCents = amount.round() * 100;
      print(amountCents);
      Map<String, dynamic> body = {
        "amount": amountCents.toString(),
        "currency": "MYR"
      };
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
          .then((value) => {makeOrder(cartModel), print("Payment Success")});
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

  makeOrder(List<CartModel> cartModel) async {
    for (var cartItem in cartModel) {
      // Fetch the document reference for the current item in the cart
      final cartItemDocRef = FirebaseFirestore.instance
          .collection("Users")
          .doc(user?.uid.toString())
          .collection("Cart")
          .doc(cartItem.productID);

      final cartItemData = await cartItemDocRef.get();

      // Check if the Cart item exists before proceeding
      if (cartItemData.exists) {
        // Add the cart item data to the "Order" collection
        final orderDocRef =
            await FirebaseFirestore.instance.collection("Orders").add({
          'UID': user?.uid.toString(),
          'Date': currentDate,
          'Status': "Ready to Pack",
          ...cartItemData.data()!, // Include existing cart item data
        });

        await orderDocRef.update({'OrderID': orderDocRef.id});

        final inventoryData = await FirebaseFirestore.instance
            .collection("Product")
            .doc(cartItem.productID)
            .get();

        int inventory = inventoryData.data()?["Inventory"];

        await FirebaseFirestore.instance
            .collection("Product")
            .doc(cartItem.productID)
            .update({
          "Inventory": inventory - 1,
        });

        // Delete the item from the "Cart" collection after it's added to the "Order" collection
        await cartItemDocRef.delete();
      } else {
        // Handle the case where the Cart item does not exist
        print("Item does not exist in the cart: ${cartItem.productID}");
      }
    }
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
              if (cart.isEmpty && quantity == 0) {
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
                                      'RM ${totalPrice.toStringAsFixed(2)}',
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
                                            cart.isEmpty
                                                ? Flushbar(
                                                    icon: Icon(
                                                      Icons.info_outline,
                                                      size: 28.0,
                                                      color: Colors.blue[300],
                                                    ),
                                                    animationDuration:
                                                        const Duration(
                                                            seconds: 1),
                                                    duration: const Duration(
                                                        seconds: 1),
                                                    margin: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 6.0,
                                                        vertical: 70),
                                                    flushbarStyle:
                                                        FlushbarStyle.FLOATING,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    leftBarIndicatorColor:
                                                        Colors.blue[300],
                                                    message: "Cart is Empty!",
                                                  ).show(context)
                                                : checkUserAddress();

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
