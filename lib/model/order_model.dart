class OrderModel{
  final String quantity;
  final String productID;
  final String date;
  final String uid;
  String status;
  final String orderId;

  OrderModel({
    required this.quantity,
    required this.productID,
    required this.date,
    required this.uid,
    required this.status,
    required this.orderId,
  });
}