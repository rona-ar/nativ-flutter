import 'package:flutter/material.dart';
import 'package:nativ/page/home.dart';

class MainPage extends StatefulWidget {
  final VoidCallback logout;
  const MainPage({super.key, required this.logout});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("NatiV Pro"),
        actions: [
          IconButton(
            onPressed: widget.logout,
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: const HomePage(),
    );
  }
}
