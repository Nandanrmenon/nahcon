import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:nahcon/screens/series_details_screen.dart';
import 'package:nahcon/widgets/navbar.dart';

import '../services/jellyfin_service.dart';
import 'library_screen.dart';
import 'login_screen.dart';
import 'movie_details_screen.dart';
import 'movies_screen.dart';
import 'search_screen.dart';
import 'series_screen.dart';
import 'settings_screen.dart';

class App extends StatefulWidget {
  final JellyfinService service;

  const App({super.key, required this.service});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  bool _isExtended = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isExtended = false;
        });
      }
    });
  }

  Widget _buildUserAvatar({double size = 24}) {
    return FutureBuilder<bool>(
      future: widget.service.hasUserImage(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data == true) {
          return CircleAvatar(
            radius: size / 2,
            backgroundImage: null,
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: widget.service.getUserImageUrl(),
                httpHeaders: widget.service.getVideoHeaders(),
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) =>
                    Icon(Icons.account_circle, size: size),
                placeholder: (context, url) =>
                    Icon(Icons.account_circle, size: size),
              ),
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
        // if (!isDesktop) SearchScreen(service: widget.service),
        SettingsScreen(service: widget.service),
      ],
    );

    Widget buildSearch() {
      final isDesktop = MediaQuery.of(context).size.width < 400 ||
          MediaQuery.of(context).size.width > 1000;

      return SizedBox(
        child: SearchAnchor(
          shrinkWrap: false,
          isFullScreen: true,
          viewBackgroundColor: Theme.of(context).colorScheme.surfaceContainer,
          builder: (context, controller) => SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: () {
                controller.openView();
              },
              child: AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _isExtended
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 4.0,
                        children: [
                          const Icon(Icons.search),
                          const Text('Search'),
                        ],
                      )
                    : const Icon(Icons.search), // smoothly collapses
              ),
            ),
          ),
          viewHintText: 'Search for Movies or TV Show',
          dividerColor: Colors.transparent,
          suggestionsBuilder: (context, controller) async {
            if (controller.text.isEmpty) {
              final randomItems = await widget.service.getSuggestions(limit: 5);
              return [
                const ListTile(
                  title: Text('Suggestions for you'),
                  enabled: false,
                ),
                ...randomItems.map(
                  (item) => InkWell(
                    onTap: () {
                      controller.closeView(item.name);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MovieDetailsScreen(
                            movie: item,
                            service: widget.service,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0),
                      child: Row(
                        spacing: 8,
                        children: [
                          item.imageUrl != null
                              ? SizedBox(
                                  width: 50,
                                  height: 80,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(5),
                                    child: Image.network(
                                      widget.service.getImageUrl(item.imageUrl),
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        print('Error loading image: $error');
                                        return const Icon(Symbols.movie);
                                      },
                                    ),
                                  ),
                                )
                              : const SizedBox(
                                  width: 40,
                                  height: 60,
                                  child: Icon(Symbols.movie),
                                ),
                          Expanded(
                            child: Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ];
            }
            final results = await widget.service.search(controller.text);
            return results.map(
              (item) => ListTile(
                leading: item.imageUrl != null
                    ? SizedBox(
                        width: 40,
                        height: 60,
                        child: Image.network(
                          widget.service.getImageUrl(item.imageUrl),
                          fit: BoxFit.cover,
                        ),
                      )
                    : const SizedBox(
                        width: 40,
                        height: 60,
                        child: Icon(Symbols.movie),
                      ),
                title: Text(item.name),
                onTap: () {
                  controller.closeView(item.name);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => item.type == 'Movie'
                          ? MovieDetailsScreen(
                              movie: item,
                              service: widget.service,
                            )
                          : SeriesDetailsScreen(
                              series: item,
                              service: widget.service,
                            ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      );
    }

    return !isDesktop
        ? Scaffold(
            body: content,
            floatingActionButton: buildSearch(),
            bottomNavigationBar: NavigationBar(
              labelBehavior:
                  NavigationDestinationLabelBehavior.onlyShowSelected,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              destinations: [
                NavigationDestination(
                  icon: Icon(Symbols.home_rounded),
                  selectedIcon: Icon(
                    Symbols.home_rounded,
                    fill: 1.0,
                  ),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Symbols.movie_rounded),
                  selectedIcon: Icon(
                    Symbols.movie_rounded,
                    fill: 1.0,
                  ),
                  label: 'Movies',
                ),
                NavigationDestination(
                  icon: Icon(Symbols.tv_rounded),
                  selectedIcon: Icon(
                    Symbols.tv_rounded,
                    fill: 1.0,
                  ),
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
                        const Icon(Symbols.expand_all_rounded, size: 12),
                      ],
                    ),
                    selectedIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildUserAvatar(),
                        const SizedBox(width: 4),
                        const Icon(Symbols.expand_all_rounded, size: 12),
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
                      _selectedIndex = 0;
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
            body: Center(
                child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: content,
            )),
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
                  final userImageUrl = profile['userId'] != null
                      ? '${profile['serverUrl']}/Users/${profile['userId']}/Images/Primary'
                      : null;
                  return ListTile(
                    leading: userImageUrl != null
                        ? CircleAvatar(
                            backgroundImage: null,
                            child: ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: userImageUrl,
                                httpHeaders: widget.service.getVideoHeaders(),
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.account_circle),
                                placeholder: (context, url) =>
                                    const Icon(Icons.account_circle),
                              ),
                            ),
                          )
                        : const Icon(Icons.account_circle),
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
                    icon: const Icon(Symbols.add),
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
