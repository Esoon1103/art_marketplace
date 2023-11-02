import 'package:another_flushbar/flushbar.dart';
import 'package:art_marketplace/model/product_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'dart:io';

import 'package:flutter/services.dart';

class SellerManageProduct extends StatefulWidget {
  const SellerManageProduct({super.key});

  @override
  State<SellerManageProduct> createState() => _SellerManageProductState();
}

class _SellerManageProductState extends State<SellerManageProduct> {
  final User? user = FirebaseAuth.instance.currentUser;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String productID = "";
  String productName = "";
  String productDesc = "";
  String productCategory = "Visual Arts";
  String productPrice = "";
  String productLocation = "";
  String urlDownload = "";
  String url3dDownload = "";
  String imageFile = "";
  String image3DFile = "";
  PlatformFile? file3D, file;
  UploadTask? task3D, task;
  bool upload = false;
  bool upload3D = false;
  final TextEditingController productNameController = TextEditingController();
  final TextEditingController productDescController = TextEditingController();
  final TextEditingController productPriceController = TextEditingController();
  final TextEditingController productLocationController =
      TextEditingController();
  final TextEditingController inventoryController =
      TextEditingController(text: "0");

  @override
  dispose() {
    productNameController.clear();
    productDescController.clear();
    productPriceController.clear();
    productLocationController.clear();
    inventoryController.clear();
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
        imageFile = file!.name;
        upload = true;
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
      PlatformFile selected3DFile = result.files.single;
      if(selected3DFile.extension?.toLowerCase() == 'glb'){
        setState(() {
          file3D = result.files.single;
          image3DFile = file3D!.name;
          upload3D = true;
        });
      }else {
        // Show an alert dialog if the selected file is not a .glb file
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Invalid 3D File Format'),
              content: const Text('Please select a .glb file.'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } else {
      return;
    }
  }

  Future uploadImage(productID) async {
    if (file == null) {
      print('Error: File is null.');
      return;
    }

    final path = 'sellerProductImage/$productID/${file!.name}';
    final File fileObject = File(file!.path!);

    final ref = FirebaseStorage.instance.ref().child(path);
    task = ref.putFile(fileObject);

    final snapshot = await task!.whenComplete(() {
      print('Upload complete');
    });

    urlDownload = await snapshot.ref.getDownloadURL();

    File(file!.path!).delete();

    setState(() {
      file = null;
    });
  }

  Future upload3DImage(productID) async {
    if (file3D == null) {
      print('Error: File is null.');
      return;
    }

    final path = 'sellerProduct3DModel/$productID/${file3D!.name}';
    final File fileObject = File(file3D!.path!);

    // Create SettableMetadata to set the content type
    final SettableMetadata metadata = SettableMetadata(
      contentType: 'model/gltf-binary', // Set the correct content type for GLB files
    );

    final ref = FirebaseStorage.instance.ref().child(path);
    task3D = ref.putFile(
        fileObject,
        metadata
    );

    // Wait for the upload to complete
    final snapshot = await task3D!.whenComplete(() {
      print('Upload complete');
    });

    url3dDownload = await snapshot.ref.getDownloadURL();

    File(file3D!.path!).delete();

    setState(() {
      file3D = null;
    });
  }

  createNewProduct(productID) async {
    await FirebaseFirestore.instance.collection("Product").doc(productID).set({
      "UID": user?.uid.toString(),
      "Image": urlDownload,
      "3D Image": url3dDownload,
      "Name": productNameController.text.toString(),
      "Desc": productDescController.text.toString(),
      "Price": productPriceController.text.toString(),
      "Location": productLocationController.text.toString(),
      "Inventory": int.parse(inventoryController.text),
      "Category": productCategory.toString(),
      "ProductID": productID,
    });
  }

  void _increment() {
    if (inventoryController.text.isEmpty) {
      inventoryController.text = '1';
    } else {
      int value = int.parse(inventoryController.text);
      inventoryController.text = (value + 1).toString();
    }
  }

  void _decrement() {
    if (inventoryController.text.isEmpty) {
      inventoryController.text = '0';
    } else {
      int value = int.parse(inventoryController.text);
      if (value > 0) {
        inventoryController.text = (value - 1).toString();
      }
    }
  }

  showDeleteProductDialog(ProductModel product) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Warning'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure to delete this product? \nProduct Name: ${product.name}'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, 'Cancel'),
              child: const Text('Cancel'),
            ),
            TextButton(
              child: const Text('DELETE'),
              onPressed: () async {
                await deleteProduct(product.productID);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  deleteProduct(String productID) async {
    // Check if there are any orders with the specified productID
    QuerySnapshot<Map<String, dynamic>> ordersSnapshot = await FirebaseFirestore.instance
        .collection('Orders')
        .where('ProductID', isEqualTo: productID)
        .get();

    if (ordersSnapshot.docs.isEmpty) {
      await FirebaseFirestore.instance
          .collection("Product")
          .doc(productID)
          .delete();
      print("Delete the product from product collection");
    } else {
      // There are orders, update the product's inventory to 0
      await FirebaseFirestore.instance
          .collection("Product")
          .doc(productID)
          .update({'Inventory': 0});
      print("Update the product inventory to 0 from product collection");
    }
  }

  updateProduct(ProductModel product) async {
    await FirebaseFirestore.instance
        .collection("Product")
        .doc(product.productID)
        .update({
      "Image": urlDownload,
      "3D Image": url3dDownload,
      "Name": productNameController.text.toString(),
      "Desc": productDescController.text.toString(),
      "Price": productPriceController.text.toString(),
      "Location": productLocationController.text.toString(),
      "Inventory": int.parse(inventoryController.text),
      "Category": productCategory.toString(),
    });
  }

  showEditProductDialog(ProductModel product) {
    String productIDNew = product.productID;
    productNameController.text = product.name;
    productDescController.text = product.description;
    productPriceController.text = product.price;
    productLocationController.text = product.location;
    inventoryController.text = product.inventory.toString();
    productCategory = product.category;
    urlDownload = product.image;
    url3dDownload = product.image3D;

    print("Product Image: $urlDownload");
    print("Product3D Image: $url3dDownload");

    showDialog<String>(
      context: context,
      builder: (BuildContext context) => Form(
        key: _formKey,
        child: AlertDialog(
          title: const Text('Edit Product'),
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
                      labelText: "Name",
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
                      labelText: "Description",
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
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Product Price cannot be empty!';
                      }
                      return null;
                    },
                    controller: productPriceController,
                    decoration: const InputDecoration(
                      labelText: "Price (RM)",
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
                      labelText: 'Location',
                      hintText: 'Hin Bus Depot, George Town',
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
                    height: 70,
                    child: Row(children: [
                      const Text(
                        "Inventory",
                        style: TextStyle(
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(
                        width: 40,
                      ),
                      Expanded(
                        child: TextFormField(
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Inventory cannot be empty!';
                            } else if (value == "0") {
                              return "Inventory cannot be 0";
                            }
                            return null;
                          },
                          controller: inventoryController,
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            labelText: 'Inventory',
                            suffixIcon: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.arrow_upward),
                                  onPressed: _increment,
                                ),
                                IconButton(
                                  icon: Icon(Icons.arrow_downward),
                                  onPressed: _decrement,
                                ),
                              ],
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
                          onPressed: () async {
                            await selectImage();

                            if(upload == true){
                              setState(() {
                                // Update the state that should trigger a rebuild
                                // For example, update image3DFile
                                product.image = file?.name ?? '';
                              });
                            }else{
                              upload == false;
                            }
                          },
                          icon: const Icon(Icons.upload_outlined),
                          label: upload
                              ? Text(product.image)
                              : (urlDownload == null ? const Text('Select') : Text(urlDownload)),
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
                  SizedBox(height: 30,),
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
                            await select3DImage();

                            if(upload3D == true){
                              setState(() {
                                product.image3D = file3D?.name ?? '';
                                upload = true;
                              });
                            }

                          },
                          icon: const Icon(Icons.upload_outlined),
                          label: upload
                              ? Text(product.image3D)
                              : (url3dDownload == null ? const Text('Select') : Text(url3dDownload)),
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
              onPressed: () {
                Navigator.pop(context, 'Cancel');
              } ,
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  if (urlDownload == "") {
                    Flushbar(
                      backgroundColor: Colors.black,
                      message: "Please upload the product image",
                      duration: const Duration(seconds: 3),
                    ).show(context);
                    return;
                  }

                  if (_formKey.currentState!.validate()) {
                    if (upload == true) {
                      await uploadImage(productIDNew);
                      await upload3DImage(productIDNew);
                    }

                    await updateProduct(product);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Product Updated')),
                    );
                    Navigator.pop(context);
                  }
                } catch (e) {
                  print('Error update the product: $e');
                }
              },
              child: const Text('UPDATE'),
            ),
          ],
        ),
      ),
    );
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
                      labelText: "Name",
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
                      labelText: "Description",
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
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Product Price cannot be empty!';
                      }
                      return null;
                    },
                    controller: productPriceController,
                    decoration: const InputDecoration(
                      labelText: "Price (RM)",
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
                      labelText: 'Location',
                      hintText: 'Hin Bus Depot, George Town',
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
                    height: 70,
                    child: Row(children: [
                      const Text(
                        "Inventory",
                        style: TextStyle(
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(
                        width: 40,
                      ),
                      Expanded(
                        child: TextFormField(
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Inventory cannot be empty!';
                            } else if (value == "0") {
                              return "Inventory cannot be 0";
                            }
                            return null;
                          },
                          controller: inventoryController,
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            labelText: 'Inventory',
                            suffixIcon: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.arrow_upward),
                                  onPressed: _increment,
                                ),
                                IconButton(
                                  icon: Icon(Icons.arrow_downward),
                                  onPressed: _decrement,
                                ),
                              ],
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
                try {
                  if (file == null) {
                    Flushbar(
                      backgroundColor: Colors.black,
                      message: "Please upload the product image",
                      duration: const Duration(seconds: 3),
                    ).show(context);
                    return;
                  }

                  if (_formKey.currentState!.validate()) {
                    DocumentReference newProductID =
                    FirebaseFirestore.instance.collection("Product").doc();

                    productID = newProductID.id;

                    await uploadImage(productID);
                    await upload3DImage(productID);
                    await createNewProduct(productID);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('New Product Added')),
                    );
                    Navigator.pop(context);

                    productNameController.clear();
                    productDescController.clear();
                    productPriceController.clear();
                    productLocationController.clear();
                    inventoryController.clear();
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
                              image3D: product["3D Image"],
                              category: product["Category"],
                              inventory: product["Inventory"],
                              productID: product["ProductID"]),
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
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            products[index].name,
                                            style: TextStyle(
                                              fontSize: 19,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                          Text(
                                            "Inventory: ${(products[index].inventory).toString()}",
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                        ],
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
                                            onPressed: () {
                                              showEditProductDialog(
                                                  products[index]);
                                            },
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
                                            onPressed: () {
                                              showDeleteProductDialog(
                                                  products[index]);
                                            },
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
              SizedBox(
                height: 75,
              )
            ],
          ),
        ),
      ),
    );
  }
}
