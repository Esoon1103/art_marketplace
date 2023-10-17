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
  String? imageFile;
  String? imageFile3D;
  String urlDownload = "";
  String url3dDownload = "";
  PlatformFile? file3D, file;
  UploadTask? task;
  final TextEditingController productNameController = TextEditingController();
  final TextEditingController productDescController = TextEditingController();
  final TextEditingController productPriceController = TextEditingController();
  final TextEditingController productLocationController = TextEditingController();

  @override
  dispose() {
    super.dispose();
    productNameController.clear();
    productDescController.clear();
    productPriceController.clear();
    productLocationController.clear();
  }

  void selectImage() async {
    FilePickerResult? result =
    await FilePicker.platform.pickFiles(
        allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg'],
    );

    if (result != null) {
      setState(() {
        file = result.files.single;
      });
    }else{
      return;
    }
  }

  void select3DImage() async {
    FilePickerResult? result =
    await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['glb', 'gltf', 'stl', 'obj'],
    );

    if (result != null) {
      setState(() {
        file3D = result.files.single;
      });
    }else{
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

    //await createNewProduct();
  }

  Future upload3DImage() async {
    final path = 'sellerProduct3DModel/${file3D!.name}';
    final File fileObject = File(file3D!.path!);

    final ref = FirebaseStorage.instance.ref().child(path);
    task = ref.putFile(fileObject);

    // Wait for the upload to complete
    final snapshot = await task!.whenComplete(() {
      print('Upload complete');
    });

    url3dDownload = await snapshot.ref.getDownloadURL();
    //await createNewProduct();
  }

  createNewProduct() async {
    await FirebaseFirestore.instance.collection("Product").doc(user?.uid.toString()).set({
      "UID" : user?.uid.toString(),
      "Image" : urlDownload,
      "3D Image": url3dDownload,
      "name": productNameController.text.toString(),
      "desc" : productDescController.text.toString(),
      "price" : productPriceController.text.toString(),
      "location" : productLocationController.text.toString(),
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
                  Container(
                    width: MediaQuery.of(context).size.width,
                    height: 50,
                    child: Row(
                        children: [
                          const Text("Category",
                            style: TextStyle(
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(width: 40,),
                          Expanded(
                            child: Container(
                              child: DropdownButtonFormField<String>(
                                value: productCategory,
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      productCategory = newValue!;
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
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(value),
                                        SizedBox(width: 8),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ]
                    ),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    child: Row(
                        children: [
                          const Text("Image      ",
                            style: TextStyle(
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(width: 30,),
                          Expanded(
                            child: TextButton.icon(
                              onPressed: () async {
                                selectImage();
                              },
                              icon: Icon(Icons.upload_outlined), // Replace with your preferred upload icon
                              label: Text('Select'),
                              style: TextButton.styleFrom(
                                primary: Colors.blue, // Text color
                                backgroundColor: Colors.grey[200], // Background color
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ]
                    ),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    child: Row(
                        children: [
                          const Text("3D Image \n(Optional)",
                            style: TextStyle(
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(width: 30,),
                          Expanded(
                            child: TextButton.icon(
                              onPressed: () {
                                select3DImage();
                              },
                              icon: Icon(Icons.upload_outlined), // Replace with your preferred upload icon
                              label: Text('Select'),
                              style: TextButton.styleFrom(
                                primary: Colors.blue, // Text color
                                backgroundColor: Colors.grey[200], // Background color
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ]
                    ),
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
                  if (_formKey.currentState!.validate()) {
                    await uploadImage();
                    //await upload3DImage();
                    await createNewProduct();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Form Submitted')),
                    );
                    Navigator.pop(context);
                  }
                  // if (updateUsernameController.text == "") {
                  //   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  //       content: Text("Username cannot be empty!")));
                  // } else {
                  //   await FirebaseFirestore.instance
                  //       .collection("Users")
                  //       .doc(user?.uid.toString())
                  //       .update({
                  //     "Username": updateUsernameController.text.toString()
                  //   });
                  //
                  //   await FirebaseAuth.instance.currentUser!.updateDisplayName(
                  //       updateUsernameController.text.toString());
                  //
                  //   setState(() {
                  //     displayName = updateUsernameController.text.toString();
                  //   });
                  //   Navigator.pop(context, 'ADD');
                  // }
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
          padding: EdgeInsets.all(8.0),
          child: Column(
            children: [
              Card(
                // Set the shape of the card using a rounded rectangle border with a 8 pixel radius
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                // Set the clip behavior of the card
                clipBehavior: Clip.antiAliasWithSaveLayer,
                // Define the child widgets of the card
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Display an image at the top of the card that fills the width of the card and has a height of 160 pixels
                    Image.asset(
                      'assets/images/artsylane_logo_full.png',
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    // Add a container with padding that contains the card's title, text, and buttons
                    Container(
                      padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // Display the card's title using a font size of 24 and a dark grey color
                          Text(
                            "Vase 1998",
                            style: TextStyle(
                              fontSize: 19,
                              color: Colors.grey[800],
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Text(
                            "Locate: Hin Bus Depot, George Town",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                          // Add a space between the title and the text
                          Container(height: 10),
                          // Display the card's text using a font size of 15 and a light grey color
                          Text(
                            "Founded in 1998, was an item stored in our family. Historical item which never been used or sold ever.",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                          // Add a row with two buttons spaced apart and aligned to the right side of the card
                          Row(
                            children: <Widget>[
                              const Text(
                                "RM 199",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              // Add a spacer to push the buttons to the right side of the card
                              const Spacer(),
                              // Add a text button labeled "SHARE" with transparent foreground color and an accent color for the text
                              TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.transparent,
                                ),
                                child: const Text(
                                  "EDIT",
                                  style: TextStyle(color: Colors.blue),
                                ),
                                onPressed: () {},
                              ),
                              // Add a text button labeled "EXPLORE" with transparent foreground color and an accent color for the text
                              TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.transparent,
                                ),
                                child: const Text(
                                  "DELETE",
                                  style: TextStyle(color: Colors.red),
                                ),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Add a small space between the card and the next widget
                    Container(height: 5),
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
