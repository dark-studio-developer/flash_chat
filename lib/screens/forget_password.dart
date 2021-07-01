import 'package:firebase_auth/firebase_auth.dart';
import 'package:flash_chat/components/rounded_button.dart';
import 'package:flash_chat/constants.dart';
import 'package:flutter/material.dart';

FirebaseAuth _auth = FirebaseAuth.instance;

class ForgetScreen extends StatefulWidget {
  static const id = 'forget_password';

  @override
  _ForgetScreenState createState() => _ForgetScreenState();
}

Future<void> resetPassword(String email, BuildContext context) async {
  SnackBar snackBar;

  try {
    await _auth.sendPasswordResetEmail(email: email);
    snackBar = SnackBar(content: Text('email sent to $email'));
  } catch (e) {
    snackBar = SnackBar(content: Text(e.toString()));
  }

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

class _ForgetScreenState extends State<ForgetScreen> {
  String email;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                child: Hero(
                  tag: 'logo',
                  child: Container(
                    height: 200.0,
                    child: Image.asset('images/logo.png'),
                  ),
                ),
              ),
              SizedBox(
                height: 20.0,
              ),
              TextField(
                onChanged: (value) {
                  email = value;
                },
                keyboardType: TextInputType.emailAddress,
                decoration:
                    kTextFieldDecoration.copyWith(hintText: "Enter your email"),
              ),
              RoundedButton(
                  title: 'Reset',
                  colour: Colors.lightBlueAccent,
                  onPress: () {
                    resetPassword(email, context);
                    print(email);
                  })
            ],
          ),
        ),
      ),
    );
  }
}
