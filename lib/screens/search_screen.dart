import 'package:flutter/material.dart';
import 'package:nahcon/screens/movie_details_screen.dart';
import 'package:nahcon/screens/series_details_screen.dart';
import 'package:nahcon/utils/responsive_grid.dart';

import '../models/jellyfin_item.dart';
import '../services/jellyfin_service.dart';
import '../widgets/movie_card.dart';

class SearchScreen extends StatelessWidget {
  final String query;
  final List<JellyfinItem> results;
  final JellyfinService service;

  const SearchScreen({
    super.key,
    required this.query,
    required this.results,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search results for "$query"'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => GridView.builder(
          padding: const EdgeInsets.all(ResponsiveGrid.gridSpacing),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: ResponsiveGrid.columnCount(constraints),
            childAspectRatio: ResponsiveGrid.posterAspectRatio,
            crossAxisSpacing: ResponsiveGrid.gridSpacing,
            mainAxisSpacing: ResponsiveGrid.gridSpacing,
          ),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final item = results[index];
            return MovieCard(
              title: item.name,
              posterUrl: service.getImageUrl(item.imageUrl),
              rating: item.rating,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => item.type == 'Movie'
                        ? MovieDetailsScreen(movie: item, service: service)
                        : SeriesDetailsScreen(series: item, service: service),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
