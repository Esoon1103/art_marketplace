import 'package:art_marketplace/model/article_model.dart';
import 'package:flutter/material.dart';

class ArticlesCard extends StatefulWidget {
  final ArticleModel articleModel;

  const ArticlesCard({super.key, required this.articleModel});

  @override
  State<ArticlesCard> createState() => _ArticlesCardState();
}

class _ArticlesCardState extends State<ArticlesCard> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Image.network(
              widget.articleModel.image,
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
                        widget.articleModel.name,
                        style: TextStyle(
                          fontSize: 19,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        "Date: ${widget.articleModel.date}",
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
                    widget.articleModel.location,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                  Container(height: 10),
                  Text(
                    widget.articleModel.description,
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
      ),
    );
  }
}
