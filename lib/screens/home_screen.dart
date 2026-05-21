import 'package:flutter/material.dart';

import '../models/place_model.dart';
import '../services/place_service.dart';
import '../widgets/place_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PlaceService _placeService =
      PlaceService();

  late Future<List<PlaceModel>> _placesFuture;

  @override
  void initState() {
    super.initState();

    _placesFuture =
        _placeService.getPlaces();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Campus Nearby Directory',
        ),
      ),

      body: FutureBuilder<List<PlaceModel>>(
        future: _placesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
              ),
            );
          }

          final places = snapshot.data ?? [];
          if (places.isEmpty) {
            return const Center(
              child: Text(
                'No places found',
              ),
            );
          }

          return ListView.builder(
            itemCount: places.length,
            itemBuilder: (context, index) {
              return PlaceCard(
                place: places[index],
              );
            },
          );
        },
      ),
    );
  }
}