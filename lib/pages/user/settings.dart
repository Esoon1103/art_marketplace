import 'package:flutter/material.dart';
import 'package:art_marketplace/widgets/user/display_profile_details.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: const Column(
            children: [
              SizedBox(
                height: 25,
              ),
              DisplayProfileDetails(),
              SizedBox(
                height: 65,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
