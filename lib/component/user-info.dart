import 'package:flutter/material.dart';

class UserInfo extends StatelessWidget {
  final String username;
  const UserInfo({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hello,',
            style: TextStyle(fontSize: 24),
          ),
          Text(
            username,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
