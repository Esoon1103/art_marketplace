import 'package:art_marketplace/model/article_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Articles extends StatefulWidget {
  const Articles({super.key});

  @override
  State<Articles> createState() => _ArticlesState();
}

class _ArticlesState extends State<Articles> {
  final User? user = FirebaseAuth.instance.currentUser;

  Stream _getArticles() {
    if (user != null) {
      Stream<QuerySnapshot<Object?>> snapshot =
      FirebaseFirestore.instance.collection('Article').snapshots();

      return snapshot;
    } else {
      return const Stream.empty();
    }
  }

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              StreamBuilder(
                  stream: _getArticles(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else if (!snapshot.hasData ||
                        snapshot.data!.docs.isEmpty) {
                      return const Text('No products available.');
                    } else {
                      //Initialize article list
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

                      return ListView.builder(
                        scrollDirection: Axis.vertical,
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        itemCount: articles.length,
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
                                  articles[index].image,
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
                                            articles[index].name,
                                            style: TextStyle(
                                              fontSize: 19,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                          Text(
                                            "Date: ${articles[index].date}",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(
                                        height: 10,
                                      ),
                                      Text(
                                        articles[index].location,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      Container(height: 10),
                                      Text(
                                        articles[index].description,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                        ),
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
            ],
          ),
        ),
      ),
    );
  }
}
