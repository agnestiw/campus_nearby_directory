import 'package:flutter/material.dart';

import '../models/place_model.dart';
import '../services/favorites_service.dart';
import '../services/place_service.dart';
import '../widgets/place_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoritesService _favService = FavoritesService();
  final PlaceService _placeService = PlaceService();

  Future<List<PlaceModel>> _loadFavoritePlaces(Set<int> ids) async {
    final futures = ids.map((id) => _placeService.getPlaceById(id));
    final results = await Future.wait(futures);
    return results.whereType<PlaceModel>().toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorit')),
      body: ValueListenableBuilder<Set<int>>(
        valueListenable: _favService.favorites,
        builder: (context, favs, _) {
          if (favs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      size: 40,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum ada favorit',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap ❤ pada tempat yang kamu suka untuk menambah favorit.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return FutureBuilder<List<PlaceModel>>(
            future: _loadFavoritePlaces(favs),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final places = snapshot.data ?? [];
              if (places.isEmpty) {
                return const Center(child: Text('Tidak dapat memuat favorit.'));
              }
              return RefreshIndicator(
                onRefresh: () async { setState(() {}); },
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: places.length,
                  itemBuilder: (context, index) {
                    final place = places[index];
                    return PlaceCard(
                      place: place,
                      categoryName: null,
                      distanceText: null,
                      isFavorite: true,
                      onFavoriteToggle: () async {
                        await _favService.toggleFavorite(place.id);
                        setState(() {});
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}