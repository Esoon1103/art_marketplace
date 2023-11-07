import 'dart:async';

import 'package:art_marketplace/pages/user/seller_manage_order.dart';
import 'package:art_marketplace/pages/user/seller_manage_product.dart';
import 'package:art_marketplace/pages/user/seller_form.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../widgets/user/loading_indicator_design.dart';

class SellerCentre extends StatefulWidget {
  const SellerCentre({super.key});

  @override
  State<SellerCentre> createState() => _SellerCentreState();
}

class _SellerCentreState extends State<SellerCentre> {
  final User? user = FirebaseAuth.instance.currentUser;
  String? approval = "false";
  bool isSeller = false;
  String rejectReason = "";
  bool isLoading = true;
  String accountId = "";

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

    final DocumentSnapshot<Map<String, dynamic>> isSellerData =
    await FirebaseFirestore.instance
        .collection("Users")
        .doc(user?.uid.toString())
        .get();

    if (sellerFormData.data()?["Reason"] != null) {
      rejectReason = sellerFormData.data()?["Reason"];
    }

    if (isSellerData.data()?["Seller"] != null) {
      isSeller = isSellerData.data()?["Seller"];
    }

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        approval = sellerFormData.data()?["Approval"].toString();
        isSeller = isSellerData.data()?["Seller"];
        isLoading = false;
      });
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
            ? const LoadingIndicatorDesign()
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isSeller == false )
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            approval == "Waiting for Review"
                                ? "Your request has been submitted to the admin. Please wait for the approval."
                                : approval == "Rejected"
                                ? "Unfortunately, your request to be a seller has been REJECTED \n Reason: $rejectReason"
                                : approval == "false" //No form submit before
                                ? "Apply Now!"
                                : "", // Display nothing if none of the conditions are met
                            style: const TextStyle(
                              fontSize: 20,
                            ),
                          ),
                          approval == "Rejected"
                              ? ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>  const SellerForm(),
                                ),
                              );
                            },
                            child: const Text(
                              "Re-Apply Now!",
                              style: TextStyle(
                                fontSize: 20,
                              ),
                            ),
                          )
                              : isSeller == false && approval != "Waiting for Review"
                              ? ElevatedButton(
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
                          )
                              : const SizedBox.shrink(),
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
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const SellerManageProduct()));
                              },
                              child: Container(
                                width: MediaQuery.of(context).size.width,
                                height: 200,
                                padding: const EdgeInsets.all(10.0),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  border: Border.all(
                                    color: Colors.black12,
                                    width: 2.0,
                                  ),
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Manage Products",
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.amber.shade800,
                                            ),
                                          )
                                        ],
                                      ),
                                    ]),
                              ),
                            ),
                            const SizedBox(
                              height: 25,
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const SellerManageOrder()));
                              },
                              child: Container(
                                width: MediaQuery.of(context).size.width,
                                height: 200,
                                padding: const EdgeInsets.all(10.0),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  border: Border.all(
                                    color: Colors.black12,
                                    width: 2.0,
                                  ),
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Manage Orders",
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.amber.shade800,
                                            ),
                                          )
                                        ],
                                      ),
                                    ]),
                              ),
                            ),
                            const SizedBox(
                              height: 25,
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
