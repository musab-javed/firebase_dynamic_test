import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Api {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Stream<User?> get onAuthStateChanged {
    return _firebaseAuth.authStateChanges().map((User? firebaseUser) {
      final user = firebaseUser;
      return user;
    });
  }

  Future<bool> sendEmailLink({
    required String email,
  }) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    debugPrint('sendEmailLink[$email]');
    try {
      final actionCodeSettings = ActionCodeSettings(
        url: 'https://exampledunit.firebaseapp.com',
        handleCodeInApp: true,
        androidPackageName: 'com.example.firebase_link_test',
      );
      debugPrint('actionCodeSettings[${actionCodeSettings.asMap()}]');
      await _firebaseAuth.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: actionCodeSettings,
      );
      FirebaseDynamicLinks.instance.onLink.listen((dynamicLinkData) {
        debugPrint('onLink[${dynamicLinkData.link}]');
      }).onError((error) {
        debugPrint('onLink.onError[$error]');
      });
      preferences.setString('passwordLessEmail', email);
      debugPrint('Link sent successfully');
      return true;
    } catch (e) {
      debugPrint('$e');
      return false;
    }
  }

  Future<User?> retrieveDynamicLinkAndSignIn({
    required bool fromColdState,
  }) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();

    try {
      String email = preferences.getString('passwordLessEmail') ?? '';
      debugPrint('retrieveDynamicLinkAndSignIn[$email]');
      if (email.isEmpty) {
        debugPrint('retrieveDynamicLinkAndSignIn email is empty');
      }

      PendingDynamicLinkData? dynamicLinkData;

      Uri? deepLink;
      if (fromColdState) {
        dynamicLinkData = await FirebaseDynamicLinks.instance.getInitialLink();
        if (dynamicLinkData != null) {
          deepLink = dynamicLinkData.link;
        }
      } else {
        dynamicLinkData = await FirebaseDynamicLinks.instance.onLink.first;
        deepLink = dynamicLinkData.link;
      }

      debugPrint('deepLink => $deepLink');
      if (deepLink != null) {
        bool validLink =
            _firebaseAuth.isSignInWithEmailLink(deepLink.toString());

        preferences.setString('passwordLessEmail', '');
        if (validLink) {
          final UserCredential userCredential =
              await _firebaseAuth.signInWithEmailLink(
            email: email,
            emailLink: deepLink.toString(),
          );
          if (userCredential.user != null) {
            return userCredential.user!;
          } else {
            debugPrint('userCredential.user is [${userCredential.user}]');
          }
        } else {
          debugPrint('Link is not valid');
        }
      } else {
        debugPrint('retrieveDynamicLinkAndSignIn.deepLink[$deepLink]');
      }
    } catch (e) {
      print(e);
    }
    return null;
  }
}
