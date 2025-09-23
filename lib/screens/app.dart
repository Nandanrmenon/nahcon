import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:nahcon/screens/series_details_screen.dart';
import 'package:nahcon/utils/constants.dart';
import 'package:nahcon/widgets/sidebar.dart';

import '../services/jellyfin_service.dart';
import 'accounts_screen.dart';
import 'library_screen.dart';
import 'login_screen.dart';
import 'movie_details_screen.dart';
import 'movies_screen.dart';
import 'series_screen.dart';

class App extends StatefulWidget {
  final JellyfinService service;

  const App({super.key, required this.service});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  // no extended search UI; always show icon-only button

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
        AccountsScreen(service: widget.service),
      ],
    );

    Widget buildBottomNav(Widget search) {
      return Positioned(
        bottom: 16,
        left: 16,
        right: 16,
        child: SafeArea(
          child: Material(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 920),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  // Home
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() => _selectedIndex = 0);
                      },
                      borderRadius: BorderRadius.circular(999),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Icon(
                          Symbols.home_rounded,
                          size: 24,
                          fill: _selectedIndex == 0 ? 1 : 0,
                          color: _selectedIndex == 0
                              ? kAppColor
                              : Theme.of(context).iconTheme.color,
                        ),
                      ),
                    ),
                  ),
                  // Movies
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() => _selectedIndex = 1);
                      },
                      borderRadius: BorderRadius.circular(999),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Icon(
                          Symbols.movie_rounded,
                          size: 24,
                          fill: _selectedIndex == 1 ? 1 : 0,
                          color: _selectedIndex == 1
                              ? kAppColor
                              : Theme.of(context).iconTheme.color,
                        ),
                      ),
                    ),
                  ),
                  // Series
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() => _selectedIndex = 2);
                      },
                      borderRadius: BorderRadius.circular(999),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Icon(
                          Symbols.tv_rounded,
                          size: 24,
                          fill: _selectedIndex == 2 ? 1 : 0,
                          color: _selectedIndex == 2
                              ? kAppColor
                              : Theme.of(context).iconTheme.color,
                        ),
                      ),
                    ),
                  ),
                  // Account (with long-press)
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedIndex = 3),
                      onLongPress: () => _showProfileSwitcher(isDesktop),
                      borderRadius: BorderRadius.circular(999),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildUserAvatar(),
                            const SizedBox(width: 6),
                            Icon(
                              Symbols.expand_all_rounded,
                              size: 14,
                              fill: _selectedIndex == 3 ? 1 : 0,
                              color: _selectedIndex == 3
                                  ? kAppColor
                                  : Theme.of(context).iconTheme.color,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Search (last item)
                  search,
                ],
              ),
            ),
          ),
        ),
      );
    }

    Widget buildSearch() {
      final isDesktop = MediaQuery.of(context).size.width < 400 ||
          MediaQuery.of(context).size.width > 1000;

      return SizedBox(
        child: SearchAnchor(
          shrinkWrap: false,
          isFullScreen: true,
          viewBackgroundColor: Theme.of(context).colorScheme.surfaceContainer,
          builder: (context, controller) => IconButton.filled(
            visualDensity: VisualDensity(horizontal: 2, vertical: 2),
            onPressed: () {
              controller.openView();
            },
            icon: const Icon(Icons.search),
          ),
          viewHintText: 'Search for Movies or TV Show',
          dividerColor: Colors.transparent,
          keyboardType: TextInputType.name,
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
                        mainAxisSize: MainAxisSize.min,
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
                          const SizedBox(width: 8),
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
            body: Stack(
              children: [
                content,
                buildBottomNav(buildSearch()),
              ],
            ),
          )
        : Scaffold(
            body: Row(
              children: [
                Sidebar(
                  service: widget.service,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (value) {
                    setState(() {
                      _selectedIndex = value;
                    });
                  },
                  search: buildSearch(),
                  accountSwitcher: IconButton(
                      onPressed: () => _showProfileSwitcher(isDesktop),
                      icon: Icon(Symbols.more_vert_rounded)),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: content,
                  ),
                ),
              ],
            ),
          );
  }

  Future<void> _showProfileSwitcher(isDesktop) async {
    final profiles = await widget.service.getProfiles();
    if (!mounted) return;

    Widget switchContent = CustomScrollView(
      shrinkWrap: true,
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
                subtitle: Text(profile['serverName'] ?? profile['serverUrl']),
                onTap: () async {
                  await widget.service.setCurrentProfile(profile['id']);
                  final success = await widget.service.tryAutoLogin();
                  if (success && mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => App(service: widget.service),
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
    );

    showAdaptiveDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
          alignment: isDesktop ? Alignment.center : Alignment.bottomCenter,
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 500 : double.maxFinite,
          ),
          child: switchContent),
    );
  }
}
