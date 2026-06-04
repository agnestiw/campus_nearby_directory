import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';

import '../screens/home_screen.dart';
import '../screens/map_screen.dart';
import '../screens/categories_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    MapScreen(),
    CategoriesScreen(),
    FavoritesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Allows the body to flow underneath the curved navigation bar
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 12), // Sitting lower to save space
        child: ClipPath(
          clipper: TopUnclippedRoundedRectClipper(),
          child: CurvedNavigationBar(
            index: _currentIndex,
            height: 65, // Slightly smaller height
            iconPadding: 10, // Makes the floating blue circle smaller
            backgroundColor: Colors.transparent, // Transparent to see page behind
            color: const Color(0xFF1A1A2E), // Dark bar color
            buttonBackgroundColor: const Color(0xFF1A6FDB), // Blue active circle
            animationDuration: const Duration(milliseconds: 300),
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: [
              CurvedNavigationBarItem(
                child: Icon(
                  _currentIndex == 0 ? Icons.home_rounded : Icons.home_outlined,
                  color: Colors.white,
                  size: 24, // Smaller icons
                ),
                label: 'Home',
                labelStyle: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: _currentIndex == 0 ? FontWeight.w600 : FontWeight.w500,
                  color: _currentIndex == 0 ? Colors.transparent : Colors.white70,
                ),
              ),
              CurvedNavigationBarItem(
                child: Icon(
                  _currentIndex == 1 ? Icons.map_rounded : Icons.map_outlined,
                  color: Colors.white,
                  size: 24,
                ),
                label: 'Peta',
                labelStyle: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: _currentIndex == 1 ? FontWeight.w600 : FontWeight.w500,
                  color: _currentIndex == 1 ? Colors.transparent : Colors.white70,
                ),
              ),
              CurvedNavigationBarItem(
                child: Icon(
                  _currentIndex == 2 ? Icons.grid_view_rounded : Icons.grid_view_outlined,
                  color: Colors.white,
                  size: 24,
                ),
                label: 'Kategori',
                labelStyle: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: _currentIndex == 2 ? FontWeight.w600 : FontWeight.w500,
                  color: _currentIndex == 2 ? Colors.transparent : Colors.white70,
                ),
              ),
              CurvedNavigationBarItem(
                child: Icon(
                  _currentIndex == 3 ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                label: 'Favorit',
                labelStyle: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: _currentIndex == 3 ? FontWeight.w600 : FontWeight.w500,
                  color: _currentIndex == 3 ? Colors.transparent : Colors.white70,
                ),
              ),
              CurvedNavigationBarItem(
                child: Icon(
                  _currentIndex == 4 ? Icons.person_rounded : Icons.person_outline_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                label: 'Profile',
                labelStyle: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: _currentIndex == 4 ? FontWeight.w600 : FontWeight.w500,
                  color: _currentIndex == 4 ? Colors.transparent : Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TopUnclippedRoundedRectClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    // RRect dengan radius berbeda: atas membulat sedikit agar tidak memotong lingkaran, bawah membulat penuh seperti pil
    final barPath = Path()
      ..addRRect(RRect.fromRectAndCorners(
        Rect.fromLTWH(0, 0, size.width, size.height),
        topLeft: const Radius.circular(8),
        topRight: const Radius.circular(8),
        bottomLeft: const Radius.circular(32),
        bottomRight: const Radius.circular(32),
      ));

    // Area bebas di bagian atas agar lingkaran biru tidak ikut terpotong
    final overflowPath = Path()
      ..addRect(Rect.fromLTWH(-100, -1000, size.width + 200, 1000));

    return Path.combine(PathOperation.union, barPath, overflowPath);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}