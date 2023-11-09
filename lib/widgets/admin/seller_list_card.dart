
import 'package:another_flushbar/flushbar.dart';
import 'package:art_marketplace/model/seller_form_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../model/user_model.dart';

class SellerListCard extends StatefulWidget {
  final SellerFormModel sellerFormModel;

  const SellerListCard({super.key, required this.sellerFormModel});

  @override
  State<SellerListCard> createState() => _SellerListCardState();
}

class _SellerListCardState extends State<SellerListCard> {
  final User? user = FirebaseAuth.instance.currentUser;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController rejectReasonController = TextEditingController();
  String rejectReason = "";

  showRejectSellerDialog(UserModel userModel) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Form(
          key: _formKey,
          child: AlertDialog(
            title: const Text('Info'),
            contentPadding: const EdgeInsets.all(16.0),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.3,
              child: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text('Reasons to reject this seller ${userModel.username}'),
                    const SizedBox(
                      height: 20,
                    ),
                    TextFormField(
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please provide the reason!';
                        }
                        return null;
                      },
                      controller: rejectReasonController,
                      decoration: const InputDecoration(
                        labelText: "Rejection Details",
                        hintStyle: TextStyle(
                          color: Color(0xFF8391A1),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          rejectReason = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, 'Cancel'),
                child: const Text('Cancel'),
              ),
              TextButton(
                child: const Text('REJECT'),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await updateSellerStatus(userModel.uid, false);
                    Navigator.of(context).pop();
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
                      message: "User Rejected",
                    ).show(context);
                    rejectReasonController.clear();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  showApproveSellerDialog(UserModel userModel) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Form(
          key: _formKey,
          child: AlertDialog(
            title: const Text('Info'),
            contentPadding: const EdgeInsets.all(16.0),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.3,
              child: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text('Approving this seller ${userModel.username}'),
                    const SizedBox(
                      height: 20,
                    ),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, 'Cancel'),
                child: const Text('Cancel'),
              ),
              TextButton(
                child: const Text('CONFIRM'),
                onPressed: () async {
                    await updateSellerStatus(userModel.uid, true);
                    Navigator.of(context).pop();
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
                      message: "User Approved",
                    ).show(context);
                    rejectReasonController.clear();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  updateSellerStatus(String uid, bool seller) async {
    if(seller == false){
      await FirebaseFirestore.instance.collection("Users").doc(uid).update({
        "Seller": false,
      });

      await FirebaseFirestore.instance.collection("SellerApplicationForm").doc(uid).update({
        "Reason": rejectReasonController.text.toString(),
        "Approval": "Rejected",
      });
    }else{
      await FirebaseFirestore.instance.collection("Users").doc(uid).update({
        "Seller": true,
      });
      await FirebaseFirestore.instance.collection("SellerApplicationForm").doc(uid).update({
        "Approval": "Approved",
      });
    }
  }

  Future<UserModel?> getSellerDetails(String uid) async {
    if (user != null) {
      try {
        DocumentSnapshot<Map<String, dynamic>> user =
            await FirebaseFirestore.instance.collection('Users').doc(uid).get();

        if (user.exists) {
          return UserModel(
              email: user["Email"],
              phone: user["Phone"],
              uid: user["UID"],
              username: user["Username"],
              seller: user["Seller"],
              isAdmin: user["isAdmin"],
              address: user["Address"] ?? ""
          );
        } else {
          return null;
        }
      } catch (e) {
        print("Error fetching user details: $e");
        return null;
      }
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: getSellerDetails(widget.sellerFormModel.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.data == null) {
          return const Text('No such user available.');
        } else {
          UserModel userModel = snapshot.data!;

          return SingleChildScrollView(
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAliasWithSaveLayer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          "Username: ${userModel.username}",
                          style: TextStyle(
                            fontSize: kIsWeb ? 16 : 14,
                            color: Colors.grey[800],
                          ),
                        ),
                        Text(
                          "UID: ${widget.sellerFormModel.uid}",
                          style: TextStyle(
                            fontSize: kIsWeb ? 14 : 12,
                            color: Colors.grey[800],
                          ),
                        ),
                        Text(
                          "Phone: ${userModel.phone}",
                          style: TextStyle(
                            fontSize: kIsWeb ? 14 : 12,
                            color: Colors.grey[800],
                          ),
                        ),
                        Text(
                          "Email: ${userModel.email}",
                          style: TextStyle(
                            fontSize: kIsWeb ? 14 : 12,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          "Business Description: ${widget.sellerFormModel.desc}",
                          style: TextStyle(
                            fontSize: kIsWeb ? 12 : 10,
                            color: Colors.grey[700],
                          ),
                        ),
                        Container(height: 5),
                        const SizedBox(height: 15),
                        Text(
                          "Supporting Documents:",
                          style: TextStyle(
                            fontSize: kIsWeb ? 12 : 10,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 5),
                        Column(
                          children: widget.sellerFormModel.fileURL.map((url) {
                            return GestureDetector(
                              onTap: () {
                                // Handle the click event here, e.g., open the URL
                                launch(url);
                              },
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Text(
                                  url,
                                  style: const TextStyle(
                                    fontSize: kIsWeb ? 12 : 10,
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        Container(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.blue,
                              ),
                              child: const Text("Approve"),
                              onPressed: () async {
                                showApproveSellerDialog(userModel);
                              },
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text("Reject"),
                              onPressed: () {
                                showRejectSellerDialog(userModel);
                              },
                            ),
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
      },
    );
  }
}
