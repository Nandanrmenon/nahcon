import 'package:flutter/material.dart';
import 'package:nahcon/widgets/movie_card.dart';

import '../models/jellyfin_item.dart';
import '../services/jellyfin_service.dart';
import '../utils/responsive_grid.dart';
import 'series_details_screen.dart';

class SeriesScreen extends StatefulWidget {
  final JellyfinService service;

  const SeriesScreen({super.key, required this.service});

  @override
  State<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends State<SeriesScreen> {
  String? selectedGenre;
  bool _isLoading = false;
  List<String> _genres = [];

  @override
  void initState() {
    super.initState();
    _fetchGenres();
  }

  Future<void> _fetchGenres() async {
    final genres = await widget.service.getSeriesGenres();
    setState(() {
      _genres = genres;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (_genres.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: selectedGenre == null,
                      onSelected: (selected) {
                        setState(() {
                          selectedGenre = null;
                          _isLoading = true;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    ..._genres.map((genre) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(genre),
                            selected: selectedGenre == genre,
                            onSelected: (selected) {
                              setState(() {
                                selectedGenre = selected ? genre : null;
                                _isLoading = true;
                              });
                            },
                          ),
                        )),
                  ],
                ),
              ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return FutureBuilder<List<JellyfinItem>>(
                    future: widget.service.getAllSeries(genreId: selectedGenre),
                    key: ValueKey(selectedGenre),
                    builder: (context, snapshot) {
                      if (_isLoading && !snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasData) {
                        _isLoading = false;
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return GridView.builder(
                        padding:
                            const EdgeInsets.all(ResponsiveGrid.gridSpacing),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              ResponsiveGrid.columnCount(constraints),
                          childAspectRatio: ResponsiveGrid.posterAspectRatio,
                          crossAxisSpacing: ResponsiveGrid.gridSpacing,
                          mainAxisSpacing: ResponsiveGrid.gridSpacing,
                        ),
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final isDesktop =
                              ResponsiveGrid.isDesktop(constraints);
                          final series = snapshot.data![index];
                          return MovieCard(
                            title: series.name,
                            posterUrl: series.imageUrl != null
                                ? widget.service.getImageUrl(series.imageUrl)
                                : null,
                            onTap: () {
                              if (isDesktop) {
                                showModalBottomSheet(
                                  context: context,
                                  scrollControlDisabledMaxHeightRatio: 0.9,
                                  constraints: BoxConstraints(
                                      minWidth: 300, maxWidth: 1200),
                                  clipBehavior: Clip.antiAlias,
                                  builder: (context) => Center(
                                    child: SeriesDetailsScreen(
                                      series: series,
                                      service: widget.service,
                                    ),
                                  ),
                                );
                              } else {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => SeriesDetailsScreen(
                                      series: series,
                                      service: widget.service,
                                    ),
                                  ),
                                );
                              }
                            },
                            // onPlay: () {
                            //   Navigator.push(
                            //     context,
                            //     MaterialPageRoute(
                            //       builder: (context) => VideoScreen(
                            //         itemId: series.id,
                            //         videoUrl:
                            //             widget.service.getStreamUrl(series.id),
                            //         title: series.name,
                            //         service: widget.service,
                            //         jellyfinItem: series,
                            //       ),
                            //     ),
                            //   );
                            // },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
