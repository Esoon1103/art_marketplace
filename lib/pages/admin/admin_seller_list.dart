import 'package:art_marketplace/model/seller_form_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../widgets/admin/seller_list_card.dart';
import 'admin_login.dart';

class AdminSellerList extends StatefulWidget {
  const AdminSellerList({super.key});

  @override
  State<AdminSellerList> createState() => _AdminSellerListState();
}

class _AdminSellerListState extends State<AdminSellerList> {
  final User? user = FirebaseAuth.instance.currentUser;

  void signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminLogin(),
      ),
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _getSellerList() {
    if (user != null) {
      return FirebaseFirestore.instance
          .collection('SellerApplicationForm')
          .where("Approval", isEqualTo: "Waiting for Review")
          .snapshots();
    } else {
      return const Stream.empty();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Artsylane Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => signOut(),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = kIsWeb ? constraints.maxWidth ~/ 400 : 2;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: StreamBuilder(
                stream: _getSellerList(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text('No form available.');
                  } else {
                    List<SellerFormModel> sellerForm = [
                      for (var form in snapshot.data!.docs)
                        SellerFormModel(
                          uid: form["UID"],
                          desc: form["BusinessDesc"],
                          approval: form["Approval"],
                          fileURL: List<String>.from(form["fileURL"] ?? []),
                        )
                    ];

                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: sellerForm.length,
                      itemBuilder: (BuildContext context, int index) {
                        return SellerListCard(
                            sellerFormModel: sellerForm[index]);
                      },
                    );
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
