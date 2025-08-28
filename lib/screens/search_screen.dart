import 'package:flutter/material.dart';
import 'package:nahcon/screens/movie_details_screen.dart';
import 'package:nahcon/screens/series_details_screen.dart';
import 'package:nahcon/utils/responsive_grid.dart';

import '../models/jellyfin_item.dart';
import '../services/jellyfin_service.dart';
import '../widgets/movie_card.dart';

class SearchScreen extends StatefulWidget {
  final JellyfinService service;

  const SearchScreen({
    super.key,
    required this.service,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  List<JellyfinItem>? _results;
  bool _isLoading = false;

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() => _results = null);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final results = await widget.service.search(query);
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search movies and TV shows',
            border: InputBorder.none,
            suffixIcon: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _results = null);
                    },
                  ),
          ),
          onChanged: _performSearch,
          textInputAction: TextInputAction.search,
          onSubmitted: _performSearch,
        ),
      ),
      body: _results == null
          ? const Center(
              child: Text('Search for movies and TV shows'),
            )
          : _results!.isEmpty
              ? const Center(
                  child: Text('No results found'),
                )
              : LayoutBuilder(
                  builder: (context, constraints) => GridView.builder(
                    padding: const EdgeInsets.all(ResponsiveGrid.gridSpacing),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: ResponsiveGrid.columnCount(constraints),
                      childAspectRatio: ResponsiveGrid.posterAspectRatio,
                      crossAxisSpacing: ResponsiveGrid.gridSpacing,
                      mainAxisSpacing: ResponsiveGrid.gridSpacing,
                    ),
                    itemCount: _results!.length,
                    itemBuilder: (context, index) {
                      final item = _results![index];
                      return MovieCard(
                        title: item.name,
                        posterUrl: widget.service.getImageUrl(item.imageUrl),
                        rating: item.rating,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => item.type == 'Movie'
                                  ? MovieDetailsScreen(
                                      movie: item, service: widget.service)
                                  : SeriesDetailsScreen(
                                      series: item, service: widget.service),
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
