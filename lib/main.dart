import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'page/login.dart';
import 'page/main.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoggedIn = false;

  @override
  void initState() {
    checkLoginStatus();
    super.initState();
  }

  Future<void> checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    setState(() {
      _isLoggedIn = isLoggedIn;
    });
    var userid = prefs.getInt('userid') ?? false;
    if (userid == false) {
      setState(() {
        _isLoggedIn = false;
      });
    }
  }

  void _login() async {
    setState(() {
      _isLoggedIn = true;
    });
  }

  void _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    await prefs.remove('userid');
    await prefs.remove('user_nim');
    await prefs.setBool('isLoggedIn', false);
    setState(() {
      _isLoggedIn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Narnoor'),
      home: _isLoggedIn ? MainPage(logout: _logout) : LoginPage(login: _login),
    );
  }
}
