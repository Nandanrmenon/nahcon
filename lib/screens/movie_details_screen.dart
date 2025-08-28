import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

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
    final isDesktop = MediaQuery.of(context).size.width > 600;

    final poster = widget.movie.imageUrl != null
        ? Hero(
            tag:
                'movie-poster-desktop-${widget.movie.id}', // Changed tag for desktop
            child: CachedNetworkImage(
              imageUrl: widget.service.getImageUrl(widget.movie.imageUrl),
              fit: BoxFit.cover,
              width: double.infinity,
              height: 600,
            ),
          )
        : const SizedBox.shrink();

    return Scaffold(
      body: FutureBuilder<JellyfinItem>(
        future: _movieDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Symbols.error_outline, size: 48),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        _movieDetailsFuture = _fetchMovieDetails();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final movieDetails = snapshot.data;
          if (movieDetails == null) {
            return const Center(
              child: Text('No movie details available'),
            );
          }

          final content = Stack(
            children: [
              // Backdrop and Content
              CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 500,
                    pinned: true,
                    leading: isDesktop ? Container() : BackButton(),
                    backgroundColor: Colors.black38,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Hero(
                        tag:
                            'movie-poster-mobile-${widget.movie.id}', // Changed tag for mobile
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (widget.movie.imageUrl != null && !isDesktop)
                              Image.network(
                                widget.service
                                    .getImageUrl(widget.movie.imageUrl),
                                fit: BoxFit.cover,
                              ),
                            if (isDesktop)
                              FutureBuilder<List<String>>(
                                future: widget.service
                                    .getBackdropUrls(widget.movie.id),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData ||
                                      snapshot.data!.isEmpty) {
                                    // fallback to poster if no backdrops
                                    return widget.movie.imageUrl != null
                                        ? Image.network(
                                            widget.service.getImageUrl(
                                                widget.movie.imageUrl),
                                            fit: BoxFit.cover,
                                          )
                                        : const SizedBox.shrink();
                                  }
                                  return _BackdropCarousel(
                                    imageUrls: snapshot.data!,
                                  );
                                },
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
                          if (!isDesktop)
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
                                runSpacing: 8.0,
                                children: [
                                  if (movieDetails.officialRating != null)
                                    Chip(
                                      avatar: Icon(
                                        Symbols.family_restroom_rounded,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        size: 18,
                                      ),
                                      label: Text(movieDetails.officialRating!),
                                    ),
                                  if (widget.movie.rating != null)
                                    Chip(
                                      avatar: const Icon(Symbols.star_rounded,
                                          color: Colors.amber, size: 18),
                                      label: Text(widget.movie.rating!
                                          .toStringAsFixed(1)),
                                    ),
                                  if (movieDetails.runtime != null)
                                    Chip(
                                      avatar: Icon(
                                        Symbols.timer_rounded,
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
                                if (!snapshot.hasData) {
                                  return const SizedBox.shrink();
                                }
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

          return isDesktop
              ? Scaffold(
                  body: Row(
                    children: [
                      SingleChildScrollView(
                        child: Material(
                          child: SizedBox(
                              width: 400,
                              child: Column(
                                children: [
                                  AppBar(),
                                  Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0, vertical: 8.0),
                                        child: Material(child: poster),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0, vertical: 8.0),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          spacing: 16.0,
                                          children: [
                                            Expanded(
                                              child: Hero(
                                                tag:
                                                    'movie-title-${widget.movie.id}',
                                                child: Material(
                                                  type:
                                                      MaterialType.transparency,
                                                  child: Text(
                                                    widget.movie.name,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .headlineSmall,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: FilledButton.icon(
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          VideoScreen(
                                                        videoUrl: widget.service
                                                            .getStreamUrl(widget
                                                                .movie.id),
                                                        title:
                                                            widget.movie.name,
                                                        service: widget.service,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                icon: const Icon(
                                                    Symbols.play_arrow),
                                                label: const Text('Play'),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )),
                        ),
                      ),
                      Expanded(child: content),
                    ],
                  ),
                )
              : Scaffold(
                  body: content,
                  bottomNavigationBar: BottomAppBar(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      spacing: 8,
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: FilledButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => VideoScreen(
                                      videoUrl: widget.service
                                          .getStreamUrl(widget.movie.id),
                                      title: widget.movie.name,
                                      service: widget.service,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Symbols.play_arrow),
                              label: const Text('Play'),
                            ),
                          ),
                        ),
                        Tooltip(
                          message: 'Watch Later',
                          child: SizedBox(
                            height: 48,
                            child: FilledButton.tonal(
                              onPressed: () {
                                debugPrint('watch later pressed');
                              },
                              child: const Icon(Symbols.watch_later_rounded),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
        },
      ),
    );
  }
}

class _BackdropCarousel extends StatefulWidget {
  final List<String> imageUrls;

  const _BackdropCarousel({required this.imageUrls});

  @override
  State<_BackdropCarousel> createState() => _BackdropCarouselState();
}

class _BackdropCarouselState extends State<_BackdropCarousel> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Auto-scroll
    Future.delayed(const Duration(seconds: 5), _nextPage);
  }

  void _nextPage() {
    if (!mounted) return;
    final nextPage = (_currentPage + 1) % widget.imageUrls.length;
    _pageController.animateToPage(
      nextPage,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
    );
    Future.delayed(const Duration(seconds: 5), _nextPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) => setState(() => _currentPage = index),
      itemCount: widget.imageUrls.length,
      itemBuilder: (context, index) {
        return Image.network(
          widget.imageUrls[index],
          fit: BoxFit.cover,
        );
      },
    );
  }
}
