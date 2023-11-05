import 'dart:convert';
import 'dart:math';
import 'package:another_flushbar/flushbar.dart';
import 'package:art_marketplace/model/order_model.dart';
import 'package:art_marketplace/widgets/user/loading_indicator_design.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:mailer/mailer.dart' as mailer;
import 'package:mailer/smtp_server/gmail.dart';
import 'package:path_provider/path_provider.dart';
import '../../model/cart_model.dart';
import '../../model/product_model.dart';
import 'cart_item.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';

class Cart extends StatefulWidget {
  const Cart({super.key});

  @override
  State<Cart> createState() => _CartState();
}

class _CartState extends State<Cart> {
  final User? user = FirebaseAuth.instance.currentUser;
  double totalPrice = 0;
  List<CartModel> cart = [];
  List<ProductModel> orderedProducts = [];
  List<OrderModel> invoiceOrders = [];
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
      print(user?.email);
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

  showAddressDialog(String? address, double totalPrice) async {
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

  checkUserAddress(double totalPrice) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> addressData =
          await FirebaseFirestore.instance
              .collection("Users")
              .doc(user?.uid.toString())
              .get();

      if (addressData.exists) {
        final address = addressData.data()?["Address"] ?? "";

        showAddressDialog(address, totalPrice);
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
              "Bearer ${dotenv.env["SECRET_KEY"]!}",
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
    double totalPrice = 0;
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

        final productData = await FirebaseFirestore.instance
            .collection("Product")
            .doc(cartItem.productID)
            .get();

        final orderData = await FirebaseFirestore.instance
            .collection("Orders")
            .doc(orderDocRef.id)
            .get();

        // Create a ProductModel instance and add it to the list
        ProductModel orderedProduct = ProductModel(
          name: productData.data()?["Name"],
          description: productData.data()?["Desc"],
          price: (productData.data()?["Price"]).toString(),
          location: productData.data()?["Location"],
          uid: productData.data()?["UID"],
          image: productData.data()?["Image"],
          image3D: productData.data()?["3D Image"],
          category: productData.data()?["Category"],
          inventory: productData.data()?["Inventory"],
          productID: productData.data()?["ProductID"],
          // Add other properties as needed
        );

        OrderModel orderModel = OrderModel(
            quantity: orderData.data()?["Quantity"],
            productID: orderData.data()?["ProductID"],
            date: orderData.data()?["Date"],
            uid: orderData.data()?["UID"],
            status: orderData.data()?["Status"],
            orderId: orderData.data()?["OrderID"]);

        orderedProducts.add(orderedProduct);
        invoiceOrders.add(orderModel);

        // Calculate the total price for each product based on its quantity
        double productPrice = double.parse(productData.data()!["Price"].toString());
        int quantity = int.parse(orderData.data()?["Quantity"]);
        double productTotalPrice = productPrice * quantity;

        // Add the product total price to the overall order total
        totalPrice += productTotalPrice;

        //Decrease the product inventory
        int inventory = productData.data()?["Inventory"];
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

    generateInvoice(invoiceOrders, orderedProducts, totalPrice);

    print('Order placed successfully, and email sent.');
  }

  Future<void> generateInvoice(List<OrderModel> orders,
      List<ProductModel> products, double totalPrice) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Address: $addressValue'),
              // Add other information as needed
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            context: context,
            data: <List<String>>[
              ['Order ID', 'Product Name', 'Description', 'Price', 'Quantity', 'Total'],
              for (var order in orders)
                for (var product in products)
                  if (product.productID == order.productID)
                    [
                      order.orderId,
                      product.name,
                      product.description,
                      product.price.toString(),
                      order.quantity.toString(),
                      (double.parse(order.quantity) * double.parse(product.price)).toString(),
                    ],
              // Add other information as needed
            ],
            border: pw.TableBorder.all(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: pw.BoxDecoration(
              borderRadius: pw.BorderRadius.circular(2),
              color: PdfColors.grey,
            ),
            cellHeight: 30,
            cellPadding: const pw.EdgeInsets.all(5),
          ),
          pw.SizedBox(height: 20),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text('Total Price: \$${totalPrice.toString()}'),
            ],
          ),
          // Add other information as needed
        ],
      ),
    );

    // Get the temporary directory using path_provider
    final tempDir = await getTemporaryDirectory();

    // Save the PDF to a file in the temporary directory
    final tempFile = File('${tempDir.path}/invoice_temp.pdf');
    await tempFile.writeAsBytes(await pdf.save());

    final email = dotenv.env['EMAIL']!;
    final password = dotenv.env['PASSWORD']!;
    String? username = user?.displayName;
    final invoiceId = generateInvoiceId();

    //Email SMTP Starts here
    final smtpServer = gmail(email, password);
    final message = mailer.Message()
      ..from = mailer.Address(email, 'Artsylane')
      ..recipients.add('p20012522@student.newinti.edu.my')
      ..subject = 'Order Confirmation - Invoice Attached (ID: $invoiceId)'
      ..text =
          'Dear $username,\n\nThank you for your recent purchase with Artsylane. '
              'Please find the attached invoice for your reference.\n\nBest regards,\nArtsylane Team'
      ..attachments.add(mailer.FileAttachment(tempFile));

    try {
      final sendReport = await mailer.send(message, smtpServer);
      print('Message sent: $sendReport');
    } on mailer.MailerException catch (e) {
      print('Message not sent. ${e.message}');
    } finally {
      // Delete the temporary file
      await tempFile.delete();
    }
  }

  String generateInvoiceId() {
    // Generate a random number for the unique identifier
    final uniqueId = Random().nextInt(999999);

    // Add a prefix to the invoice ID (you can customize this)
    final prefix = 'INV';

    // Get the current timestamp to add to the invoice ID
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Combine the elements to create the invoice ID
    final invoiceId = '$prefix-$uniqueId-$timestamp';

    return invoiceId;
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
                      return const LoadingIndicatorDesign();
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
                            return const LoadingIndicatorDesign();
                          } else if (totalPriceSnapshot.hasError) {
                            return Text(
                              'Error calculating total price: ${totalPriceSnapshot.error}',
                            );
                          } else {
                            totalPrice = totalPriceSnapshot.data ?? 0;
                            print("Total $totalPrice");

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
                                                : checkUserAddress(totalPrice);
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
