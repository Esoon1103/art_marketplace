import 'package:another_flushbar/flushbar.dart';
import 'package:art_marketplace/pages/user/recently_viewed.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../pages/user/order_page.dart';
import '../../pages/user/seller_centre.dart';
import '../../pages/user/user_login.dart';

class DisplayProfileDetails extends StatefulWidget {
  const DisplayProfileDetails({super.key});

  @override
  State<DisplayProfileDetails> createState() => _DisplayProfileDetailsState();
}

class _DisplayProfileDetailsState extends State<DisplayProfileDetails> {
  final User? user = FirebaseAuth.instance.currentUser;
  String? displayName = FirebaseAuth.instance.currentUser?.displayName;
  String? email = FirebaseAuth.instance.currentUser?.email;
  String valueText = "";
  String? address = "";
  bool isLoading = true;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController updateUsernameController =
      TextEditingController();
  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

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
  void initState() {
    if(user != null){
      updateUsernameController.text = displayName!;
    }

    getAddress();
    super.initState();
  }

  @override
  void dispose() {
    updateUsernameController.clear();
    currentPasswordController.clear();
    newPasswordController.clear();
    addressController.clear();
    super.dispose();
  }

  void updateUsername() async {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Edit Username'),
        content: TextFormField(
          controller: updateUsernameController,
          onChanged: (value) {
            setState(() {
              valueText = value;
            });
          },
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, 'Cancel'),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                if (updateUsernameController.text == "") {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Username cannot be empty!")));
                } else {
                  await FirebaseFirestore.instance
                      .collection("Users")
                      .doc(user?.uid.toString())
                      .update({
                    "Username": updateUsernameController.text.toString()
                  });

                  await FirebaseAuth.instance.currentUser!.updateDisplayName(
                      updateUsernameController.text.toString());

                  setState(() {
                    displayName = updateUsernameController.text.toString();
                  });
                  Navigator.pop(context, 'OK');
                }
              } catch (e) {
                print('Error updating username: $e');
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  updatePassword() async {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => Center(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: AlertDialog(
              title: const Text('Change Password'),
              content: Column(
                children: [
                  TextFormField(
                    controller: currentPasswordController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your current password';
                      }
                      return null;
                    },
                    decoration:
                        const InputDecoration(labelText: "Current Password"),
                    obscuringCharacter: '*',
                    obscureText: true,
                  ),
                  TextFormField(
                    controller: newPasswordController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your new password';
                      } else if (value.length < 5) {
                        return 'Password must be more than 5 characters';
                      }
                      return null;
                    },
                    obscuringCharacter: '*',
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: "New Password"),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(context, 'Cancel'),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    try {
                      if (_formKey.currentState!.validate()) {
                        if (FirebaseAuth.instance.currentUser != null) {
                          final DocumentSnapshot<Map<String, dynamic>>
                              currentUserData = await FirebaseFirestore.instance
                                  .collection("Users")
                                  .doc(user?.uid.toString())
                                  .get();

                          String currentEmail =
                              currentUserData.data()!["Email"];
                          // Validate the current password before proceeding
                          var credential = EmailAuthProvider.credential(
                            email: currentEmail.toString(),
                            password: currentPasswordController.text.toString(),
                          );

                          try {
                            await FirebaseAuth.instance.currentUser
                                ?.reauthenticateWithCredential(credential)
                                .then((value) {
                              user?.updatePassword(
                                  newPasswordController.text.toString());
                              print("Ok password");
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("Password Changed!")));
                              Navigator.pop(context, 'OK');
                              currentPasswordController.clear();
                              newPasswordController.clear();
                            });
                          } catch (e) {
                            // Reauthentication failed, handle the error (e.g., incorrect current password).
                            print('Error reauthenticating user: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text("Incorrect Current Password!")));
                          }
                        }
                      }
                    } catch (e) {
                      print('Error changing password: $e');
                    }
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  updateAddress() async {
    await getAddress();

    !isLoading
        ? showDialog<String>(
            context: context,
            builder: (BuildContext context) => Form(
              key: _formKey,
              child: AlertDialog(
                title: const Text('Address'),
                content: TextFormField(
                  controller: addressController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your address';
                    } else if (value.length < 15) {
                      return 'Make sure you type full address';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(labelText: "Edit Address"),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.pop(context, 'Cancel'),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        try {
                          if (addressController.text == "") {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Address cannot be empty!")));
                          } else {
                            await FirebaseFirestore.instance
                                .collection("Users")
                                .doc(user?.uid.toString())
                                .set({
                              "Address": addressController.text.toString()
                            }, SetOptions(merge: true)).then((addressValue) {
                              setState(() {
                                address = addressController.text.toString();
                                isLoading = false;
                              });
                            });

                            Navigator.pop(context, 'OK');
                          }
                        } catch (e) {
                          print('Error updating address: $e');
                        }
                      }
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            ),
          )
        : const SizedBox();
  }

  getAddress() async {
    setState(() {
      isLoading = true;
    });

    final DocumentSnapshot<Map<String, dynamic>> getAddress =
        await FirebaseFirestore.instance
            .collection("Users")
            .doc(user?.uid.toString())
            .get();

    setState(() {
      address = getAddress.data()?["Address"] ?? "";
      addressController.text = address!;
      isLoading = false;
    });
  }

  sendMail() async {
    String? uid = user?.uid.toString();

    String? encodeQueryParameters(Map<String, String> params) {
      return params.entries
          .map((MapEntry<String, String> e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
    }

    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'ngesoon123@gmail.com',
      query: encodeQueryParameters(<String, String>{
        'subject': "Contact Enquiry from Artsylane",
        'body': "Dear artsylane administrator,  This is the message from "
            "username: $displayName and UID: $uid. I am writing here to ",
      }),
    );

    if (await canLaunchUrl(emailUri)) {
      launchUrl(emailUri);
    } else {
      throw Exception("Could not launch $emailUri");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SettingsList(
        sections: [
          SettingsSection(
            title: const Text('Account'),
            tiles: <SettingsTile>[
              SettingsTile.navigation(
                leading: const Icon(Icons.account_circle_rounded),
                title: const Text("Username"),
                value: Text(displayName!),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {
                    setState(() {
                      updateUsername();
                    });
                  },
                ),
              ),
              SettingsTile.navigation(
                leading: const Icon(Icons.mail),
                title: const Text('Email'),
                value: Text(email!),
              ),
              SettingsTile.navigation(
                leading: const Icon(Icons.house_outlined),
                title: const Text('Address'),
                value: isLoading
                    ? const Text("")
                    : Text(address == "" ? "No Address Provided" : address!),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {
                    setState(() {
                      updateAddress();
                    });
                  },
                ),
              ),
            ],
          ),
          SettingsSection(
            title: const Text('Security'),
            tiles: <SettingsTile>[
              SettingsTile.navigation(
                leading: const Icon(Icons.password_outlined),
                title: const Text('Change Password'),
                onPressed: (context) {
                  setState(() {
                    updatePassword();
                  });
                },
              ),
            ],
          ),
          SettingsSection(
            title: const Text('Gateway'),
            tiles: <SettingsTile>[
              SettingsTile.navigation(
                leading: const Icon(Icons.change_circle),
                title: const Text('Seller Centre'),
                onPressed: (context) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SellerCentre()));
                },
              ),
              SettingsTile.navigation(
                leading: const Icon(Icons.shopping_bag_outlined),
                title: const Text('My Orders'),
                onPressed: (context) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const OrderPage()));
                },
              ),
              SettingsTile.navigation(
                leading: const Icon(Icons.remove_red_eye_rounded),
                title: const Text('Recently Viewed'),
                onPressed: (context) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const RecentlyViewed()));
                },
              ),
              SettingsTile(
                leading: const Icon(Icons.help),
                title: const Text('Contact Us'),
                onPressed: (context) {
                  sendMail();
                },
              ),
              SettingsTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sign Out'),
                onPressed: (context) => signOut(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
