import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/place_model.dart';

class PlaceCard extends StatelessWidget {
  final PlaceModel place;

  const PlaceCard({
    super.key,
    required this.place,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CachedNetworkImage(
            imageUrl: place.photoUrl ?? '',
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,

            errorWidget:
                (context, url, error) {
              return Container(
                height: 200,
                color: Colors.grey.shade300,
                child: const Center(
                  child: Icon(Icons.broken_image),
                ),
              );
            },
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(place.address),

                const SizedBox(height: 8),

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
              ],
            ),
          ),
        ],
      ),
    );
  }
}