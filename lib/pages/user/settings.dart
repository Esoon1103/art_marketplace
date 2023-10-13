import 'package:art_marketplace/pages/user/seller_centre.dart';
import 'package:art_marketplace/pages/user/user_login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final User? user = FirebaseAuth.instance.currentUser;
  String? displayName = FirebaseAuth.instance.currentUser?.displayName;
  String? email = FirebaseAuth.instance.currentUser?.email;

  void signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const UserLogin(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Column(
            children: [
              const SizedBox(height: 25,),
              Expanded(
                child: SettingsList(
                  sections: [
                    SettingsSection(
                      title: const Text('Account'),
                      tiles: <SettingsTile>[
                        SettingsTile.navigation(
                          leading: const Icon(Icons.account_circle_rounded),
                          title: Text("Username"),
                          value: Text(displayName!),
                        ),
                        SettingsTile.navigation(
                          leading: const Icon(Icons.mail),
                          title: const Text('Email'),
                          value: Text(email!),
                        ),
                      ],
                    ),
                    SettingsSection(
                      title: const Text('Gateway'),
                      tiles: <SettingsTile>[
                        SettingsTile.navigation(
                          leading: const Icon(Icons.change_circle),
                          title: const Text('Seller Centre'),
                          onPressed: (context){
                            Navigator.push(context,
                            MaterialPageRoute(builder: (context) => const SellerCentre()));
                          },
                        ),
                      ],
                    ),
                    SettingsSection(
                      tiles: <SettingsTile>[
                        SettingsTile(
                          leading: const Icon(Icons.logout),
                          title: const Text('Sign Out'),
                          onPressed: (context) => signOut(),
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
    );
  }
}
