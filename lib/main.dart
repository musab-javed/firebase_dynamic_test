import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_link_test/api.dart';
import 'package:firebase_link_test/home.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passController = TextEditingController();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint('App in foreground');
        Api().retrieveDynamicLinkAndSignIn(fromColdState: false);
        break;
      default:
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    listenAuth();
  }

  listenAuth() async {
    await Future.delayed(Duration(seconds: 1));
    print('listening to auth state');
    Api().onAuthStateChanged.listen((User? user) {
      if (user == null) {
        print('auth user is null');
      } else {
        print("authenticated ********* $user");
        Navigator.push(
            context, MaterialPageRoute(builder: ((context) => Home())));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: passController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
              ),
            ),
            const SizedBox(height: 32.0),
            ElevatedButton(
              onPressed: () {
                Api().sendEmailLink(email: emailController.text);
              },
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
