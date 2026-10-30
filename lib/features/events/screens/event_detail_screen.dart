import 'package:flutter/material.dart';

class EventDetailScreen extends StatelessWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pasākuma detaļas')),
      body: Center(
        child: Text('Pasākuma ID: $eventId'),
      ),
    );
  }
}
