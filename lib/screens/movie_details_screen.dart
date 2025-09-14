import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:nahcon/widgets/m_list.dart';
import 'package:nahcon/widgets/movie_card.dart';

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
            tag: 'movie-poster-desktop-${widget.movie.id}',
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

          final content = Padding(
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.movie.name,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          if (movieDetails.year != null)
                            Text(
                              widget.movie.year.toString(),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant),
                            ),
                        ],
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
                              color: Theme.of(context).colorScheme.primary,
                              size: 18,
                            ),
                            label: Text(movieDetails.officialRating!),
                          ),
                        if (widget.movie.rating != null)
                          Chip(
                            avatar: const Icon(Symbols.star_rounded,
                                color: Colors.amber, size: 18),
                            label:
                                Text(widget.movie.rating!.toStringAsFixed(1)),
                          ),
                        if (movieDetails.runtime != null)
                          Chip(
                            avatar: Icon(
                              Symbols.timer_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 18,
                            ),
                            label: Text('${movieDetails.runtime} min'),
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
                    SizedBox(
                      height: 8,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        movieDetails.overview ?? 'No Description',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    SizedBox(
                      height: 8,
                    ),
                    MListHeader(title: 'Media Info'),
                    ...?(movieDetails.mediaSources?.map((source) {
                      final video = source.streams?.firstWhere(
                        (s) => s.type == 'Video',
                        orElse: () => MediaStream(),
                      );

                      final audio = source.streams?.firstWhere(
                        (s) => s.type == 'Audio',
                        orElse: () => MediaStream(),
                      );

                      final resolution =
                          video?.width != null && video?.height != null
                              ? "${video!.width}x${video.height}"
                              : "Unknown res";

                      final hdr = video?.videoRange ?? "SDR";
                      final codec = video?.codec ?? "Unknown codec";
                      final audioLang = audio?.language ?? "Unknown audio";
                      final displayTitle =
                          video?.displayTitle?.split(' ').first ?? "Unknown";

                      return MListView(
                        // spacing: 4.0,
                        items: [
                          MListItemData(
                            title: displayTitle.toUpperCase(),
                            subtitle: 'Resolution',
                            onTap: () async {},
                          ),
                          MListItemData(
                            title: codec.toUpperCase(),
                            subtitle: 'Codec',
                            onTap: () async {},
                          ),
                          MListItemData(
                            title: audioLang.toUpperCase(),
                            subtitle: 'Language',
                            onTap: () async {},
                          ),
                          MListItemData(
                            title: hdr.toUpperCase(),
                            subtitle: 'Video',
                            onTap: () async {},
                          ),
                        ],
                      );
                    })),
                  ],
                ),
                Text(
                  'More Like This',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(
                  height: 250,
                  child: FutureBuilder<List<JellyfinItem>>(
                    future: widget.service.getSimilarItems(widget.movie.id),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const SizedBox.shrink();
                      }
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final movie = snapshot.data![index];
                          // return Container(
                          //   width: 120,
                          //   margin: const EdgeInsets.only(right: 8),
                          //   child: InkWell(
                          //     onTap: () {
                          //       Navigator.push(
                          //         context,
                          //         MaterialPageRoute(
                          //           builder: (context) => MovieDetailsScreen(
                          //             movie: movie,
                          //             service: widget.service,
                          //           ),
                          //         ),
                          //       );
                          //     },
                          //     child: Column(
                          //       crossAxisAlignment: CrossAxisAlignment.start,
                          //       children: [
                          //         if (movie.imageUrl != null)
                          //           Expanded(
                          //             child: ClipRRect(
                          //               borderRadius: BorderRadius.circular(8),
                          //               child: Image.network(
                          //                 widget.service
                          //                     .getImageUrl(movie.imageUrl),
                          //                 fit: BoxFit.cover,
                          //                 width: double.infinity,
                          //                 height: 250,
                          //               ),
                          //             ),
                          //           ),
                          //         Padding(
                          //           padding: const EdgeInsets.all(8.0),
                          //           child: Text(
                          //             movie.name,
                          //             maxLines: 1,
                          //             overflow: TextOverflow.ellipsis,
                          //             style: Theme.of(context)
                          //                 .textTheme
                          //                 .bodyMedium,
                          //           ),
                          //         ),
                          //       ],
                          //     ),
                          //   ),
                          // );
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
                            posterUrl: movie.imageUrl != null
                                ? widget.service.getImageUrl(movie.imageUrl)
                                : null,
                            rating: movie.rating,
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          );

          return isDesktop
              ? Scaffold(
                  appBar: AppBar(
                    leading: IconButton.filledTonal(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: Icon(Symbols.arrow_back)),
                    backgroundColor: Colors.transparent,
                  ),
                  extendBodyBehindAppBar: true,
                  body: SingleChildScrollView(
                    child: Column(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            AspectRatio(
                              aspectRatio: 21 / 9,
                              child: FutureBuilder<List<String>>(
                                future: widget.service
                                    .getBackdropUrls(widget.movie.id),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData ||
                                      snapshot.data!.isEmpty) {
                                    return widget.movie.imageUrl != null
                                        ? ClipRect(
                                            child: ImageFiltered(
                                              imageFilter: ImageFilter.blur(
                                                  tileMode: TileMode.mirror,
                                                  sigmaY: 5,
                                                  sigmaX: 5),
                                              child: Image.network(
                                                widget.service.getImageUrl(
                                                    widget.movie.imageUrl),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          )
                                        : const SizedBox.shrink();
                                  }
                                  return _BackdropCarousel(
                                    imageUrls: snapshot.data!,
                                  );
                                },
                              ),
                            ),
                            Positioned(
                              bottom: -80,
                              left: 20,
                              child: SizedBox(
                                  width: 300,
                                  child: Center(
                                      child: Material(
                                    elevation: 8.0,
                                    child: AspectRatio(
                                        aspectRatio: 9 / 16, child: poster),
                                  ))),
                            ),
                            Positioned(
                              bottom: -100,
                              right: 20,
                              child: Column(
                                spacing: 16.0,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Hero(
                                    tag: 'movie-title-${widget.movie.id}',
                                    child: Material(
                                      type: MaterialType.transparency,
                                      child: Text(
                                        widget.movie.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    child: FilledButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => VideoScreen(
                                              itemId: widget.movie.id,
                                              videoUrl: widget.service
                                                  .getStreamUrl(
                                                      widget.movie.id),
                                              title: widget.movie.name,
                                              service: widget.service,
                                              jellyfinItem: movieDetails,
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Symbols.play_arrow),
                                      label: const Text('Play'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 80,
                        ),
                        content,
                      ],
                    ),
                  ),
                )
              : Scaffold(
                  body: CustomScrollView(
                    slivers: [
                      SliverAppBar(
                        expandedHeight: 500,
                        pinned: true,
                        leading: isDesktop
                            ? Container()
                            : IconButton.filledTonal(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                icon: Icon(Symbols.arrow_back)),
                        flexibleSpace: FlexibleSpaceBar(
                          background: Hero(
                            tag: 'movie-poster-mobile-${widget.movie.id}',
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (widget.movie.imageUrl != null && !isDesktop)
                                  Image.network(
                                    widget.service
                                        .getImageUrl(widget.movie.imageUrl),
                                    fit: BoxFit.cover,
                                  ),
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
                      SliverToBoxAdapter(child: content),
                    ],
                  ),
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
                                      itemId: widget.movie.id,
                                      videoUrl: widget.service
                                          .getStreamUrl(widget.movie.id),
                                      title: widget.movie.name,
                                      service: widget.service,
                                      jellyfinItem: movieDetails,
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
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999.0)),
                              ),
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
        return ClipRect(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaY: 5,
              sigmaX: 5,
              tileMode: TileMode.mirror,
            ),
            child: Image.network(
              widget.imageUrls[index],
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }
}
