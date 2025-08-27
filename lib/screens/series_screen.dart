import 'package:flutter/material.dart';
import 'package:nahcon/widgets/movie_card.dart';

import '../models/jellyfin_item.dart';
import '../services/jellyfin_service.dart';
import '../utils/responsive_grid.dart';
import 'series_details_screen.dart';

class SeriesScreen extends StatelessWidget {
  final JellyfinService service;

  const SeriesScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Series')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return FutureBuilder<List<JellyfinItem>>(
            future: service.getAllSeries(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              return GridView.builder(
                padding: const EdgeInsets.all(ResponsiveGrid.gridSpacing),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: ResponsiveGrid.columnCount(constraints),
                  childAspectRatio: ResponsiveGrid.posterAspectRatio,
                  crossAxisSpacing: ResponsiveGrid.gridSpacing,
                  mainAxisSpacing: ResponsiveGrid.gridSpacing,
                ),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final series = snapshot.data![index];
                  return MovieCard(
                    title: series.name,
                    posterUrl: series.imageUrl != null
                        ? service.getImageUrl(series.imageUrl)
                        : null,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SeriesDetailsScreen(
                            series: series,
                            service: service,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
