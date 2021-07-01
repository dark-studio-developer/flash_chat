import 'package:firebase_core/firebase_core.dart';
import 'package:flash_chat/google_signIn_provider.dart';
import 'package:flash_chat/screens/forget_password.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/screens/welcome_screen.dart';
import 'package:flash_chat/screens/login_screen.dart';
import 'package:flash_chat/screens/registration_screen.dart';
import 'package:flash_chat/screens/chat_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('app_icon');

  final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid, iOS: null, macOS: null);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onSelectNotification: selectNotification);

  await Firebase.initializeApp();
  runApp(FlashChat());
}

Future selectNotification(String payload) async {
  //Handle notification tapped logic here
  if (payload != null) {
    debugPrint('notification payload $payload');
  }
}

class FlashChat extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SignInProvider(),
      child: MaterialApp(
        initialRoute: WelcomeScreen.id,
        debugShowCheckedModeBanner: false,
        routes: {
          WelcomeScreen.id: (context) => WelcomeScreen(),
          LoginScreen.id: (context) => LoginScreen(),
          RegistrationScreen.id: (context) => RegistrationScreen(),
          ChatScreen.id: (context) => ChatScreen(),
          ForgetScreen.id: (context) => ForgetScreen(),
        },
      ),
    );
  }
}
// return
