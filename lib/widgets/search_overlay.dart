import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../models/jellyfin_item.dart';
import '../services/jellyfin_service.dart';

class SearchOverlay extends StatelessWidget {
  final List<JellyfinItem> suggestions;
  final VoidCallback onViewAll;
  final Function(JellyfinItem) onItemTap;
  final JellyfinService service;

  const SearchOverlay({
    super.key,
    required this.suggestions,
    required this.onViewAll,
    required this.onItemTap,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 2,
        children: [
          ...suggestions.take(5).map(
                (item) => InkWell(
                  onTap: () => onItemTap(item),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      spacing: 8,
                      children: [
                        item.imageUrl != null
                            ? SizedBox(
                                width: 40,
                                height: 80,
                                child: Image.network(
                                  service.getImageUrl(item.imageUrl),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    print('Error loading image: $error');
                                    return const Icon(Symbols.movie);
                                  },
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
          if (suggestions.length > 5)
            ListTile(
              title: const Text('View all results'),
              trailing: const Icon(Symbols.arrow_forward),
              onTap: onViewAll,
            ),
        ],
      ),
    );
  }
}
