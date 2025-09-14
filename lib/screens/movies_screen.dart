import 'package:flutter/material.dart';
import 'package:nahcon/screens/movie_details_screen.dart';
import 'package:nahcon/screens/video_screen.dart';
import 'package:nahcon/widgets/movie_card.dart';

import '../models/jellyfin_item.dart';
import '../services/jellyfin_service.dart';
import '../utils/responsive_grid.dart';

class MoviesScreen extends StatefulWidget {
  final JellyfinService service;
  const MoviesScreen({super.key, required this.service});

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  String? selectedGenre;
  bool _isLoading = false;
  List<String> _genres = [];

  @override
  void initState() {
    super.initState();
    _fetchGenres();
  }

  Future<void> _fetchGenres() async {
    final genres = await widget.service.getMovieGenres();
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
                  final isDesktop = ResponsiveGrid.isDesktop(constraints);
                  return FutureBuilder<List<JellyfinItem>>(
                    key: ValueKey(selectedGenre),
                    future: widget.service.getAllMovies(genreId: selectedGenre),
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
                          final movie = snapshot.data![index];
                          return MovieCard(
                            title: movie.name,
                            onTap: () {
                              if (isDesktop) {
                                showModalBottomSheet(
                                  context: context,
                                  scrollControlDisabledMaxHeightRatio: 0.9,
                                  constraints: BoxConstraints(
                                      minWidth: 300, maxWidth: 1200),
                                  clipBehavior: Clip.antiAlias,
                                  builder: (context) => Center(
                                    child: MovieDetailsScreen(
                                      movie: movie,
                                      service: widget.service,
                                    ),
                                  ),
                                );
                              } else {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => MovieDetailsScreen(
                                      movie: movie,
                                      service: widget.service,
                                    ),
                                  ),
                                );
                              }
                            },
                            onPlay: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VideoScreen(
                                    itemId: movie.id,
                                    videoUrl:
                                        widget.service.getStreamUrl(movie.id),
                                    title: movie.name,
                                    service: widget.service,
                                    jellyfinItem: movie,
                                  ),
                                ),
                              );
                            },
                            rating: movie.rating,
                            posterUrl: movie.imageUrl != null
                                ? widget.service.getImageUrl(movie.imageUrl)
                                : null,
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
