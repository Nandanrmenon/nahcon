import 'package:flutter/material.dart';

import '../models/jellyfin_item.dart';
import '../services/jellyfin_service.dart';
import 'video_screen.dart';

class MovieDetailsScreen extends StatefulWidget {
  final JellyfinItem movie;
  final JellyfinService service;

  const MovieDetailsScreen({
    super.key,
    required this.movie,
    required this.service,
  });

  @override
  _MovieDetailsState createState() => _MovieDetailsState();
}

class _MovieDetailsState extends State<MovieDetailsScreen> {
  late Future<JellyfinItem> _movieDetailsFuture;
  JellyfinItem? _cachedDetails;

  @override
  void initState() {
    super.initState();
    _movieDetailsFuture = _fetchMovieDetails();
  }

  Future<JellyfinItem> _fetchMovieDetails() async {
    if (_cachedDetails != null) return _cachedDetails!;

    try {
      final details = await widget.service.getItemDetails(widget.movie.id);
      _cachedDetails = details;
      return details;
    } catch (e) {
      // Try to reauthorize and fetch again
      if (await widget.service.tryAutoLogin()) {
        return await widget.service.getItemDetails(widget.movie.id);
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<JellyfinItem>(
        future: _movieDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final movieDetails = snapshot.data!;
          return Stack(
            children: [
              // Backdrop and Content
              CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 400,
                    pinned: true,
                    leading: Container(),
                    backgroundColor: Colors.black38,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Hero(
                        tag: 'movie-poster-${widget.movie.id}',
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (widget.movie.imageUrl != null)
                              Image.network(
                                widget.service
                                    .getImageUrl(widget.movie.imageUrl),
                                fit: BoxFit.cover,
                              ),
                            // Top gradient for better app bar visibility
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.center,
                                  colors: [
                                    Colors.black54,
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            // Bottom gradient for content visibility
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black87,
                                  ],
                                  stops: [0.6, 1.0],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        spacing: 16,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Hero(
                            tag: 'movie-title-${widget.movie.id}',
                            child: Material(
                              type: MaterialType.transparency,
                              child: Text(
                                widget.movie.name,
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
                              ),
                            ),
                          ),
                          // Metadata row
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 8,
                            children: [
                              Wrap(
                                spacing: 8,
                                children: [
                                  if (movieDetails.officialRating != null)
                                    Chip(
                                      avatar: Icon(
                                        Icons.family_restroom,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        size: 18,
                                      ),
                                      label: Text(movieDetails.officialRating!),
                                    ),
                                  if (widget.movie.rating != null)
                                    Chip(
                                      avatar: const Icon(Icons.star,
                                          color: Colors.amber, size: 18),
                                      label: Text(widget.movie.rating!
                                          .toStringAsFixed(1)),
                                    ),
                                  if (movieDetails.runtime != null)
                                    Chip(
                                      avatar: Icon(
                                        Icons.timer_outlined,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        size: 18,
                                      ),
                                      label:
                                          Text('${movieDetails.runtime} min'),
                                    ),
                                ],
                              ),
                              Wrap(
                                spacing: 8,
                                children: movieDetails.genres
                                        ?.map((genre) => Chip(
                                              label: Text(genre),
                                              backgroundColor: Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainer,
                                            ))
                                        .toList() ??
                                    [],
                              ),
                            ],
                          ),
                          Text(
                            movieDetails.overview ?? 'No Description',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            'More Like This',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          SizedBox(
                            height: 250,
                            child: FutureBuilder<List<JellyfinItem>>(
                              future: widget.service
                                  .getSimilarItems(widget.movie.id),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData)
                                  return const SizedBox.shrink();
                                return ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: snapshot.data!.length,
                                  itemBuilder: (context, index) {
                                    final movie = snapshot.data![index];
                                    return Container(
                                      width: 120,
                                      margin: const EdgeInsets.only(right: 8),
                                      child: InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  MovieDetailsScreen(
                                                movie: movie,
                                                service: widget.service,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (movie.imageUrl != null)
                                              Expanded(
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: Image.network(
                                                    widget.service.getImageUrl(
                                                        movie.imageUrl),
                                                    fit: BoxFit.cover,
                                                    width: double.infinity,
                                                    height: 250,
                                                  ),
                                                ),
                                              ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(
                                                movie.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 80), // Space for FAB
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
      floatingActionButton: FilledButton.tonal(
        // elevation: 0,
        onPressed: () {
          Navigator.pop(context);
        },
        // tooltip: 'Back',
        child: const Icon(Icons.arrow_back),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 8,
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VideoScreen(
                        videoUrl: widget.service.getStreamUrl(widget.movie.id),
                        title: widget.movie.name,
                        service: widget.service,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Play'),
              ),
            ),
            IconButton.filledTonal(
              onPressed: () {
                debugPrint('watch later pressed');
              },
              tooltip: 'Watch Later',
              icon: const Icon(Icons.watch_later_outlined),
            ),
          ],
        ),
      ),
    );
  }
}
