import 'package:another_flushbar/flushbar.dart';
import 'package:art_marketplace/model/article_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'admin_home.dart';
import 'admin_login.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class AdminArticles extends StatefulWidget {
  const AdminArticles({super.key});

  @override
  State<AdminArticles> createState() => _AdminArticlesState();
}

class _AdminArticlesState extends State<AdminArticles> {
  final User? user = FirebaseAuth.instance.currentUser;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String currentDate = DateFormat("yyyy-MM-dd").format(DateTime.now());
  String articleID = "";
  String articleName = "";
  String articleDesc = "";
  String articleLocation = "";
  String articleDate = "";
  String imageFile = "";
  String urlDownload = "";
  PlatformFile? file;
  UploadTask? task;
  bool upload = false;
  final TextEditingController articleNameController = TextEditingController();
  final TextEditingController articleDescController = TextEditingController();
  final TextEditingController articleLocationController =
      TextEditingController();

  @override
  dispose() {
    articleNameController.dispose();
    articleDescController.dispose();
    articleLocationController.dispose();
    super.dispose();
  }

  void signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminLogin(),
      ),
    );
  }

  Stream _getArticles() {
    if (user != null) {
      Stream<QuerySnapshot<Object?>> snapshot =
          FirebaseFirestore.instance.collection('Article').snapshots();

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

  Future uploadImage(articleID) async {
    if (file == null) {
      print('Error: File is null.');
      return;
    }

    if (kIsWeb) {
      // For web, use bytes instead of path
      final bytes = file!.bytes!;
      final path = 'articleImage/$articleID/${file!.name}';
      final ref = FirebaseStorage.instance.ref().child(path);
      task = ref.putData(bytes);
    } else {
      final path = 'articleImage/$articleID/${file!.name}';
      final File fileObject = File(file!.path!);
      final ref = FirebaseStorage.instance.ref().child(path);
      task = ref.putFile(fileObject);
    }

    final snapshot = await task!.whenComplete(() {
      print('Upload complete');
    });

    urlDownload = await snapshot.ref.getDownloadURL();

    if (!kIsWeb) {
      File(file!.path!).delete();
    }

    setState(() {
      file = null;
      imageFile = "";
    });
  }

  createNewArticle(articleID) async {
    await FirebaseFirestore.instance.collection("Article").doc(articleID).set({
      "Image": urlDownload,
      "Name": articleNameController.text.toString(),
      "Desc": articleDescController.text.toString(),
      "Location": articleLocationController.text.toString(),
      "Date": currentDate.toString(),
      "ArticleID": articleID,
    });
  }

  showDeleteArticleDialog(ArticleModel article) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Warning'),
          contentPadding: const EdgeInsets.all(16.0),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.3,
            child: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(
                      'Are you sure to delete this article? \nArticle Name: ${article.name}'),
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
              child: const Text('DELETE'),
              onPressed: () async {
                await deleteArticle(article.articleID);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  deleteArticle(String articleID) async {
    await FirebaseFirestore.instance
        .collection("Article")
        .doc(articleID)
        .delete();
  }

  updateArticle(ArticleModel article) async {
    await FirebaseFirestore.instance
        .collection("Article")
        .doc(article.articleID)
        .update({
      "Image": urlDownload,
      "Name": articleNameController.text.toString(),
      "Desc": articleDescController.text.toString(),
      "Date": currentDate.toString(),
      "Location": articleLocationController.text.toString(),
      "ArticleID": article.articleID,
    });
  }

  showEditArticleDialog(ArticleModel article) {
    String articleIDNew = article.articleID;
    articleNameController.text = article.name;
    articleDescController.text = article.description;
    articleLocationController.text = article.location;
    urlDownload = article.image;

    print("Product Image: $urlDownload");

    showDialog<String>(
      context: context,
      builder: (BuildContext context) => Form(
        key: _formKey,
        child: AlertDialog(
          title: const Text('Edit Article'),
          contentPadding: const EdgeInsets.all(16.0),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.3,
            child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    TextFormField(
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Article name cannot be empty!';
                        }
                        return null;
                      },
                      controller: articleNameController,
                      decoration: const InputDecoration(
                        labelText: "Name",
                        hintStyle: TextStyle(
                          color: Color(0xFF8391A1),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          articleName = value;
                        });
                      },
                    ),
                    TextFormField(
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Article description cannot be empty!';
                        }
                        return null;
                      },
                      controller: articleDescController,
                      decoration: const InputDecoration(
                        labelText: "Description",
                        hintStyle: TextStyle(
                          color: Color(0xFF8391A1),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          articleDesc = value;
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
                      controller: articleLocationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        hintText: 'Hin Bus Depot, George Town',
                        hintStyle: TextStyle(
                          color: Color(0xFF8391A1),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          articleLocation = value;
                        });
                      },
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

                              if (upload == true) {
                                setState(() {
                                  // Update the state that should trigger a rebuild
                                  // For example, update image3DFile
                                  article.image = file?.name ?? '';
                                });
                              } else {
                                upload == false;
                              }
                            },
                            icon: const Icon(Icons.upload_outlined),
                            label: upload
                                ? Text(article.image)
                                : (urlDownload == null
                                    ? const Text('Select')
                                    : Text(urlDownload)),
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
                    const SizedBox(
                      height: 30,
                    ),
                  ],
                ),
              );
            }),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context, 'Cancel');
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  if (urlDownload == "") {
                    Flushbar(
                      backgroundColor: Colors.black,
                      message: "Please upload the article image",
                      duration: const Duration(seconds: 3),
                    ).show(context);
                    return;
                  }

                  if (_formKey.currentState!.validate()) {
                    if (upload == true) {
                      await uploadImage(articleIDNew);
                    }

                    await updateArticle(article);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Article Updated')),
                    );
                    Navigator.pop(context);
                  }
                } catch (e) {
                  print('Error update the article: $e');
                }
              },
              child: const Text('UPDATE'),
            ),
          ],
        ),
      ),
    );
  }

  addArticleDialog() async {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => Form(
        key: _formKey,
        child: AlertDialog(
          title: const Text('Add Article'),
          contentPadding: const EdgeInsets.all(16.0),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.3,
            child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    TextFormField(
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Article name cannot be empty!';
                        }
                        return null;
                      },
                      controller: articleNameController,
                      decoration: const InputDecoration(
                        labelText: "Name",
                        hintStyle: TextStyle(
                          color: Color(0xFF8391A1),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          articleName = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10,),
                    TextFormField(
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Article description cannot be empty!';
                        }
                        return null;
                      },
                      controller: articleDescController,
                      decoration: const InputDecoration(
                        labelText: "Description",
                        hintStyle: TextStyle(
                          color: Color(0xFF8391A1),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          articleDesc = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10,),
                    TextFormField(
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Location cannot be empty!';
                        }
                        return null;
                      },
                      controller: articleLocationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        hintText: 'Hin Bus Depot, George Town',
                        hintStyle: TextStyle(
                          color: Color(0xFF8391A1),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          articleLocation = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10,),
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
                              if (upload == true) {
                                setState(() {
                                  imageFile;
                                });
                              } else {
                                upload == false;
                              }

                            },
                            icon: const Icon(Icons.upload_outlined),
                            label: imageFile == null
                                ? const Text('Select')
                                : Text(imageFile),
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
          ),
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
                      message: "Please upload the article image",
                      duration: const Duration(seconds: 3),
                    ).show(context);
                    return;
                  }

                  if (_formKey.currentState!.validate()) {
                    DocumentReference newProductID =
                        FirebaseFirestore.instance.collection("Article").doc();

                    articleID = newProductID.id;

                    await uploadImage(articleID);
                    await createNewArticle(articleID);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('New Article Added')),
                    );
                    Navigator.pop(context);

                    articleNameController.clear();
                    articleDescController.clear();
                    articleLocationController.clear();
                  }
                } catch (e) {
                  print('Error add new article: $e');
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
          addArticleDialog();
        },
        child: const Icon(Icons.add),
      ),
      appBar: AppBar(
        title: InkWell(
            onTap: () => Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const AdminHome())),
            child: const Text('Artsylane Admin')),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => signOut(),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = kIsWeb ? constraints.maxWidth ~/ 300 : 2;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: StreamBuilder(
                stream: _getArticles(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text('No article available.');
                  } else {
                    List<ArticleModel> articles = [
                      for (var article in snapshot.data!.docs)
                        ArticleModel(
                          name: article["Name"],
                          description: article["Desc"],
                          location: article["Location"],
                          date: article["Date"],
                          image: article["Image"],
                          articleID: article["ArticleID"],
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
                      itemCount: articles.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          clipBehavior: Clip.antiAliasWithSaveLayer,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Image.network(
                                articles[index].image,
                                width: double.infinity,
                                height: kIsWeb ? 150 : 120,
                                fit: BoxFit.cover,
                              ),
                              Container(
                                padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      articles[index].name,
                                      style: TextStyle(
                                        fontSize: kIsWeb ? 16 : 14,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      articles[index].location,
                                      style: TextStyle(
                                        fontSize: kIsWeb ? 12 : 10,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    Container(height: 5),
                                    Row(
                                      children: <Widget>[
                                        Text(
                                          articles[index].date,
                                        ),
                                        const Spacer(),
                                        TextButton(
                                          style: TextButton.styleFrom(
                                            primary: Colors.blue,
                                          ),
                                          child: const Text("EDIT"),
                                          onPressed: () {
                                            showEditArticleDialog(articles[index]);
                                          },
                                        ),
                                        TextButton(
                                          style: TextButton.styleFrom(
                                            primary: Colors.red,
                                          ),
                                          child: const Text("DELETE"),
                                          onPressed: () {
                                            showDeleteArticleDialog(articles[index]);
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
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
