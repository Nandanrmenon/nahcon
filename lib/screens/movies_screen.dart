import 'package:flutter/material.dart';
import 'package:nahcon/screens/movie_details_screen.dart';
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

  // void _showFilterSheet() {
  //   showModalBottomSheet(
  //     context: context,
  //     showDragHandle: true,
  //     builder: (context) => FutureBuilder<List<String>>(
  //       future: widget.service.getMovieGenres(),
  //       builder: (context, snapshot) {
  //         if (!snapshot.hasData) {
  //           return const Center(child: CircularProgressIndicator());
  //         }
  //         return ListView.builder(
  //           itemCount: snapshot.data!.length + 1,
  //           itemBuilder: (context, index) {
  //             final isAll = index == 0;
  //             final genre = isAll ? 'All' : snapshot.data![index - 1];
  //             final isSelected =
  //                 isAll ? selectedGenre == null : genre == selectedGenre;

  //             return ListTile(
  //               trailing: isSelected ? const Icon(Icons.check) : null,
  //               title: Text(genre),
  //               onTap: () {
  //                 setState(() {
  //                   selectedGenre = isAll ? null : genre;
  //                   _isLoading = true;
  //                 });
  //                 Navigator.pop(context);
  //               },
  //             );
  //           },
  //         );
  //       },
  //     ),
  //   );
  // }

  Future<void> _fetchGenres() async {
    final genres = await widget.service.getMovieGenres();
    setState(() {
      _genres = genres;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   elevation: 0,
      //   scrolledUnderElevation: 0,
      //   centerTitle: false,
      //   // title: ElevatedButton.icon(
      //   //   iconAlignment: IconAlignment.end,
      //   //   icon: const Icon(Icons.arrow_drop_down),
      //   //   label: Text(
      //   //     selectedGenre ?? 'All ',
      //   //   ),
      //   //   onPressed: _showFilterSheet,
      //   // ),
      //   // bottom: PreferredSize(preferredSize: preferredSize, child: child),
      // ),
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
                    key: ValueKey(
                        selectedGenre), // Force rebuild on genre change
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
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MovieDetailsScreen(
                                    movie: movie,
                                    service: widget.service,
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
