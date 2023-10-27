import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../model/product_model.dart';
import '../../widgets/user/search_card.dart';

class Search extends StatefulWidget {
  final TextEditingController searchQuery;

  const Search({super.key, required this.searchQuery});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  String searchText = "";
  bool filterHighSelection = false;
  bool filterLowSelection = false;
  String productType = "default";

  @override
  void initState() {
    searchText = widget.searchQuery.toString();
    print(searchText);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getSearchProducts() async {
    if (!filterLowSelection) {
      return FirebaseFirestore.instance
          .collection('Product')
          .orderBy('Price')
          .get();
    } else {
      return FirebaseFirestore.instance
          .collection('Product')
          .orderBy('Price', descending: true)
          .get();
    }
  }

  bool _containsAnyWord(String text, List<String> words) {
    return words.any((word) => text.contains(word));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        widget.searchQuery.clear();
        return Future.value(true);
      },
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 00.0,
          centerTitle: true,
          toolbarHeight: 60.2,
          toolbarOpacity: 0.8,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(25),
                bottomLeft: Radius.circular(25)),
          ),
          elevation: 0.00,
          title: const Text('Search Result'),
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                const SizedBox(
                  height: 10,
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: double.infinity),
                  child: Column(
                    children: [
                      ConstrainedBox(
                        constraints:
                            const BoxConstraints(minWidth: double.infinity),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 46,
                                    decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(8)),
                                    child: TextField(
                                      controller: widget.searchQuery,
                                      cursorColor: Colors.black,
                                      decoration: InputDecoration(
                                          prefixIcon: Icon(
                                            Icons.search,
                                            color: Colors.grey.shade700,
                                          ),
                                          border: InputBorder.none,
                                          hintText: "Vintage",
                                          hintStyle: TextStyle(
                                              color: Colors.grey.shade500)),
                                      textInputAction: TextInputAction.search,
                                      onChanged: (value) {
                                        setState(() {
                                          searchText = value;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: SizedBox(
                                    width: 50,
                                    height: 50,
                                    child: ElevatedButton(
                                      style: ButtonStyle(
                                        backgroundColor:
                                            MaterialStateProperty.all<Color>(
                                                Colors.orangeAccent),
                                        padding: MaterialStateProperty.all<
                                                EdgeInsetsGeometry>(
                                            EdgeInsets.zero),
                                      ),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title:
                                                Text("Filter for $searchText"),
                                            content: SizedBox(
                                              height: 250,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      ElevatedButton(
                                                        onPressed: () {
                                                          filterLowSelection =
                                                              true;
                                                          filterHighSelection =
                                                              false;
                                                          setState(() {});
                                                          Navigator.of(context,
                                                                  rootNavigator:
                                                                      true)
                                                              .pop('dialog');
                                                        },
                                                        child: const Row(
                                                          children: [
                                                            Icon(Icons
                                                                .arrow_upward),
                                                            Text(
                                                                "Price: Lowest to Highest"),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      ElevatedButton(
                                                        onPressed: () {
                                                          filterHighSelection =
                                                              true;
                                                          filterLowSelection =
                                                              false;
                                                          setState(() {});
                                                          Navigator.of(context,
                                                                  rootNavigator:
                                                                      true)
                                                              .pop('dialog');
                                                        },
                                                        child: const Row(
                                                          children: [
                                                            Icon(Icons
                                                                .arrow_downward),
                                                            Text(
                                                                "Price: Highest to Lowest"),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Icon(
                                        Icons.filter_list_rounded,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                if (filterHighSelection)
                                  OutlinedButton(
                                    onPressed: () {
                                      filterHighSelection = false;
                                      filterLowSelection = false;
                                      setState(() {});
                                    },
                                    child:
                                        const Text("Price: Highest to Lowest"),
                                  ),
                                if (filterLowSelection)
                                  OutlinedButton(
                                    onPressed: () {
                                      filterHighSelection = false;
                                      filterLowSelection = false;
                                      setState(() {});
                                    },
                                    child:
                                        const Text("Price: Lowest to Highest"),
                                  ),
                                if (productType == "Rent")
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: OutlinedButton(
                                      onPressed: () {
                                        productType = "default";
                                        setState(() {});
                                      },
                                      child: const Text("Type: Rent"),
                                    ),
                                  ),
                                if (productType == "Sell")
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: OutlinedButton(
                                      onPressed: () {
                                        productType = "default";
                                        setState(() {});
                                      },
                                      child: const Text("Type: Sell"),
                                    ),
                                  ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          future: getSearchProducts(),
                          builder: (BuildContext context,
                              AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>>
                                  snapshot) {
                            if (snapshot.hasError) {
                              print(snapshot.error);
                              return Text('Error: ${snapshot.error}');
                            }
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }

                            final List<DocumentSnapshot<Map<String, dynamic>>>
                                productDoc = snapshot.data!.docs;

                            List<ProductModel> products = [
                              for (var product in productDoc)
                                ProductModel(
                                    name: product["Name"],
                                    description: product["Desc"],
                                    location: product["Location"],
                                    price: product["Price"],
                                    uid: product["UID"],
                                    image: product["Image"],
                                    image3D: product["3D Image"],
                                    category: product["Category"],
                                    inventory: product["Inventory"],
                                    productID: product["ProductID"]),
                            ];

                            return ListView.builder(
                              scrollDirection: Axis.vertical,
                              shrinkWrap: true,
                              itemCount: productDoc.length,
                              itemBuilder: (BuildContext context, int index) {
                                //If search parameter is nothing or found
                                if (searchText.isEmpty ||
                                    _containsAnyWord(
                                        products[index].name.toLowerCase(),
                                        searchText.toLowerCase().split(' ')) ||
                                    _containsAnyWord(
                                        products[index]
                                            .description
                                            .toLowerCase(),
                                        searchText.toLowerCase().split(' ')) ||
                                    _containsAnyWord(
                                        products[index].location.toLowerCase(),
                                        searchText.toLowerCase().split(' ')) ||
                                    _containsAnyWord(
                                        products[index].category.toLowerCase(),
                                        searchText.toLowerCase().split(' '))) {
                                  // Display the product
                                  return SearchCard(
                                    productModel: products[index],
                                  );
                                } else {
                                  //if parameter did not found anything
                                  print("Nothing Found");
                                  if (index == 0) {
                                    return const Center(
                                      child: Text(
                                        'No results found',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    );
                                  }
                                }
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
