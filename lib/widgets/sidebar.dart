import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:nahcon/screens/movie_details_screen.dart';
import 'package:nahcon/screens/series_details_screen.dart';
import 'package:nahcon/services/jellyfin_service.dart';
import 'package:nahcon/utils/constants.dart';
import 'package:nahcon/widgets/app_logo.dart';
import 'package:nahcon/widgets/m_list.dart';

class Sidebar extends StatefulWidget {
  final JellyfinService service;
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final Widget search;
  final Widget? accountSwitcher;

  const Sidebar({
    super.key,
    required this.service,
    required this.selectedIndex,
    this.onDestinationSelected,
    required this.search,
    this.accountSwitcher,
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    widget.onDestinationSelected?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width < 400 || width > 1000;

    Widget buildSearch() {
      final isDesktop = MediaQuery.of(context).size.width < 400 ||
          MediaQuery.of(context).size.width > 1000;
      return SizedBox(
        child: SearchAnchor(
          shrinkWrap: true,
          isFullScreen: true,
          viewBackgroundColor: Theme.of(context).colorScheme.surfaceContainer,
          viewElevation: 4,
          viewShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          builder: (context, controller) => SizedBox(
            height: 44,
            child: Material(
              type: MaterialType.button,
              color: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
                // side: BorderSide(
                //     color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Padding(
                padding:
                    EdgeInsets.only(left: 16.0, right: isDesktop ? 60.0 : 16.0),
                child: Row(
                  spacing: 8.0,
                  children: [
                    Icon(
                      Symbols.search,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    if (isDesktop)
                      Text(
                        'Search',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          viewHintText: 'Search for Movies or TV Show',
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

    final large = Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      width: 280,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          spacing: 16.0,
          children: [
            // widget.search,
            Column(
              spacing: 8.0,
              children: [
                Row(
                  spacing: 8.0,
                  children: [
                    AppLogo(
                      width: 48,
                      height: 48,
                      borderRadius: 16.0,
                    ),
                    Text(
                      kAppName,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w500),
                    )
                  ],
                ),
                buildSearch(),
              ],
            ),
            Column(
              spacing: 8.0,
              children: [
                MListHeader(title: 'Library'),
                MListView(
                  items: [
                    MListItemData(
                      leading: Icon(
                        Symbols.video_library_rounded,
                        fill: _selectedIndex == 0 ? 1 : 0,
                        color: _selectedIndex == 0 ? kAppColor : null,
                      ),
                      title: 'Home',
                      subtitle: '',
                      onTap: () => _onItemTapped(0),
                      selected: _selectedIndex == 0,
                    ),
                    MListItemData(
                      leading: Icon(
                        Symbols.movie_rounded,
                        fill: _selectedIndex == 1 ? 1 : 0,
                        color: _selectedIndex == 1 ? kAppColor : null,
                      ),
                      title: 'Movies',
                      subtitle: '',
                      onTap: () => _onItemTapped(1),
                      selected: _selectedIndex == 1,
                    ),
                    MListItemData(
                      leading: Icon(
                        Symbols.tv_rounded,
                        fill: _selectedIndex == 2 ? 1 : 0,
                        color: _selectedIndex == 2 ? kAppColor : null,
                      ),
                      title: 'Series',
                      subtitle: '',
                      onTap: () => _onItemTapped(2),
                      selected: _selectedIndex == 2,
                    ),
                    MListItemData(
                      leading: _buildUserAvatar(),
                      title: 'Me',
                      subtitle: '',
                      onTap: () => _onItemTapped(3),
                      selected: _selectedIndex == 3,
                      suffix: widget.accountSwitcher,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );

    final small = NavigationRail(
      labelType: NavigationRailLabelType.selected,
      leading: Column(
        spacing: 8.0,
        children: [
          AppLogo(
            width: 48,
            height: 48,
            borderRadius: 16.0,
          ),
          // widget.search,
          buildSearch(),
        ],
      ),
      destinations: [
        NavigationRailDestination(
          icon: Icon(Symbols.video_library_rounded),
          label: Text('Home'),
          selectedIcon: Icon(
            Symbols.video_library_rounded,
            fill: 1,
          ),
        ),
        NavigationRailDestination(
          icon: Icon(Symbols.movie_rounded),
          label: Text('Movies'),
          selectedIcon: Icon(
            Symbols.movie_rounded,
            fill: 1,
          ),
        ),
        NavigationRailDestination(
          icon: Icon(Symbols.tv_rounded),
          label: Text('Series'),
          selectedIcon: Icon(
            Symbols.tv_rounded,
            fill: 1,
          ),
        ),
        NavigationRailDestination(
          icon: _buildUserAvatar(),
          label: Text('Me'),
        ),
      ],
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onItemTapped,
    );

    return AnimatedSwitcher(
      duration: Duration(milliseconds: 200),
      child: isDesktop ? large : small,
    );
  }
}
