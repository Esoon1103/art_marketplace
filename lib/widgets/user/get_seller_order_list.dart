import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';

import '../../model/order_model.dart';
import '../../model/product_model.dart';
import '../../model/user_model.dart';

class GetSellerOrderList extends StatefulWidget {
  final String orderStatus;

  const GetSellerOrderList({super.key, required this.orderStatus});

  @override
  State<GetSellerOrderList> createState() => _GetSellerOrderListState();
}

class _GetSellerOrderListState extends State<GetSellerOrderList> {
  final User? user = FirebaseAuth.instance.currentUser;

  Stream fetchOrdersForCurrentUser() async* {
    if (user != null) {
      // Get the products that match the current user's UID
      QuerySnapshot<Map<String, dynamic>> productsSnapshot =
          await FirebaseFirestore.instance
              .collection('Product')
              .where('UID', isEqualTo: user?.uid)
              .get();

      List<String> productIds =
          productsSnapshot.docs.map((doc) => doc.id).toList();

      // Get the orders where the product ID is in the list of product IDs
      QuerySnapshot<Map<String, dynamic>> ordersSnapshot =
          await FirebaseFirestore.instance
              .collection('Orders')
              .where('ProductID', whereIn: productIds)
              .where("Status", isEqualTo: widget.orderStatus)
              .get();

      yield ordersSnapshot;
    }
  }

  Future<ProductModel> getProductDetail(OrderModel orderModel) async {
    DocumentSnapshot<Map<String, dynamic>> product = await FirebaseFirestore
        .instance
        .collection('Product')
        .doc(orderModel.productID)
        .get();

    ProductModel productModel = ProductModel(
        name: product["Name"],
        description: product["Desc"],
        location: product["Location"],
        price: product["Price"],
        uid: product["UID"],
        image: product["Image"],
        image3D: product["3D Image"],
        category: product["Category"],
        inventory: product["Inventory"],
        productID: product["ProductID"]);

    return productModel;
  }

  Future<Map<String, dynamic>> getOrderDetails(OrderModel orderModel) async {
    ProductModel productModel = await getProductDetail(orderModel);

    DocumentSnapshot<Map<String, dynamic>> userSnapshot =
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(orderModel.uid)
            .get();

    UserModel userModel = UserModel(
      uid: userSnapshot['UID'],
      username: userSnapshot['Username'],
      email: userSnapshot['Email'],
      address: userSnapshot['Address'],
      phone: userSnapshot["Phone"],
      seller: userSnapshot["Seller"],
      isAdmin: userSnapshot["isAdmin"],
    );

    // Combine the data into a map
    Map<String, dynamic> orderDetails = {
      'productModel': productModel,
      'userModel': userModel,
    };

    return orderDetails;
  }

  updateOrderStatus(OrderModel orderModel, String newStatus) async {
    await FirebaseFirestore.instance
        .collection("Orders")
        .doc(orderModel.orderId)
        .update({
      "Status": newStatus.toString(),
    });
  }

  showUserDetailsDialog(UserModel userModel) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('User Details'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Username:\n ${userModel.username}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Phone:\n ${userModel.phone}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Email:\n ${userModel.email}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Address:\n ${userModel.address}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Ok'),
              onPressed: () async {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: fetchOrdersForCurrentUser(),
        builder: (context, snapshot) {
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
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Text('No products available.');
          } else {
            List<OrderModel> orders = [
              for (var order in snapshot.data!.docs)
                OrderModel(
                    uid: order["UID"],
                    productID: order["ProductID"],
                    quantity: order["Quantity"],
                    date: order["Date"],
                    status: order["Status"],
                    orderId: order["OrderID"]),
            ];

            return ListView.builder(
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: orders.length,
              itemBuilder: (BuildContext context, int index) {
                return FutureBuilder(
                  future: getOrderDetails(orders[index]),
                  builder: (context, futureSnapshot) {
                    if (futureSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (futureSnapshot.hasError) {
                      return Text('Error: ${futureSnapshot.error}');
                    } else {
                      Map<String, dynamic> orderDetails = futureSnapshot.data!;

                      ProductModel productModel = orderDetails['productModel'];
                      UserModel userModel = orderDetails['userModel'];
                      return buildOrderCard(
                          orders[index], productModel, userModel);
                    }
                  },
                );
              },
            );
          }
        });
  }

  Widget buildOrderCard(
    OrderModel orders,
    ProductModel productModel,
    UserModel userModel,
  ) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
                // Replace the image provider with your actual image loading logic
                image: DecorationImage(
                  image: NetworkImage(productModel.image),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          productModel.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow
                              .ellipsis, // This line handles overflow
                          maxLines: 3,
                        ),
                      ),
                      Text(
                        'Date: ${orders.date}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),
                  // Order Status
                  Row(
                    children: [
                      if (orders.status ==
                          'Delivered') // Show text if status is Delivered
                        Text('Status: ${orders.status}'),
                      if (orders.status !=
                          'Delivered') // Show dropdown if status is not Delivered
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: orders.status,
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                updateOrderStatus(orders, newValue);
                                setState(() {
                                  orders.status = newValue;
                                });
                              }
                            },
                            items: (orders.status == 'Ready to Pack')
                                ? [
                                    const DropdownMenuItem(
                                      value: 'Ready to Pack',
                                      child: Text('Ready to Pack'),
                                    ),
                                    const DropdownMenuItem(
                                      value: 'Delivering',
                                      child: Text('Delivering'),
                                    ),
                                  ]
                                : (orders.status == 'Delivering')
                                    ? [
                                        const DropdownMenuItem(
                                          value: 'Delivering',
                                          child: Text('Delivering'),
                                        ),
                                        const DropdownMenuItem(
                                          value: 'Delivered',
                                          child: Text('Delivered'),
                                        ),
                                      ]
                                    : [],
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            showUserDetailsDialog(userModel);
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white, backgroundColor: Colors.blue, // Text color
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10), // Padding
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  10), // Button border radius
                            ),
                            elevation: 3, // Button elevation
                          ),
                          child: const Text(
                            "View User Details",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'RM${(double.parse(productModel.price) * int.parse(orders.quantity)).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'Qty:${orders.quantity}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    children: [
                      const Spacer(),
                      RichText(
                        text: TextSpan(
                          text: 'Total(${orders.quantity} item): ',
                          style: DefaultTextStyle.of(context).style,
                          children: <TextSpan>[
                            TextSpan(
                              text:
                                  'RM${(double.parse(productModel.price) * int.parse(orders.quantity)).toStringAsFixed(2)}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
