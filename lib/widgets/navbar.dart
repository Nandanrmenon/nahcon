import 'package:flutter/material.dart';
import 'package:nahcon/screens/movie_details_screen.dart';
import 'package:nahcon/screens/series_details_screen.dart';
import 'package:nahcon/services/jellyfin_service.dart'; // Import the service

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

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width < 400 ||
        MediaQuery.of(context).size.width > 1000;
    return Material(
      elevation: 4,
      child: Container(
        height: widget.height,
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Row(
          spacing: 16,
          children: [
            SizedBox(
              width: 24,
            ),
            Text(
              'nahCon',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const VerticalDivider(indent: 12, endIndent: 12),
            Row(
              spacing: 4,
              children: widget.items
                  .map((item) => NavItemWidget(item: item))
                  .toList(),
            ),
            const Spacer(),
            SizedBox(
              width: isDesktop ? 300 : null,
              child: SearchAnchor(
                shrinkWrap: true,
                isFullScreen: isDesktop ? false : true,
                viewBackgroundColor:
                    Theme.of(context).colorScheme.surfaceContainer,
                viewElevation: 4,
                viewShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                builder: (context, controller) {
                  return isDesktop
                      ? SearchBar(
                          controller: controller,
                          shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          )),
                          side: WidgetStatePropertyAll(BorderSide(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          )),
                          backgroundColor: WidgetStatePropertyAll(
                            Theme.of(context).colorScheme.surface,
                          ),
                          padding: const WidgetStatePropertyAll<EdgeInsets>(
                            EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 4.0),
                          ),
                          constraints: BoxConstraints(maxHeight: 200),
                          onTap: () {
                            controller.openView();
                          },
                          leading: const Icon(Icons.search),
                          hintText: 'Search movies and series',
                        )
                      : IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () {
                            controller.openView();
                          },
                        );
                },
                suggestionsBuilder: (context, controller) async {
                  if (controller.text.isEmpty) {
                    final randomItems =
                        await widget.service.getRandomMovies(limit: 5);
                    return [
                      const ListTile(
                        title: Text('Suggestions for you'),
                        enabled: false,
                      ),
                      ...randomItems.map((item) => InkWell(
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Row(
                                spacing: 8,
                                children: [
                                  item.imageUrl != null
                                      ? SizedBox(
                                          width: 50,
                                          height: 80,
                                          child: Image.network(
                                            widget.service
                                                .getImageUrl(item.imageUrl),
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              print(
                                                  'Error loading image: $error');
                                              return const Icon(Icons.movie);
                                            },
                                          ),
                                        )
                                      : const SizedBox(
                                          width: 40,
                                          height: 60,
                                          child: Icon(Icons.movie),
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
                          )),
                    ];
                  }

                  final results = await widget.service.search(controller.text);

                  return results.map((item) => ListTile(
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
                                child: Icon(Icons.movie),
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
                      ));
                },
              ),
            ),
            SizedBox(
              width: 24,
            )
          ],
        ),
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
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: widget.item.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: widget.item.isSelected
                ? Theme.of(context).colorScheme.primary
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
                  widget.item.isSelected ? FontWeight.bold : FontWeight.normal,
            ),
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
