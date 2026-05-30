import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/place_model.dart';
import '../services/location_service.dart';
import '../services/place_service.dart';
import '../models/category_model.dart';
import '../services/category_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final PlaceService _placeService = PlaceService();
  final LocationService _locationService = LocationService();
  final CategoryService _categoryService =
      CategoryService();

  List<CategoryModel> _categories = [];

  int? _selectedCategoryId;

  Future<void> _loadCategories() async {
    final categories =
        await _categoryService
            .getCategories();

    setState(() {
      _categories = categories;
    });
  }

  Future<void> _filterPlaces(
    int? categoryId,
  ) async {
    setState(() {
      _selectedCategoryId =
          categoryId;

      if (categoryId == null) {
        _placesFuture =
            _placeService.getPlaces();
      } else {
        _placesFuture =
            _placeService
                .getPlacesByCategory(
          categoryId,
        );
      }
    });
  }

  late Future<List<PlaceModel>> _placesFuture;

  Position? _currentPosition;

  @override
  void initState() {
    super.initState();

    _placesFuture =
        _placeService.getPlaces();

    _loadCurrentLocation();

    _loadCategories();
  }

  Future<void> _loadCurrentLocation() async {
    final position =
        await _locationService.getCurrentLocation();

    if (position != null) {
      setState(() {
        _currentPosition = position;
      });

      debugPrint(
        'Current Location: '
        '${position.latitude}, '
        '${position.longitude}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Campus Map',
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 60,
            child: ListView(
              scrollDirection:
                  Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              children: [
                FilterChip(
                  label: const Text(
                    'Semua',
                  ),
                  selected:
                      _selectedCategoryId ==
                          null,
                  onSelected: (_) {
                    _filterPlaces(null);
                  },
                ),

                const SizedBox(width: 8),

                ..._categories.map(
                  (category) {
                    return Padding(
                      padding:
                          const EdgeInsets.only(
                        right: 8,
                      ),
                      child: FilterChip(
                        label: Text(
                          category.name,
                        ),
                        selected:
                            _selectedCategoryId ==
                                category.id,
                        onSelected: (_) {
                          _filterPlaces(
                            category.id,
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          Expanded(
            child:
                FutureBuilder<List<PlaceModel>>(
              future: _placesFuture,
              builder: (
                context,
                snapshot,
              ) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child:
                        CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      snapshot.error
                          .toString(),
                    ),
                  );
                }

                final places =
                    snapshot.data ?? [];

                return FlutterMap(
                  options: MapOptions(
                    initialCenter:
                        _currentPosition != null
                            ? LatLng(
                                _currentPosition!
                                    .latitude,
                                _currentPosition!
                                    .longitude,
                              )
                            : LatLng(
                                -7.2698,
                                112.7590,
                              ),
                    initialZoom: 15,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName:
                          'com.example.campus_nearby',
                    ),

                    MarkerLayer(
                      markers: [
                        ...places.map(
                          (place) {
                            return Marker(
                              point: LatLng(
                                place.latitude,
                                place.longitude,
                              ),
                              width: 80,
                              height: 80,
                              child:
                                  GestureDetector(
                                onTap: () {
                                  _showPlaceDialog(
                                    place,
                                  );
                                },
                                child:
                                    const Icon(
                                  Icons
                                      .location_on,
                                  color:
                                      Colors.red,
                                  size: 40,
                                ),
                              ),
                            );
                          },
                        ),

                        if (_currentPosition !=
                            null)
                          Marker(
                            point: LatLng(
                              _currentPosition!
                                  .latitude,
                              _currentPosition!
                                  .longitude,
                            ),
                            width: 80,
                            height: 80,
                            child: const Icon(
                              Icons.my_location,
                              color: Colors.blue,
                              size: 40,
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showPlaceDialog(
    PlaceModel place,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(
            16,
          ),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                place.name,
                style:
                    const TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                place.address,
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  const Icon(
                    Icons.star,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    place.rating?.toString() ??
                        '-',
                  ),
                ],
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(
                      context,
                    );
                  },
                  icon: const Icon(
                    Icons.close,
                  ),
                  label: const Text(
                    'Close',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}