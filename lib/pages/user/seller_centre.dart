import 'dart:async';

import 'package:another_flushbar/flushbar.dart';
import 'package:art_marketplace/pages/user/seller_manage_order.dart';
import 'package:art_marketplace/pages/user/seller_manage_product.dart';
import 'package:art_marketplace/pages/user/seller_form.dart';
import 'package:art_marketplace/services/stripe_backend_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/user/loading_indicator_design.dart';

class SellerCentre extends StatefulWidget {
  const SellerCentre({super.key});

  @override
  State<SellerCentre> createState() => _SellerCentreState();
}

class _SellerCentreState extends State<SellerCentre> {
  final User? user = FirebaseAuth.instance.currentUser;
  String? approval = "false";
  String rejectReason = "";
  bool isLoading = true;
  String accountId = "";

  @override
  initState() {
    super.initState();
    checkSellerStatus();
    getExistingAccountIdFromFirestore();
  }

  getExistingAccountIdFromFirestore() async {
    QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
        .collection("Users")
        .doc(user?.uid.toString())
        .collection("StripeId")
        .get();

    if (snapshot.docs.isNotEmpty) {
      // Take the first document in the list (you might want to handle multiple documents differently)
      DocumentSnapshot<Map<String, dynamic>> account = snapshot.docs[0];

      // Check if the document has a field named "accountId"
      if (account.data() != null && account.data()!["accountId"] != null) {
        // Update the state and print the accountId
        setState(() {
          accountId = account.data()?["accountId"];
        });
        print("Account ID: $accountId");
      } else {
        // The document doesn't have the expected field
        print("Document does not have 'accountId' field.");
      }
    }
  }

  checkSellerStatus() async {
    final DocumentSnapshot<Map<String, dynamic>> sellerFormData =
        await FirebaseFirestore.instance
            .collection("SellerApplicationForm")
            .doc(user?.uid.toString())
            .get();

    if (sellerFormData.data()?["Reason"] != null) {
      rejectReason = sellerFormData.data()?["Reason"];
    }

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        approval = sellerFormData.data()?["Approval"].toString();
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
                    if (approval == "Waiting for Review" ||
                        approval == "Rejected")
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            approval == "Waiting for Review"
                                ? "Your request has been submitted to the admin. Please wait for the approval."
                                : "Unfortunately, your request to be a seller has been REJECTED \n Reason: $rejectReason",
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
                                        builder: (context) =>
                                            const SellerForm(),
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
                            GestureDetector(
                              onTap: () async {
                                try {
                                  if(accountId != "" && accountId != null){
                                    print(accountId);
                                    Flushbar(
                                      icon: Icon(
                                        Icons.info_outline,
                                        size: 28.0,
                                        color: Colors.blue[300],
                                      ),
                                      animationDuration: const Duration(seconds: 1),
                                      duration: const Duration(seconds: 1),
                                      margin:
                                      const EdgeInsets.symmetric(horizontal: 6.0, vertical: 30),
                                      flushbarStyle: FlushbarStyle.FLOATING,
                                      borderRadius: BorderRadius.circular(12),
                                      leftBarIndicatorColor: Colors.blue[300],
                                      message: "Connected with Stripe Payment!",
                                    ).show(context);
                                  }else{
                                    CreateAccountResponse response = await StripeBackendService.createSellerAccount();
                                    await canLaunch(response.url) ? await launch(response.url) : throw 'Could not launch URL';

                                    if (response.success) {
                                      // Successfully created a seller account
                                      print('Account ID: ${response.accountId}');
                                      print('URL: ${response.url}');

                                      print("Account id ${response.accountId}");

                                      // Save the new account ID in Firestore
                                      await FirebaseFirestore.instance
                                          .collection("Users")
                                          .doc(user?.uid.toString())
                                          .collection("StripeId")
                                          .doc(response.accountId.toString())
                                          .set({
                                        "accountId": response.accountId.toString(),
                                      });
                                    } else {
                                      print('Failed to create a seller account');
                                    }
                                  }
                                } catch (e) {
                                  print(e);
                                }
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
                                            "Payment: Connect With Stripe",
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.amber.shade800,
                                            ),
                                          ),
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
