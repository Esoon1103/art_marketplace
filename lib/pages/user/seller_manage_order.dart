import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';

import '../../widgets/user/get_seller_order_list.dart';

class SellerManageOrder extends StatefulWidget {
  const SellerManageOrder({super.key});

  @override
  State<SellerManageOrder> createState() => _SellerManageOrderState();
}

class _SellerManageOrderState extends State<SellerManageOrder> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: NestedScrollView(
            headerSliverBuilder: (context, value) {
              return [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 60, bottom: 20),
                    child: Column(
                      children: [
                        FadeInDown(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  icon: const Icon(Icons.arrow_back)),
                              Text(
                                "Manage Orders  📦",
                                style: TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade800,
                                    height: 1.5),
                              ),
                              const SizedBox(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ];
            },
            body: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  FadeInDown(
                    delay: const Duration(milliseconds: 200),
                    child: TabBar(
                        labelColor: Colors.black,
                        unselectedLabelColor: Colors.grey.shade600,
                        indicatorColor: Colors.black,
                        tabs: const [
                          Tab(
                            text: "Ready to Pack",
                          ),
                          Tab(
                            text: "Delivering",
                          ),
                          Tab(
                            text: "Delivered",
                          )
                        ]),
                  ),
                   const Expanded(
                    child: TabBarView(
                      children: [
                        GetSellerOrderList(orderStatus: "Ready to Pack"),
                        GetSellerOrderList(orderStatus: "Delivering"),
                        GetSellerOrderList(orderStatus: "Delivered"),
                      ],
                    ),
                  )
                ],
              ),
            )));
  }
}
