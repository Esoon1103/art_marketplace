import 'package:art_marketplace/pages/user/sellerManageOrder.dart';
import 'package:art_marketplace/pages/user/sellerManageProduct.dart';
import 'package:art_marketplace/pages/user/seller_form.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';

class SellerCentre extends StatefulWidget {
  const SellerCentre({super.key});

  @override
  State<SellerCentre> createState() => _SellerCentreState();
}

class _SellerCentreState extends State<SellerCentre> {
  final User? user = FirebaseAuth.instance.currentUser;
  String? approval = "false";
  bool isLoading = true;
  bool onTap = false;
  bool onTap1 = false;
  int index = 0;
  List<bool> onTapList = List.filled(4, false);

  @override
  initState() {
    super.initState();
    checkSellerStatus();
  }

  checkSellerStatus() async {
    final DocumentSnapshot<Map<String, dynamic>> sellerFormData =
        await FirebaseFirestore.instance
            .collection("SellerApplicationForm")
            .doc(user?.uid.toString())
            .get();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          approval = sellerFormData.data()?["Approval"].toString();
          isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Centre'),
        backgroundColor: Colors.black87,
      ),
      body: Center(
        child: isLoading
            ? const SizedBox(
                width: 50,
                child: LoadingIndicator(
                  indicatorType: Indicator.ballRotateChase,
                  colors: [Colors.blueGrey],
                  strokeWidth: 1,
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (approval == "Waiting for review" ||
                        approval == null ||
                        approval == "Rejected")
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            "Begin your Business Now!",
                            style: TextStyle(
                              fontSize: 20,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SellerForm(),
                                ),
                              );
                            },
                            child: const Text(
                              "Apply Now!",
                              style: TextStyle(
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Align(
                        alignment: Alignment.topCenter,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  onTap = !onTap;
                                  onTap1 = false;
                                });

                                Future.delayed(const Duration(milliseconds: 150), () {
                                  setState(() {
                                    onTap = false;
                                    onTap1 = false;
                                  });
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SellerManageProduct()));
                                });
                              },
                              child: AnimatedContainer(
                                width: MediaQuery.of(context).size.width,
                                height: 200,
                                duration: const Duration(milliseconds: 100),
                                padding: const EdgeInsets.all(10.0),
                                decoration: BoxDecoration(
                                  color: onTap
                                      ? Colors.amber.shade50
                                      : Colors.grey.shade100,
                                  border: Border.all(
                                    color: onTap
                                        ? Colors.amber
                                        : Colors.black12,
                                    width: 2.0,
                                  ),
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                            Text(
                                              "Manage Products",
                                              style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: onTap
                                                      ? Colors.amber.shade800
                                                      : Colors.black),
                                            )
                                        ],
                                      ),
                                    ]),
                              ),
                            ),
                            const SizedBox(height: 25,),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  onTap = false;
                                  onTap1 = !onTap1;
                                });

                                Future.delayed(const Duration(milliseconds: 150), () {
                                  setState(() {
                                    onTap = false;
                                    onTap1 = false;
                                  });
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SellerManageOrder()));
                                });


                              },
                              child: AnimatedContainer(
                                width: MediaQuery.of(context).size.width,
                                height: 200,
                                duration: const Duration(milliseconds: 100),
                                padding: const EdgeInsets.all(10.0),
                                decoration: BoxDecoration(
                                  color: onTap1
                                      ? Colors.amber.shade50
                                      : Colors.grey.shade100,
                                  border: Border.all(
                                    color: onTap1
                                        ? Colors.amber
                                        : Colors.black12,
                                    width: 2.0,
                                  ),
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                            Text(
                                              "Manage Orders",
                                              style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: onTap1
                                                      ? Colors.amber.shade800
                                                      : Colors.black),
                                            )
                                        ],
                                      ),
                                    ]),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
