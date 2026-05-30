import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/place_model.dart';

class PlaceDetailScreen extends StatelessWidget {
  final PlaceModel place;

  const PlaceDetailScreen({
    super.key,
    required this.place,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(place.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            CachedNetworkImage(
              imageUrl: place.photoUrl ?? '',
              width: double.infinity,
              height: 250,
              fit: BoxFit.cover,
              errorWidget:
                  (context, url, error) {
                return Container(
                  height: 250,
                  color: Colors.grey.shade300,
                  child: const Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 50,
                    ),
                  ),
                );
              },
            ),

            Padding(
              padding:
                  const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style:
                        const TextStyle(
                      fontSize: 24,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        place.rating
                                ?.toString() ??
                            '-',
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  _buildInfoTile(
                    Icons.location_on,
                    "Alamat",
                    place.address,
                  ),

                  _buildInfoTile(
                    Icons.access_time,
                    "Jam Operasional",
                    place.openHour ??
                        'Tidak tersedia',
                  ),

                  _buildInfoTile(
                    Icons.phone,
                    "Telepon",
                    place.phone ??
                        'Tidak tersedia',
                  ),

                  _buildInfoTile(
                    Icons.language,
                    "Website",
                    place.website ??
                        'Tidak tersedia',
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    "Deskripsi",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    place.description ??
                        "Belum ada deskripsi.",
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Routing nanti
                      },
                      icon: const Icon(
                        Icons.directions,
                      ),
                      label:
                          const Text(
                        "Buka Rute",
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(icon),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight
                            .bold,
                  ),
                ),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}