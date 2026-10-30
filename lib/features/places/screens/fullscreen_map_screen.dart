import 'package:flutter/material.dart';

class FullscreenMapScreen extends StatelessWidget {
  const FullscreenMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pilnekrāna karte')),
      body: const Center(
        child: Text('Karte tiks implementēta Uzdevumā 8'),
      ),
    );
  }
}

