import 'package:art_marketplace/pages/user/seller_form.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SellerCentre extends StatefulWidget {
  const SellerCentre({super.key});

  @override
  State<SellerCentre> createState() => _SellerCentreState();
}

class _SellerCentreState extends State<SellerCentre> {
  final User? user = FirebaseAuth.instance.currentUser;
  String? approval = "false";
  bool isLoading = true;

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

    Future.delayed(Duration(seconds: 1), () {
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
            ? const CircularProgressIndicator(
                strokeWidth: 4.0,
              ) // Show a loading indicator while data is being fetched
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (approval == "Waiting for review" ||
                          approval == null ||
                          approval == "Rejected")
                        Column(
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
                        Column(
                          children: [
                            const Text(
                              "Manage product!",
                              style: TextStyle(
                                fontSize: 20,
                              ),
                            ),
                          ],
                        )
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
