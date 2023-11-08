import 'package:art_marketplace/model/article_model.dart';
import 'package:art_marketplace/widgets/user/articles_card.dart';
import 'package:art_marketplace/widgets/user/loading_indicator_design.dart';
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
              const SizedBox(height: 55,),
              StreamBuilder(
                  stream: _getArticles(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const LoadingIndicatorDesign();
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
                          return ArticlesCard(articleModel: articles[index]);
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
