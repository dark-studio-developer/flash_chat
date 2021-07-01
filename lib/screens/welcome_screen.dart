import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flash_chat/google_signIn_provider.dart';
import 'package:flash_chat/screens/chat_screen.dart';
import 'package:flash_chat/screens/login_screen.dart';
import 'package:flash_chat/screens/registration_screen.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/components/rounded_button.dart';
import 'package:provider/provider.dart';

class WelcomeScreen extends StatefulWidget {
  static const id = 'welcome_screen';
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

final FirebaseAuth _auth = FirebaseAuth.instance;

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  AnimationController controller;
  Animation animation;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );

    animation = ColorTween(begin: Colors.blueGrey, end: Colors.white)
        .animate(controller);

    controller.forward();

    controller.addListener(() {
      setState(() {});
    });
  }

  // void checkUserLogin() async {
  //   FirebaseAuth.instance.authStateChanges().listen((User user) async {
  //     if (user == null) {
  //       print('User is currently signed out!');
  //     } else {
  //       print('User is signed in! with ' + user.email);
  //       Navigator.pushNamed(context, ChatScreen.id);
  //     }
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: animation.value,
      body: StreamBuilder(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text('Soomething went Wrong'),
              );
            } else if (snapshot.hasData) {
              return ChatScreen();
            } else {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Hero(
                          tag: 'logo',
                          child: Container(
                            child: Image.asset('images/logo.png'),
                            height: 60.0,
                          ),
                        ),
                        AnimatedTextKit(
                          animatedTexts: [
                            TypewriterAnimatedText(
                              'Flash Chat',
                              textStyle: TextStyle(
                                fontSize: 45.0,
                                fontWeight: FontWeight.w900,
                              ),
                              speed: Duration(milliseconds: 250),
                            ),
                          ],
                          repeatForever: true,
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 48.0,
                    ),
                    RoundedButton(
                      title: 'Log In',
                      colour: Colors.lightBlueAccent,
                      onPress: () {
                        Navigator.pushNamed(context, LoginScreen.id);
                      },
                    ),
                    RoundedButton(
                      title: 'Register',
                      colour: Colors.blueAccent,
                      onPress: () {
                        Navigator.pushNamed(context, RegistrationScreen.id);
                      },
                    ),
                    RoundedButton(
                      title: 'Sign in with Google',
                      colour: Colors.green[400],
                      onPress: () async {
                        try {
                          final provider = Provider.of<SignInProvider>(context,
                              listen: false);
                          provider.googleLogin();
                        } catch (e) {
                          print(e);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              );
            }
          }),
    );
  }
}
