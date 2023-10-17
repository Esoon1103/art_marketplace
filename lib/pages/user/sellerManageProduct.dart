import 'package:art_marketplace/model/product_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class SellerManageProduct extends StatefulWidget {
  const SellerManageProduct({super.key});

  @override
  State<SellerManageProduct> createState() => _SellerManageProductState();
}

class _SellerManageProductState extends State<SellerManageProduct> {
  final User? user = FirebaseAuth.instance.currentUser;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String productName = "";
  String productDesc = "";
  String productCategory = "Visual Arts";
  String productPrice = "";
  String productLocation = "";
  String urlDownload = "";
  String url3dDownload = "";
  PlatformFile? file3D, file;
  UploadTask? task3D, task;
  final TextEditingController productNameController = TextEditingController();
  final TextEditingController productDescController = TextEditingController();
  final TextEditingController productPriceController = TextEditingController();
  final TextEditingController productLocationController =
      TextEditingController();

  @override
  dispose() {
    productNameController.clear();
    productDescController.clear();
    productPriceController.clear();
    productLocationController.clear();
    super.dispose();
  }

  Stream _getSellerProducts() {
    if (user != null) {
      Stream<QuerySnapshot<Object?>> snapshot = FirebaseFirestore.instance
          .collection('Product')
          .where("UID", isEqualTo: user?.uid.toString())
          .snapshots();

      return snapshot;
    } else {
      return const Stream.empty();
    }
  }

  selectImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg'],
    );

    if (result != null) {
      setState(() {
        file = result.files.single;
      });
    } else {
      return;
    }
  }

  select3DImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.any,
    );

    if (result != null) {
      setState(() {
        file3D = result.files.single;
      });
    } else {
      return;
    }
  }

  Future uploadImage() async {
    if (file == null) {
      print('Error: File is null.');
      // Handle the error or return early.
      return;
    }

    final path = 'sellerProductImage/${file!.name}';
    final File fileObject = File(file!.path!);

    final ref = FirebaseStorage.instance.ref().child(path);
    task = ref.putFile(fileObject);

    // Wait for the upload to complete
    final snapshot = await task!.whenComplete(() {
      print('Upload complete');
    });

    urlDownload = await snapshot.ref.getDownloadURL();
  }

  Future upload3DImage() async {
    if (file3D == null) {
      print('Error: File is null.');
      // Handle the error or return early.
      return;
    }

    final path = 'sellerProduct3DModel/${file3D!.name}';
    final File fileObject = File(file3D!.path!);

    final ref = FirebaseStorage.instance.ref().child(path);
    task3D = ref.putFile(fileObject);

    // Wait for the upload to complete
    final snapshot = await task3D!.whenComplete(() {
      print('Upload complete');
    });

    url3dDownload = await snapshot.ref.getDownloadURL();
  }

  createNewProduct() async {
    await FirebaseFirestore.instance.collection("Product").doc().set({
      "UID": user?.uid.toString(),
      "Image": urlDownload,
      "3D Image": url3dDownload,
      "Name": productNameController.text.toString(),
      "Desc": productDescController.text.toString(),
      "Price": productPriceController.text.toString(),
      "Location": productLocationController.text.toString(),
    });
  }

  addProductDialog() async {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => Form(
        key: _formKey,
        child: AlertDialog(
          title: const Text('Add Product'),
          content: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Product name cannot be empty!';
                      }
                      return null;
                    },
                    controller: productNameController,
                    decoration: const InputDecoration(
                      hintText: 'Name',
                      hintStyle: TextStyle(
                        color: Color(0xFF8391A1),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        productName = value;
                      });
                    },
                  ),
                  TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Product description cannot be empty!';
                      }
                      return null;
                    },
                    controller: productDescController,
                    decoration: const InputDecoration(
                      hintText: 'Description',
                      hintStyle: TextStyle(
                        color: Color(0xFF8391A1),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        productDesc = value;
                      });
                    },
                  ),
                  TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Product Price cannot be empty!';
                      }
                      return null;
                    },
                    controller: productPriceController,
                    decoration: const InputDecoration(
                      hintText: 'Price (RM)',
                      hintStyle: TextStyle(
                        color: Color(0xFF8391A1),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        productPrice = value;
                      });
                    },
                  ),
                  TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Location cannot be empty!';
                      }
                      return null;
                    },
                    controller: productLocationController,
                    decoration: const InputDecoration(
                      hintText: 'Location',
                      hintStyle: TextStyle(
                        color: Color(0xFF8391A1),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        productLocation = value;
                      });
                    },
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: 50,
                    child: Row(children: [
                      const Text(
                        "Category",
                        style: TextStyle(
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(
                        width: 40,
                      ),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: productCategory,
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                productCategory = newValue;
                              });
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Product Price cannot be empty!';
                            }
                            return null;
                          },
                          items: <String>['Visual Arts', 'Vintage', 'Nature']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(value),
                                  const SizedBox(width: 8),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ]),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: Row(children: [
                      const Text(
                        "Image      ",
                        style: TextStyle(
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(
                        width: 30,
                      ),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () {
                            selectImage();
                          },
                          icon: const Icon(Icons.upload_outlined),
                          label: file?.name == null
                              ? const Text('Select')
                              : Text(file!.name),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue,
                            backgroundColor: Colors.grey[200],
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: Row(children: [
                      const Text(
                        "3D Image \n(Optional)",
                        style: TextStyle(
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(
                        width: 30,
                      ),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () async {
                            select3DImage();
                          },
                          icon: const Icon(Icons.upload_outlined),
                          label: file3D?.name == null
                              ? const Text('Select')
                              : Text(file3D!.name),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue,
                            backgroundColor: Colors.grey[200],
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            );
          }),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, 'Cancel'),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                print(urlDownload);
                print(url3dDownload);
                try {
                  if (_formKey.currentState!.validate() || urlDownload == "") {
                    await uploadImage();
                    await upload3DImage();
                    await createNewProduct();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('New Product Added')),
                    );
                    Navigator.pop(context);
                  }
                } catch (e) {
                  print('Error add new product: $e');
                }
              },
              child: const Text('ADD'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          addProductDialog();
        },
        child: const Icon(Icons.add),
      ),
      appBar: AppBar(
        title: const Text('Manage Products'),
        backgroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              StreamBuilder(
                  stream: _getSellerProducts(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else if (!snapshot.hasData ||
                        snapshot.data!.docs.isEmpty) {
                      return const Text('No products available.');
                    } else {
                      //Initialize product list
                      List<ProductModel> products = [
                        for (var product in snapshot.data!.docs)
                          ProductModel(
                              name: product["Name"],
                              description: product["Desc"],
                              location: product["Location"],
                              price: product["Price"],
                              uid: product["UID"],
                              image: product["Image"],
                              image3D: product["3D Image"]),
                      ];

                      return ListView.builder(
                        scrollDirection: Axis.vertical,
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        itemCount: products.length,
                        itemBuilder: (BuildContext context, int index) {
                          // Use the 'products' list to build your UI
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            clipBehavior: Clip.antiAliasWithSaveLayer,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Image.network(
                                  products[index].image,
                                  height: 160,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                                Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(15, 15, 15, 0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        products[index].name,
                                        style: TextStyle(
                                          fontSize: 19,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      Text(
                                        products[index].location,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      Container(height: 10),
                                      Text(
                                        products[index].description,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      Row(
                                        children: <Widget>[
                                          Text(
                                            "RM ${products[index].price}",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const Spacer(),
                                          TextButton(
                                            style: TextButton.styleFrom(
                                              foregroundColor:
                                                  Colors.transparent,
                                            ),
                                            child: const Text(
                                              "EDIT",
                                              style:
                                                  TextStyle(color: Colors.blue),
                                            ),
                                            onPressed: () {},
                                          ),
                                          TextButton(
                                            style: TextButton.styleFrom(
                                              foregroundColor:
                                                  Colors.transparent,
                                            ),
                                            child: const Text(
                                              "DELETE",
                                              style:
                                                  TextStyle(color: Colors.red),
                                            ),
                                            onPressed: () {},
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(height: 5),
                              ],
                            ),
                          );
                        },
                      );
                    }
                  }),
              SizedBox(height: 75,)
            ],
          ),
        ),
      ),
    );
  }
}
