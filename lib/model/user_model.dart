class UserModel{
  String email;
  String phone;
  String uid;
  String username;
  String seller;
  bool isAdmin;

  UserModel({
    required this.email,
    required this.phone,
    required this.uid,
    required this.username,
    required this.seller,
    required this.isAdmin,
  });
}