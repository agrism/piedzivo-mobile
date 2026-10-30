import 'package:flutter/material.dart';

class FollowingScreen extends StatefulWidget {
  const FollowingScreen({super.key});

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Mani sekotie pasākumi un vietas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Stāvokļa pārbaude: $_counter',
            key: const Key('following_tab_counter'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            key: const Key('following_increment_button'),
            onPressed: () => setState(() => _counter++),
            child: const Text('Palielināt skaitītāju'),
          ),
        ],
      ),
    );
  }
}
