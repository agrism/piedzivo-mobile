import 'package:flutter/material.dart';

class PlacesListScreen extends StatefulWidget {
  const PlacesListScreen({super.key});

  @override
  State<PlacesListScreen> createState() => _PlacesListScreenState();
}

class _PlacesListScreenState extends State<PlacesListScreen> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Vietu katalogs',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Stāvokļa pārbaude: $_counter',
            key: const Key('places_tab_counter'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            key: const Key('places_increment_button'),
            onPressed: () => setState(() => _counter++),
            child: const Text('Palielināt skaitītāju'),
          ),
        ],
      ),
    );
  }
}
