import 'package:another_flushbar/flushbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:io';
import 'package:art_marketplace/widgets/user/bottom_navigation_bar.dart'
as user_bottom_navigation_bar;

class SellerForm extends StatefulWidget {
  const SellerForm({super.key});

  @override
  State<SellerForm> createState() => _SellerFormState();
}

class _SellerFormState extends State<SellerForm> {
  final User? user = FirebaseAuth.instance.currentUser;
  final _formKey = GlobalKey<FormState>();
  UploadTask? task;
  List<PlatformFile> _files = [];
  List<String> urlDownloads = [];
  TextEditingController businessOverviewController = TextEditingController();

  @override
  void dispose(){
    businessOverviewController.dispose();
    super.dispose();
  }

  submitApplicationForm(List<String> urls) async {
    await FirebaseFirestore.instance.collection("SellerApplicationForm").doc(user?.uid.toString()).set({
      "UID" : user?.uid.toString(),
      "fileURL" : urls,
      "BusinessDesc" : businessOverviewController.text.toString(),
      "Approval" : "Waiting for Review"
    });

    businessOverviewController.clear();
  }

  void selectFiles() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(allowMultiple: true);

    if (result != null) {
      setState(() {
        _files = result.files;
      });
    }
  }

  Future uploadFilesAndForm() async {
    for (PlatformFile file in _files) {
      final path = 'sellerDocumentFormFiles/${file.name}';
      final File fileObject = File(file.path!);

      final ref = FirebaseStorage.instance.ref().child(path);
      task = ref.putFile(fileObject);

      // Wait for the upload to complete
      final snapshot = await task!.whenComplete(() {
        print('Upload complete');
      });

      final urlDownload = await snapshot.ref.getDownloadURL();
      urlDownloads.add(urlDownload);

      await submitApplicationForm(urlDownloads);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Seller Application Form"),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: TextFormField(
                    controller: businessOverviewController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please describe your business overview';
                      } else if (value.length < 20) {
                        return 'Please describe your business more than 20 words';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      border: UnderlineInputBorder(),
                      labelText: 'Business Overview',
                    ),
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
                Text(
                  'Documents Verification',
                  style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(
                  height: 10,
                ),
                Text(
                  'You must submit documents to verify your business',
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
                ),
                const SizedBox(
                  height: 10,
                ),
                GestureDetector(
                  onTap: () {
                    selectFiles();
                  },
                  child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40.0, vertical: 20.0),
                      child: DottedBorder(
                        borderType: BorderType.RRect,
                        radius: const Radius.circular(10),
                        dashPattern: const [10, 4],
                        strokeCap: StrokeCap.round,
                        color: Colors.blue.shade400,
                        child: Container(
                          width: double.infinity,
                          height: 150,
                          decoration: BoxDecoration(
                              color: Colors.blue.shade50.withOpacity(.3),
                              borderRadius: BorderRadius.circular(10)),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Iconsax.folder_open,
                                color: Colors.blue,
                                size: 40,
                              ),
                              const SizedBox(
                                height: 15,
                              ),
                              Text(
                                'Select your files',
                                style: TextStyle(
                                    fontSize: 15, color: Colors.grey.shade400),
                              ),
                            ],
                          ),
                        ),
                      )),
                ),
                const Text('Selected Files:'),
                Column(
                  children: _files.isEmpty
                      ? [Text("No Files are Selected")]
                      : _files.map((file) => Text(file.name)).toList(),
                ),
                const SizedBox(
                  height: 30,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50), // NEW
                    ),
                    onPressed: () async {
                      if (_files.isEmpty) {
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
                          message: "Please select your documents",
                        ).show(context);
                        return;
                      }

                      if (_formKey.currentState!.validate()) {
                        await uploadFilesAndForm();
                        Navigator.pop(context);

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
                          message: "Form Submitted",
                        ).show(context);

                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const user_bottom_navigation_bar.BottomNavigationBar(
                            pageNum: 3)));
                      }
                    },
                    child: const Text('Submit'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      //Build a Form
      // Location of your business
      // Product Description
      // Upload Multiple Document for verification
    );
  }
}
