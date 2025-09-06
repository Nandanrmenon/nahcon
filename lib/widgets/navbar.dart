import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:nahcon/screens/movie_details_screen.dart';
import 'package:nahcon/screens/series_details_screen.dart';
import 'package:nahcon/services/jellyfin_service.dart';
import 'package:nahcon/utils/constants.dart';
import 'package:nahcon/widgets/app_logo.dart'; // Import the service

class TopNav extends StatefulWidget implements PreferredSizeWidget {
  final List<NavbarItem> items;
  final double height;
  final JellyfinService service; // Add this

  const TopNav({
    super.key,
    required this.items,
    required this.service, // Add this
    this.height = 60,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  _TopNavState createState() => _TopNavState();
}

class _TopNavState extends State<TopNav> {
  final SearchController _searchController = SearchController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
            color: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
                side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant)),
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 60.0),
              child: Row(
                spacing: 8.0,
                children: [
                  Icon(
                    Symbols.search,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  Text(
                    'Search',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                                    errorBuilder: (context, error, stackTrace) {
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

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width < 400 ||
        MediaQuery.of(context).size.width > 1000;
    return Container(
      height: widget.height,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        spacing: 16,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            spacing: 8.0,
            children: [
              AppLogo(
                height: 44,
                width: 44,
                borderRadius: 10,
              ),
              Visibility(
                  visible: isDesktop,
                  maintainAnimation: true,
                  maintainState: true,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    opacity: isDesktop ? 1 : 0,
                    child: Text(
                      'nahCon',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w500),
                    ),
                  )),
            ],
          ),
          Material(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Row(
                spacing: 4,
                mainAxisSize: MainAxisSize.min,
                children: widget.items
                    .map((item) => NavItemWidget(item: item))
                    .toList(),
              ),
            ),
          ),
          buildSearch(),
        ],
      ),
    );
  }
}

class NavItemWidget extends StatefulWidget {
  final NavbarItem item;

  const NavItemWidget({super.key, required this.item});

  @override
  State<NavItemWidget> createState() => _NavItemWidgetState();
}

class _NavItemWidgetState extends State<NavItemWidget> {
  final bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: widget.item.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: widget.item.isSelected
              ? Theme.of(context).colorScheme.inverseSurface
              : _isHovered
                  ? Theme.of(context).colorScheme.surfaceBright
                  : Colors.transparent,
        ),
        child: Text(
          widget.item.label,
          style: TextStyle(
            color: widget.item.isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface,
            fontWeight:
                widget.item.isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class NavbarItem {
  final String label;
  final VoidCallback onTap;
  final bool isSelected; // Add this

  NavbarItem({
    required this.label,
    required this.onTap,
    this.isSelected = false, // Add this
  });
}
