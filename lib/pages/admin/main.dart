import 'package:another_flushbar/flushbar.dart';
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
        // The user is an admin
        return const AdminHome();
      } else {
        Flushbar(
          icon: Icon(
            Icons.info_outline,
            size: 28.0,
            color: Colors.blue[300],
          ),
          animationDuration: const Duration(seconds: 1),
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.all(6.0),
          flushbarStyle: FlushbarStyle.FLOATING,
          borderRadius: BorderRadius.circular(12),
          leftBarIndicatorColor: Colors.blue[300],
          message: "You have no permission to enter!",
        ).show(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            checkAdminStatus();
            return SizedBox.shrink();
          } else if (snapshot.data == null) {
            // Admin is not logged in, navigate to login page
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
