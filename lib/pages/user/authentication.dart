import 'package:art_marketplace/pages/user/home_page.dart';
import 'package:art_marketplace/pages/user/user_login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure that Flutter is initialized
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
        builder: (context, snapshot){
          if (snapshot.connectionState == ConnectionState.active) {
            final User? user = snapshot.data;

            if (user == null) {
              // User is not logged in, navigate to login page
              return const UserLogin();
            } else {
              // User is logged in, navigate to home page
              return const HomePage();
            }
          }

          return const Center(child: CircularProgressIndicator());
          //
          // if(snapshot.hasData){
          //   return const HomePage();
          // }
          // else if(snapshot.hasError){
          //   return const Center(child: Text('Something Went Wrong :('),);
          // }
          // else if(snapshot.connectionState == ConnectionState.waiting){
          //   return const Center(child: CircularProgressIndicator(),);
          // }
          // else{
          //   return const UserLogin();
          // }
        },
      ),
    );
  }
}