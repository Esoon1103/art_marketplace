import 'package:art_marketplace/pages/user/search.dart';
import 'package:art_marketplace/widgets/user/get_visual_art_product.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  String? displayName = "";
  String currentDate = DateFormat("yyyy-MM-dd").format(DateTime.now());
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    updateDisplayName();
    super.initState();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  getUsername() async {
    final DocumentSnapshot<Map<String, dynamic>> getUsername =
        await FirebaseFirestore.instance
            .collection("Users")
            .doc(user?.uid.toString())
            .get();
    displayName = getUsername.data()?["Username"].toString();
  }

  updateDisplayName() async {
    await getUsername();
    await FirebaseAuth.instance.currentUser!.updateDisplayName(displayName);
  }

  void beginSearch(String value) {
    if (value.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Search(
            searchQuery: searchController,
          ),
        ),
      );
    } else {
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: NestedScrollView(
            headerSliverBuilder: (context, value) {
              return [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 30,
                        ),
                        FadeInDown(
                          child: Row(
                            children: [
                              Text(
                                "The Art from Penangnites  🔥",
                                style: TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade800,
                                    height: 1.5),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        FadeInDown(
                          delay: const Duration(milliseconds: 200),
                          duration: const Duration(milliseconds: 500),
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8)),
                            child: TextFormField(
                              controller: searchController,
                              onFieldSubmitted: (searchValue) {
                                beginSearch(searchValue);
                              },
                              cursorColor: Colors.black,
                              decoration: InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: Colors.grey.shade700,
                                  ),
                                  border: InputBorder.none,
                                  hintText: "Vintage",
                                  hintStyle:
                                      TextStyle(color: Colors.grey.shade500)),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                )
              ];
            },
            body: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  FadeInDown(
                    delay: const Duration(milliseconds: 200),
                    child: TabBar(
                        labelColor: Colors.black,
                        unselectedLabelColor: Colors.grey.shade600,
                        indicatorColor: Colors.black,
                        tabs: const [
                          Tab(
                            text: "Visual Arts",
                          ),
                          Tab(
                            text: "Vintage",
                          ),
                          Tab(
                            text: "Nature",
                          )
                        ]),
                  ),
                  const Expanded(
                    child: TabBarView(
                      children: [
                        GetVisualArtProduct(productCategory: "Visual Arts"),
                        GetVisualArtProduct(productCategory: "Vintage"),
                        GetVisualArtProduct(productCategory: "Nature"),
                      ],
                    ),
                  )
                ],
              ),
            )));
  }
}
