import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/category_model.dart';
import '../models/place_model.dart';
import '../services/category_service.dart';
import '../services/location_service.dart';
import '../services/place_service.dart';
import '../services/favorites_service.dart';
import '../utils/distance_helper.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/place_card.dart';
import '../widgets/search_bar_widget.dart';
import '../core/app_theme.dart';
import 'place_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PlaceService _placeService = PlaceService();
  final CategoryService _categoryService = CategoryService();
  final LocationService _locationService = LocationService();
  final FavoritesService _favService = FavoritesService();

  List<PlaceModel> _allPlaces = [];
  List<PlaceModel> _filteredPlaces = [];
  List<CategoryModel> _categories = [];
  Map<int, String> _categoryMap = {};

  Position? _currentPosition;
  String _searchKeyword = '';
  int? _selectedCategoryId;

  bool _isLoading = true;
  String? _errorMessage;

  late PageController _pageController;
  Timer? _carouselTimer;
  int _currentCarouselIndex = 0;

  @override
  void initState() {
    super.initState();

    _pageController = PageController();
    _startCarousel();

    _favService.loadFavorites();
    _favService.favorites.addListener(_onFavoritesChanged);

    _loadData();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    _favService.favorites.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  void _startCarousel() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      final spots = _spotOfTheDayPlaces;
      if (spots.isNotEmpty) {
        setState(() {
          _currentCarouselIndex = (_currentCarouselIndex + 1) % spots.length;
        });
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            _currentCarouselIndex,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  List<PlaceModel> get _spotOfTheDayPlaces {
    final sorted = List<PlaceModel>.from(_allPlaces);
    sorted.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
    return sorted.take(3).toList();
  }

  void _onFavoritesChanged() {
    if (!mounted) return;
    final favIds = _favService.favorites.value;
    setState(() {
      for (final place in _allPlaces) {
        place.isFavorite = favIds.contains(place.id);
      }
      for (final place in _filteredPlaces) {
        place.isFavorite = favIds.contains(place.id);
      }
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _categoryService.getCategories(),
        _placeService.getPlaces(),
      ]);

      final categories = results[0] as List<CategoryModel>;
      final places = results[1] as List<PlaceModel>;

      final categoryMap = {for (var c in categories) c.id: c.name};

      _loadLocation();

      setState(() {
        _categories = categories;
        _categoryMap = categoryMap;
        _allPlaces = places;
        _filteredPlaces = places;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _loadLocation() async {
    final result = await _locationService.getCurrentLocation();
    if (result.isSuccess && mounted) {
      setState(() => _currentPosition = result.position);
      _applyFilter();
    }
  }

  void _applyFilter() {
    List<PlaceModel> filtered = _allPlaces;

    if (_selectedCategoryId != null) {
      filtered = filtered.where((p) => p.categoryId == _selectedCategoryId).toList();
    }

    if (_searchKeyword.isNotEmpty) {
      final kw = _searchKeyword.toLowerCase();
      filtered = filtered.where((p) {
        final catName = _categoryMap[p.categoryId]?.toLowerCase() ?? '';
        return p.name.toLowerCase().contains(kw) ||
               p.address.toLowerCase().contains(kw) ||
               catName.contains(kw);
      }).toList();
    }

    if (_currentPosition != null) {
      filtered.sort((a, b) {
        final distA = DistanceHelper.calculateDistance(
          startLat: _currentPosition!.latitude,
          startLng: _currentPosition!.longitude,
          endLat: a.latitude,
          endLng: a.longitude,
        );
        final distB = DistanceHelper.calculateDistance(
          startLat: _currentPosition!.latitude,
          startLng: _currentPosition!.longitude,
          endLat: b.latitude,
          endLng: b.longitude,
        );
        return distA.compareTo(distB);
      });
    }

    setState(() => _filteredPlaces = filtered);
  }

  String? _getDistance(PlaceModel place) {
    if (_currentPosition == null) return null;
    final meters = DistanceHelper.calculateDistance(
      startLat: _currentPosition!.latitude,
      startLng: _currentPosition!.longitude,
      endLat: place.latitude,
      endLng: place.longitude,
    );
    return DistanceHelper.formatDistance(meters);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A), // Dark Slate
              Color(0xFF3B82F6), // Vibrant Blue
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 24),
                              // ── Search ───────────────────────────────
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: SearchBarWidget(
                                    hint: 'Cari cafe, fotokopi, ATM...',
                                    onChanged: (value) {
                                      _searchKeyword = value;
                                      _applyFilter();
                                    },
                                    onFilterTap: () {
                                      _showFilterBottomSheet();
                                    },
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 20),

                            // ── Spot of the Day ────────────────────
                            if (!_isLoading && _searchKeyword.isEmpty && _selectedCategoryId == null)
                              _buildSpotCarousel(),

                            if (!_isLoading && _searchKeyword.isEmpty && _selectedCategoryId == null)
                              const SizedBox(height: 32),

                            // ── Rekomendasi Terdekat ────────────────
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _searchKeyword.isEmpty ? 'Rekomendasi Terdekat' : 'Hasil Pencarian',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1A1A2E),
                                    ),
                                  ),

                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),

                      // ── Content ──────────────────────────────
                      _buildContent(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Campus Nearby',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF1A1A2E),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpotCarousel() {
    final spots = _spotOfTheDayPlaces;
    if (spots.isEmpty) return const SizedBox();

    return Column(
      children: [
        SizedBox(
          height: 240,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentCarouselIndex = index;
              });
            },
            itemCount: spots.length,
            itemBuilder: (context, index) {
              return _buildSpotCard(spots[index]);
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(spots.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentCarouselIndex == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentCarouselIndex == index ? const Color(0xFF3B82F6) : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Filter Kategori", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Semua'),
                          selected: _selectedCategoryId == null,
                          onSelected: (val) {
                            setState(() => _selectedCategoryId = null);
                            setModalState(() {});
                            _applyFilter();
                            Navigator.pop(context);
                          },
                        ),
                        ..._categories.map((cat) => ChoiceChip(
                          label: Text(cat.name),
                          selected: _selectedCategoryId == cat.id,
                          onSelected: (val) {
                            setState(() => _selectedCategoryId = cat.id);
                            setModalState(() {});
                            _applyFilter();
                            Navigator.pop(context);
                          },
                        )).toList(),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }

  Widget _buildSpotCard(PlaceModel place) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlaceDetailScreen(
              place: place,
              categoryName: _categoryMap[place.categoryId],
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        height: 240,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          image: DecorationImage(
            image: CachedNetworkImageProvider(place.photoUrl ?? ''),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ]
        ),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),
            // TOP BADGES
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.stars_rounded, color: Color(0xFF8B5CF6), size: 16),
                    SizedBox(width: 6),
                    Text(
                      'SPOT OF THE DAY',
                      style: TextStyle(
                        color: Color(0xFF8B5CF6),
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_border_rounded,
                  color: Color(0xFF1A1A2E),
                  size: 18,
                ),
              ),
            ),
            // BOTTOM CONTENT
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_cafe_rounded, color: Colors.white, size: 12),
                        const SizedBox(width: 6),
                        Text(
                          _categoryMap[place.categoryId] ?? 'Kategori',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    place.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${place.rating ?? 0.0} (230 review)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_outlined, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                place.address,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: const [
                            Text(
                              'Lihat Detail',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                          ],
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const SliverToBoxAdapter(
        child: Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator())),
      );
    }

    if (_errorMessage != null) {
      return SliverToBoxAdapter(
        child: ErrorStateWidget(
          type: ErrorType.network,
          onRetry: _loadData,
        ),
      );
    }

    if (_filteredPlaces.isEmpty) {
      return SliverToBoxAdapter(
        child: ErrorStateWidget(
          type: ErrorType.empty,
          onRetry: () {
            setState(() {
              _searchKeyword = '';
            });
            _applyFilter();
          },
        ),
      );
    }

    // Since Spot of the Day is now a top 3 rated carousel separate from the list, we show all filteredPlaces in Rekomendasi
    final listPlaces = _filteredPlaces;

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final place = listPlaces[index];
          return PlaceCard(
            place: place,
            categoryName: _categoryMap[place.categoryId],
            distanceText: _getDistance(place),
            isFavorite: place.isFavorite,
            onFavoriteToggle: () async {
              await _favService.toggleFavorite(place.id);
            },
          );
        },
        childCount: listPlaces.length,
      ),
    );
  }
}