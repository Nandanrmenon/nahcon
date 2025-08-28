import 'package:flutter/material.dart';
import 'package:nahcon/widgets/navbar.dart';

import '../services/jellyfin_service.dart';
import 'library_screen.dart';
import 'login_screen.dart';
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

  Widget _buildUserAvatar({double size = 24}) {
    return FutureBuilder<bool>(
      future: widget.service.hasUserImage(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data == true) {
          return CircleAvatar(
            radius: size / 2,
            backgroundImage: NetworkImage(
              widget.service.getUserImageUrl(),
              headers: widget.service.getVideoHeaders(),
            ),
          );
        }
        return Icon(Icons.account_circle, size: size);
      },
    );
  }

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
        SettingsScreen(service: widget.service),
      ],
    );
    return !isDesktop
        ? Scaffold(
            body: content,
            bottomNavigationBar: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              destinations: [
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
                GestureDetector(
                  onLongPress: _showProfileSwitcher,
                  child: NavigationDestination(
                    icon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildUserAvatar(),
                        const SizedBox(width: 4),
                        const Icon(Icons.expand_more, size: 12),
                      ],
                    ),
                    selectedIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildUserAvatar(),
                        const SizedBox(width: 4),
                        const Icon(Icons.expand_more, size: 12),
                      ],
                    ),
                    label: 'Account',
                  ),
                ),
              ],
            ),
          )
        : Scaffold(
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

  void _showProfileSwitcher() async {
    final profiles = await widget.service.getProfiles();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => CustomScrollView(
          controller: scrollController,
          slivers: [
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Switch Account',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: profiles.length,
                itemBuilder: (context, index) {
                  final profile = profiles[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: profile['userId'] != null
                          ? NetworkImage(
                              '${profile['serverUrl']}/Users/${profile['userId']}/Images/Primary',
                              headers: widget.service.getVideoHeaders(),
                            )
                          : null,
                      child: profile['userId'] == null
                          ? const Icon(Icons.account_circle)
                          : null,
                    ),
                    title: Text(profile['username']),
                    subtitle:
                        Text(profile['serverName'] ?? profile['serverUrl']),
                    onTap: () async {
                      await widget.service.setCurrentProfile(profile['id']);
                      final success = await widget.service.tryAutoLogin();
                      if (success && mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) =>
                                  App(service: widget.service),
                            ),
                            (Route<dynamic> route) => false);
                      }
                    },
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  height: 48,
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Account'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
