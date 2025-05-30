import 'package:flutter/material.dart';
import 'package:nahcon/widgets/navbar.dart';

import '../services/jellyfin_service.dart';
import 'library_screen.dart';
import 'movies_screen.dart';
import 'series_screen.dart';
import 'settings_screen.dart';

class App extends StatefulWidget {
  final JellyfinService service;

  const App({super.key, required this.service});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;

    final content = IndexedStack(
      index: _selectedIndex,
      children: [
        LibraryScreen(service: widget.service),
        MoviesScreen(service: widget.service),
        SeriesScreen(service: widget.service),
        SettingsScreen(service: widget.service),
      ],
    );
    return !isDesktop
        ? Scaffold(
            body: content,
            bottomNavigationBar: NavigationBar(
              labelBehavior:
                  NavigationDestinationLabelBehavior.onlyShowSelected,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.movie_outlined),
                  selectedIcon: Icon(Icons.movie),
                  label: 'Movies',
                ),
                NavigationDestination(
                  icon: Icon(Icons.tv_outlined),
                  selectedIcon: Icon(Icons.tv),
                  label: 'Series',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Me',
                ),
              ],
            ),
          )
        : Scaffold(
            // appBar: AppBar(
            //   title: const Text('nahCon'),
            //   actions: [
            //     TextButton(
            //       child: const Text('Home'),
            //       onPressed: () {
            //         setState(() {
            //           _selectedIndex = 0; // Switch to Settings
            //         });
            //       },
            //     ),
            //     TextButton(
            //       child: const Text('Movies'),
            //       onPressed: () {
            //         setState(() {
            //           _selectedIndex = 1; // Switch to Settings
            //         });
            //       },
            //     ),
            //     TextButton(
            //       child: const Text('Series'),
            //       onPressed: () {
            //         setState(() {
            //           _selectedIndex = 2; // Switch to Settings
            //         });
            //       },
            //     ),
            //     TextButton(
            //       child: const Text('Me'),
            //       onPressed: () {
            //         setState(() {
            //           _selectedIndex = 3; // Switch to Settings
            //         });
            //       },
            //     ),
            //   ],
            // ),
            appBar: TopNav(
              service: widget.service,
              items: [
                NavbarItem(
                  isSelected: _selectedIndex == 0,
                  label: 'Home',
                  onTap: () {
                    setState(() {
                      _selectedIndex = 0; // Switch to Settings
                    });
                  },
                ),
                NavbarItem(
                  isSelected: _selectedIndex == 1,
                  label: 'Movies',
                  onTap: () {
                    setState(() {
                      _selectedIndex = 1; // Switch to Settings
                    });
                  },
                ),
                NavbarItem(
                  isSelected: _selectedIndex == 2,
                  label: 'Series',
                  onTap: () {
                    setState(() {
                      _selectedIndex = 2; // Switch to Settings
                    });
                  },
                ),
                NavbarItem(
                  isSelected: _selectedIndex == 3,
                  label: 'Me',
                  onTap: () {
                    setState(() {
                      _selectedIndex = 3; // Switch to Settings
                    });
                  },
                ),
              ],
            ),

            body: content,
          );
  }
}
