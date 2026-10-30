import 'package:flutter/material.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meklēšana'),
      ),
      body: const Center(
        child: Text('Meklēšanas ekrāns tiks implementēts Uzdevumā 10'),
      ),
    );
  }
}

