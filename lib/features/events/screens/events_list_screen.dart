import 'package:flutter/material.dart';

class EventsListScreen extends StatefulWidget {
  const EventsListScreen({super.key});

  @override
  State<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends State<EventsListScreen> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Pasākumu saraksts',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Stāvokļa pārbaude: $_counter',
            key: const Key('events_tab_counter'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            key: const Key('events_increment_button'),
            onPressed: () => setState(() => _counter++),
            child: const Text('Palielināt skaitītāju'),
          ),
        ],
      ),
    );
  }
}
