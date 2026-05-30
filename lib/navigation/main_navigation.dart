import 'package:flutter/material.dart';

import '../screens/home_screen.dart';
import '../screens/map_screen.dart';
import '../screens/categories_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/profile_screen.dart';

class MainNavigation
    extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation>
      createState() =>
          _MainNavigationState();
}

class _MainNavigationState
    extends State<MainNavigation> {
  int currentIndex = 0;

  final pages = [
    const HomeScreen(),
    const MapScreen(),
    const FavoritesScreen(),
    const CategoriesScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],

      bottomNavigationBar:
          BottomNavigationBar(
        currentIndex: currentIndex,

        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },

        type:
            BottomNavigationBarType
                .fixed,

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),

          BottomNavigationBarItem(
            icon:
                Icon(Icons.favorite),
            label: 'Favorites',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view),
            label: 'Categories',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}