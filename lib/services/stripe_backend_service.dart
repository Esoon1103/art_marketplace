import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class CreateAccountResponse {
  late String url;
  late bool success;
  late String accountId;

  CreateAccountResponse(String url, bool success, String accountId) {
    this.url = url;
    this.success = success;
    this.accountId = accountId;
  }
}

class StripeBackendService {
  final User? user = FirebaseAuth.instance.currentUser;
  static Map<String, String> headers = {'Content-Type': 'application/json'};
  static const String BACKEND_HOST = 'http://localhost:3000';
  static String apiBase = '$BACKEND_HOST/api/stripe';

  static String createAccountUrl =
      '${StripeBackendService.apiBase}/account?mobile=true';

  static Future<CreateAccountResponse> createSellerAccount() async {
    var url = Uri.parse(StripeBackendService.createAccountUrl);
    var response = await http.get(url, headers: StripeBackendService.headers);
    Map<String, dynamic> body = jsonDecode(response.body);
    print(response.body);
    String? accountId = body['accountId'] as String?;

    if (accountId == null) {
      // Handle the case where 'id' is null
      return CreateAccountResponse(body['url'], false, '');
    }

    return CreateAccountResponse(body['url'], true, accountId!);
  }
}

