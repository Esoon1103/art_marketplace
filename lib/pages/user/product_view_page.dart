import 'package:another_flushbar/flushbar.dart';
import 'package:art_marketplace/model/product_model.dart';
import 'package:art_marketplace/pages/user/product_view_ar_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/user/loading_indicator_design.dart';

class ProductViewPage extends StatefulWidget {
  final ProductModel product;

  const ProductViewPage({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  State<ProductViewPage> createState() => _ProductViewPageState();
}

class _ProductViewPageState extends State<ProductViewPage> {
  String? sellerName = "";
  String sellerUID = "";
  int latestInventory = 0;
  int cartQuantity = 0;
  bool isLoading = true;
  bool maxQuantity = false;
  final User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController currentNumberController =
      TextEditingController(text: "1");

  @override
  void initState() {
    super.initState();
    print("Product Name Fetched: ${widget.product.name}");
    getSellerName();
    getInventory();
    getCartQuantity();
    print(latestInventory);
  }

  @override
  void dispose(){
    currentNumberController.dispose();
    super.dispose();
  }

  getCartQuantity() async {
    //Search if the product is already exist in cart
    final QuerySnapshot<Map<String, dynamic>> cartProduct =
    await FirebaseFirestore.instance
        .collection("Users")
        .doc(user?.uid.toString())
        .collection("Cart")
        .where("ProductID", isEqualTo: widget.product.productID)
        .get();

    // Check if the product is found in the cart
    if (cartProduct.docs.isNotEmpty) {
      print("not empty");
      setState(() {
        cartQuantity = int.parse(cartProduct.docs[0].data()["Quantity"]);
      });
    } else {
      return 0;
    }
  }

  getSellerName() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> getUIDinProduct =
          await FirebaseFirestore.instance
              .collection("Product")
              .limit(1) //limit result to only 1 document
              .get();

      if (getUIDinProduct.docs.isNotEmpty) {
        sellerUID = getUIDinProduct.docs[0].get("UID");

        QuerySnapshot<Map<String, dynamic>> getSeller = await FirebaseFirestore
            .instance
            .collection("Users")
            .where("UID", isEqualTo: sellerUID)
            .get();

        if (getSeller.docs.isNotEmpty) {
          if (mounted) {
            setState(() {
              sellerName = getSeller.docs[0].get("Username");
              isLoading = false;
            });
          }
        } else {
          setState(() {
            sellerName = "Unavailable";
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error getting seller name: $e");
    }
  }

  getInventory() async {
    //retrieve current product id
    final DocumentSnapshot<Map<String, dynamic>> inventory =
        await FirebaseFirestore.instance
            .collection("Product")
            .doc(widget.product.productID)
            .get();

    latestInventory = inventory.data()?["Inventory"];
  }

  void _incrementNumber() async {
    await getInventory();

    if (latestInventory == 0) {
      // If the firestore inventory is 0
      setState(() {
        currentNumberController.text = "Out of Stock";
      });
    } else {
      int cartValue = int.parse(currentNumberController.text);

      if (cartValue < latestInventory) {
        setState(() {
          currentNumberController.text = (cartValue + 1).toString();
        });
      } else {
        print("Max");
      }
    }
  }

  void _decrementNumber() async {
    await getInventory();
    print("Decrease");
    int value = int.tryParse(currentNumberController.text) ?? 1;

    if (latestInventory == 0) {
      // If the firestore inventory is 0
      setState(() {
        currentNumberController.text = "Out of Stock";
      });
    }

    if (value > 1) {
      setState(() {
        currentNumberController.text = (value - 1).toString();
      });
    }
  }

  showAddToCartDialog() async {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Center(child: Text('Cart')),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: currentNumberController,
                        keyboardType: TextInputType.number,
                        readOnly: true,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: 'Quantity',
                          suffixIcon: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_upward),
                                onPressed: latestInventory == 0
                                    ? null
                                    : () {
                                  getCartQuantity();
                                        if ((int.parse(currentNumberController //adding quantity + cart quantity is not exceed the total inventory e.g. 1 : 4 or 3 : 4
                                                .text) + cartQuantity) <
                                            latestInventory) {
                                          _incrementNumber();
                                        }else{
                                          print(currentNumberController.text);
                                          print(cartQuantity);
                                          print(latestInventory);
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
                                            message: "Your cannot add to cart by exceeding the total quantity of the product!",
                                          ).show(context);
                                        }
                                      },
                              ),
                              IconButton(
                                icon: const Icon(Icons.arrow_downward),
                                onPressed: latestInventory == 0
                                    ? null
                                    : () {
                                        if (int.parse(currentNumberController
                                                .text) >=
                                            1) {
                                          _decrementNumber();
                                        }
                                      },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context, 'Cancel');
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              child: const Text('ADD TO CART'),
              onPressed: () async {
                maxQuantity == true? null :
                await addToCart(widget.product.productID);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  checkCart() async {
    //Search if the product is already exist in cart
    final QuerySnapshot<Map<String, dynamic>> cartProduct =
    await FirebaseFirestore.instance
        .collection("Users")
        .doc(user?.uid.toString())
        .collection("Cart")
        .where("ProductID", isEqualTo: widget.product.productID)
        .get();

    //Update the product quantity if exist
    if (cartProduct.docs.isNotEmpty) {
      String cartQuantity = cartProduct.docs[0].data()["Quantity"];

      //if user cart product is already having the max inventory of the product
      //CHECK FOR CART
      if(int.parse(cartQuantity) == latestInventory){
        print("You already have the maximum quantity of the product in your cart");
        setState(() {
          maxQuantity = true;
        });
      }
    }
    print(maxQuantity);
  }

  addToCart(String productID) async {
    //Search if the product is already exist in cart
    final QuerySnapshot<Map<String, dynamic>> cartProduct =
        await FirebaseFirestore.instance
            .collection("Users")
            .doc(user?.uid.toString())
            .collection("Cart")
            .where("ProductID", isEqualTo: widget.product.productID)
            .get();

    //Update the product quantity if exist
    if (cartProduct.docs.isNotEmpty) {
      String cartQuantity = cartProduct.docs[0].data()["Quantity"];

      await FirebaseFirestore.instance
          .collection("Users")
          .doc(user?.uid.toString())
          .collection("Cart")
          .doc(widget.product.productID)
          .update({
        "Quantity": (int.parse(cartQuantity) + int.parse(currentNumberController.text.toString())).toString(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to Cart!')),
      );
      // Delay for 1 second and then hide the SnackBar
      Future.delayed(Duration(seconds: 1), () {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      });

    } else {
      //Add to cart for the product
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(user?.uid.toString())
          .collection("Cart")
          .doc(widget.product.productID)
          .set({
        "Quantity": currentNumberController.text.toString(),
        "ProductID": widget.product.productID,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to Cart!')),
      );
      // Delay for 1 second and then hide the SnackBar
      Future.delayed(Duration(seconds: 1), () {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? const LoadingIndicatorDesign()
          : CustomScrollView(slivers: [
              SliverAppBar(
                iconTheme: const IconThemeData(color: Colors.blue),
                expandedHeight: MediaQuery.of(context).size.height * 0.7,
                elevation: 0,
                snap: true,
                floating: true,
                stretch: true,
                backgroundColor: Colors.grey.shade50,
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                  ],
                  background:
                      Image.network(widget.product.image, fit: BoxFit.cover),
                ),
                bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(45),
                    child: Transform.translate(
                      offset: const Offset(0, 1),
                      child: Container(
                        height: 25,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                        ),
                        child: Center(
                            child: Container(
                          width: 50,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        )),
                      ),
                    )),
              ),
              SliverList(
                  delegate: SliverChildListDelegate([
                Container(
                    height: MediaQuery.of(context).size.height * 0.7,
                    color: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.product.name,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis, // This line handles overflow
                                      maxLines: 5,
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    widget.product.inventory <= 5
                                        ? Text(
                                            "\t${widget.product.inventory} items remaining",
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          )
                                        : const SizedBox(),
                                    const SizedBox(
                                      height: 15,
                                    ),
                                    widget
                                        .product.image3D != "" ? GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    ProductViewARPage(
                                                        product3DImage: widget
                                                            .product.image3D, productName: widget.product.name)));
                                      },
                                      child: SizedBox(
                                        height: 30,
                                        width: 90,
                                        child: DottedBorder(
                                          borderType: BorderType.RRect,
                                          radius: const Radius.circular(12),
                                          padding: const EdgeInsets.all(6),
                                          child: ClipRRect(
                                              borderRadius:
                                                  const BorderRadius.all(
                                                      Radius.circular(12)),
                                              child: Row(children: [
                                                Image.asset(
                                                    'assets/images/ar_logo.png'),
                                                const Text(
                                                  "View AR",
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ])),
                                        ),
                                      ),
                                    ) : const SizedBox(),
                                  ],
                                ),
                              ),
                              Text(
                                "RM ${widget.product.price}.00",
                                style: const TextStyle(
                                    color: Colors.black, fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 40,
                          ),
                          Text(
                            "Seller By: $sellerName",
                            style: TextStyle(
                              height: 1.5,
                              color: Colors.grey.shade800,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          Text(
                            "Location: ${widget.product.location}",
                            style: TextStyle(
                              height: 1.5,
                              color: Colors.grey.shade800,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          Text(
                            "Description: ${widget.product.description}",
                            style: TextStyle(
                              height: 1.5,
                              color: Colors.grey.shade800,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(
                            height: 30,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Flexible(
                                child: MaterialButton(
                                  onPressed: () async {
                                    await checkCart();
                                    latestInventory == 0 || maxQuantity == true
                                        ? null
                                        : showAddToCartDialog();

                                    if(maxQuantity == true){
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
                                        message: "You have reached the max quantity in your cart",
                                      ).show(context);
                                      return;
                                    }

                                  },
                                  height: 50,
                                  elevation: 0,
                                  splashColor: latestInventory != 0
                                      ? Colors.white54
                                      : Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  color: Colors.black87,
                                  child: Center(
                                    child: Text(
                                      latestInventory == 0
                                          ? "Out of Stock"
                                          : "Add to Cart",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 30,
                          ),
                        ],
                      ),
                    ))
              ])),
            ]),
    );
  }
}
