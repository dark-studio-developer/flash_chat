import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignInProvider extends ChangeNotifier {
  final googleSignIn = GoogleSignIn();

  UserCredential _userWithEmail;
  UserCredential get thisuser => _userWithEmail;

  GoogleSignInAccount _user;

  GoogleSignInAccount get user => _user;

  Future googleLogin() async {
    final googleUser = await googleSignIn.signIn();

    if (googleUser == null) return;
    _user = googleUser;

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await FirebaseAuth.instance.signInWithCredential(credential);

    notifyListeners();
  }

  Future loginWithEmailAndPass(email, password) async {
    try {
      final loginUser = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // if (loginUser == null) return;
      // _userWithEmail = loginUser;

      notifyListeners();
    } catch (e) {
      print(e + " message");
    }
  }

  Future logout() async {
    try {
      await googleSignIn.disconnect();
    } catch (e) {
      print(e);
    }
    FirebaseAuth.instance.signOut();
  }
}
