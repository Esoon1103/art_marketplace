import 'package:flutter/material.dart';

import '../../model/product_model.dart';
import '../../pages/user/product_view_page.dart';

class RecentlyViewedCard extends StatefulWidget {
  final ProductModel productModel;

  const RecentlyViewedCard({super.key, required this.productModel});

  @override
  State<RecentlyViewedCard> createState() => _RecentlyViewedCardState();
}

class _RecentlyViewedCardState extends State<RecentlyViewedCard> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  ProductViewPage(product: widget.productModel))),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Card(
            elevation: 1,
            shadowColor: Colors.black,
            child: Column(
              children: [
                Stack(
                  children: [
                    SizedBox(
                      height: 150,
                      width: MediaQuery.of(context).size.width,
                      child: Image.network(
                        widget.productModel.image,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.productModel.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {},
                            child: Text(
                              "RM${widget.productModel.price}",
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 15,
                                color: Colors.grey,
                              ),
                              Text(
                                widget.productModel.location,
                                style: const TextStyle(
                                  color: Colors.black38,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Category: ${widget.productModel.category}",
                            style: const TextStyle(
                              color: Colors.black38,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
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
