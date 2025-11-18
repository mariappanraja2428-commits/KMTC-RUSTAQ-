import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pages/records_page.dart';
import 'pages/record_form_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _signedIn = false;

  @override
  void initState() {
    super.initState();
    _ensureSignedIn();
  }

  Future<void> _ensureSignedIn() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
    }
    setState(() => _signedIn = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_signedIn) {
      return const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NAMA Rustaq',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const RecordsPage(),
      routes: {
        '/new': (_) => const RecordFormPage(),
      },
    );
  }
}
