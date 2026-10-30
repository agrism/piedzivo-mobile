import 'package:flutter/material.dart';

class PlaceDetailScreen extends StatelessWidget {
  final String placeId;

  const PlaceDetailScreen({super.key, required this.placeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vietas detaļas')),
      body: Center(
        child: Text('Vietas ID: $placeId'),
      ),
    );
  }
}
