import 'package:art_marketplace/pages/admin/admin_home.dart';
import 'package:art_marketplace/pages/admin/admin_login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Ensure that Flutter is initialized

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MaterialApp(
    home: AuthPage(),
    debugShowCheckedModeBanner: false,
  ));
}

class AuthPage extends StatefulWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  @override
  initState(){

    super.initState();
  }

  checkAdminStatus() async {
    final User? user = FirebaseAuth.instance.currentUser;
    DocumentSnapshot<Map<String, dynamic>> userSnapshot =
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(user?.uid.toString())
            .get();

    if (userSnapshot.exists) {
      bool isAdmin = userSnapshot['isAdmin'] ?? false;

      if (isAdmin) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) {
          return const AdminHome();
        }));
      }else{
        showNotAdminPrompt();
      }
    }
  }

  void showNotAdminPrompt() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Access Denied: You are not an admin.'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            checkAdminStatus();
            return const AdminLogin();
          } else if (snapshot.data == null) {
            return const AdminLogin();
          } else if (snapshot.hasError) {
            return const Center(
              child: Text('Something Went Wrong :('),
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}
