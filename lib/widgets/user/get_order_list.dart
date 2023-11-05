import 'package:art_marketplace/model/product_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../model/order_model.dart';
import 'loading_indicator_design.dart';

class GetOrderList extends StatefulWidget {
  final String orderStatus;

  const GetOrderList({super.key, required this.orderStatus});

  @override
  State<GetOrderList> createState() => _GetOrderListState();
}

class _GetOrderListState extends State<GetOrderList> {
  final User? user = FirebaseAuth.instance.currentUser;

  Stream getPackOrder() {
    if (user != null) {
      Stream<QuerySnapshot<Object?>> snapshot = FirebaseFirestore.instance
          .collection('Orders')
          .where("UID", isEqualTo: user?.uid.toString())
          .where("Status", isEqualTo: widget.orderStatus)
          .snapshots();
      return snapshot;
    } else {
      return const Stream.empty();
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: getPackOrder(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicatorDesign();
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
                  future: getProductDetail(orders[index]),
                  builder: (context, futureSnapshot) {
                    if (futureSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const LoadingIndicatorDesign();
                    } else if (futureSnapshot.hasError) {
                      return Text('Error: ${futureSnapshot.error}');
                    } else {
                      ProductModel? productModel = futureSnapshot.data;
                      return buildOrderCard(orders[index], productModel!);
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
            Row(
              children: [

              ],
            ),
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
                          overflow: TextOverflow.ellipsis, // This line handles overflow
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
                      const SizedBox(width: 8),
                      Text(
                        orders.status,
                        style: const TextStyle(
                          fontSize: 16,
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
                  const SizedBox(height: 20,),
                  Row(
                    children: [
                      const Spacer(),
                      RichText(
                        text: TextSpan(
                          text: 'Total(${orders.quantity} item): ',
                          style: DefaultTextStyle.of(context).style,
                          children: <TextSpan>[
                            TextSpan(
                              text: 'RM${(double.parse(productModel.price) * int.parse(orders.quantity)).toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
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
