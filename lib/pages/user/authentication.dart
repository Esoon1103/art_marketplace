import 'package:art_marketplace/pages/user/user_login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:art_marketplace/widgets/user/bottom_navigation_bar.dart'
    as user_bottom_navigation_bar;

Future<void> main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Ensure that Flutter is initialized
  await Firebase.initializeApp();

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
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return const user_bottom_navigation_bar.BottomNavigationBar(
                pageNum: 0);
          } else if (snapshot.data == null) {
            // User is not logged in, navigate to login page
            return const UserLogin();
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
