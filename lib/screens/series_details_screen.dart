import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:nahcon/screens/video_screen.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../models/jellyfin_item.dart';
import '../services/jellyfin_service.dart';

class SeriesDetailsScreen extends StatefulWidget {
  final JellyfinItem series;
  final JellyfinService service;

  const SeriesDetailsScreen({
    super.key,
    required this.series,
    required this.service,
  });

  @override
  State<SeriesDetailsScreen> createState() => _SeriesDetailsScreenState();
}

class _SeriesDetailsScreenState extends State<SeriesDetailsScreen> {
  late Future<JellyfinItem> _seriesDetailsFuture;
  late Future<List<JellyfinItem>> _seasonsFuture;
  JellyfinItem? _selectedSeason;

  @override
  void initState() {
    super.initState();
    _seriesDetailsFuture = widget.service.getItemDetails(widget.series.id);
    _seasonsFuture =
        widget.service.getSeasons(widget.series.id).then((seasons) {
      if (seasons.isNotEmpty) {
        _selectedSeason = seasons.first;
      }
      return seasons;
    });
  }

  void _showSeasonPicker(List<JellyfinItem> seasons) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => ListView.builder(
        shrinkWrap: true,
        itemCount: seasons.length,
        itemBuilder: (context, index) {
          final season = seasons[index];
          return ListTile(
            selected: season.id == _selectedSeason?.id,
            title: Text(season.name),
            onTap: () {
              setState(() => _selectedSeason = season);
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;

    final poster = Hero(
      tag: 'series-poster-${widget.series.id}',
      child: widget.series.imageUrl != null
          ? Image.network(
              widget.service.getImageUrl(widget.series.imageUrl),
              fit: BoxFit.cover,
            )
          : const Center(child: Icon(Symbols.tv, size: 48)),
    );

    final content = FutureBuilder<List<dynamic>>(
      future: Future.wait([_seriesDetailsFuture, _seasonsFuture]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final seriesDetails = snapshot.data![0] as JellyfinItem;
        final seasons = snapshot.data![1] as List<JellyfinItem>;
        return Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 500,
                  pinned: true,
                  leading: isDesktop ? Container() : IconButton.filledTonal(onPressed: (){Navigator.pop(context);}, icon: Icon(Symbols.arrow_back)),
                  // backgroundColor: Colors.black38,
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.parallax,
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (widget.series.imageUrl != null && !isDesktop)
                          Image.network(
                            widget.service.getImageUrl(widget.series.imageUrl),
                            fit: BoxFit.cover,
                          ),
                        if (isDesktop)
                          FutureBuilder<List<String>>(
                            future: widget.service
                                .getBackdropUrls(widget.series.id),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return widget.series.imageUrl != null
                                    ? Image.network(
                                        widget.service.getImageUrl(
                                            widget.series.imageUrl),
                                        fit: BoxFit.cover,
                                      )
                                    : const SizedBox.shrink();
                              }
                              return _BackdropCarousel(
                                  imageUrls: snapshot.data!);
                            },
                          ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.center,
                              colors: [Colors.black54, Colors.transparent],
                            ),
                          ),
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black87],
                              stops: [0.6, 1.0],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 16,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.series.name,
                                  style:
                                      Theme.of(context).textTheme.headlineSmall,
                                ),
                                Text(
                                  widget.series.year.toString(),
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 8,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8.0,
                                  children: [
                                    if (seriesDetails.officialRating != null)
                                      Chip(
                                        avatar: Icon(
                                          Symbols.family_restroom,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          size: 18,
                                        ),
                                        label:
                                            Text(seriesDetails.officialRating!),
                                      ),
                                    if (widget.series.rating != null)
                                      Chip(
                                        avatar: const Icon(Symbols.star,
                                            color: Colors.amber, size: 18),
                                        label: Text(widget.series.rating!
                                            .toStringAsFixed(1)),
                                      ),
                                    if (seriesDetails.runtime != null)
                                      Chip(
                                        avatar: Icon(
                                          Symbols.timer_rounded,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          size: 18,
                                        ),
                                        label: Text(
                                            '${seriesDetails.runtime} min'),
                                      ),
                                  ],
                                ),
                                Wrap(
                                  spacing: 8,
                                  children: seriesDetails.genres
                                          ?.map((genre) => Chip(
                                                label: Text(genre),
                                                backgroundColor:
                                                    Theme.of(context)
                                                        .colorScheme
                                                        .surfaceContainer,
                                              ))
                                          .toList() ??
                                      [],
                                ),
                              ],
                            ),
                            Text(
                              seriesDetails.overview ??
                                  'No description available',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      if (_selectedSeason != null)
                        FutureBuilder<List<JellyfinItem>>(
                          future: widget.service.getEpisodes(
                            widget.series.id,
                            _selectedSeason!.id,
                          ),
                          builder: (context, episodeSnapshot) {
                            if (!episodeSnapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            final episodes = episodeSnapshot.data!;
                            return Column(
                              children: [
                                ListTile(
                                  // contentPadding: const EdgeInsets.symmetric(
                                  //     horizontal: 16.0),
                                  title: Text(
                                    'Episodes: ${episodes.length}',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  trailing: TextButton(
                                    onPressed: () => _showSeasonPicker(seasons),
                                    child: Text(_selectedSeason?.name ??
                                        'Select Season'),
                                  ),
                                ),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: episodes.length,
                                  itemBuilder: (context, index) {
                                    final episode = episodes[index];
                                    return Skeletonizer(
                                      enabled: episode.imageUrl == null,
                                      child: Container(
                                        color: index.isEven
                                            ? Theme.of(context)
                                                .colorScheme
                                                .surfaceContainerLowest
                                            : Theme.of(context)
                                                .colorScheme
                                                .surface,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8, horizontal: 16),
                                        child: InkWell(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    VideoScreen(
                                                  itemId: widget.series.id,
                                                  videoUrl: widget.service
                                                      .getStreamUrl(episode.id),
                                                  title: episode.name,
                                                  service: widget.service,
                                                ),
                                              ),
                                            );
                                          },
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: 24,
                                                child: Text(
                                                  '${index + 1}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium!
                                                      .copyWith(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onInverseSurface,
                                                      ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              if (episode.imageUrl != null)
                                                Stack(
                                                  alignment: Alignment.center,
                                                  children: [
                                                    Image.network(
                                                      widget.service
                                                          .getImageUrl(
                                                        episode.imageUrl,
                                                      ),
                                                      width: 100,
                                                      height: 60,
                                                      fit: BoxFit.cover,
                                                    ),
                                                    Container(
                                                      width: 100,
                                                      height: 60,
                                                      color: Colors.black12,
                                                      child: const Center(
                                                        child: Icon(
                                                          Icons
                                                              .play_circle_fill,
                                                          color: Colors.white60,
                                                          size: 36,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      episode.name,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleSmall,
                                                    ),
                                                    if (episode.overview !=
                                                        null)
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(top: 4.0),
                                                        child: Text(
                                                          episode.overview!,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodySmall,
                                                        ),
                                                      ),
                                                    if (episode.runtime != null)
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(top: 2.0),
                                                        child: Text(
                                                          '${episode.runtime} min',
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodySmall,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                      // If no season is selected, show the season picker button
                      if (_selectedSeason == null)
                        ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16.0),
                          title: Text(
                            'Episodes: 0',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          trailing: TextButton(
                            onPressed: () => _showSeasonPicker(seasons),
                            child:
                                Text(_selectedSeason?.name ?? 'Select Season'),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    return isDesktop
        ? Scaffold(
            body: Row(
              children: [
                Material(
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
                                        tag: 'movie-title-${widget.series.id}',
                                        child: Material(
                                          type: MaterialType.transparency,
                                          child: Text(
                                            widget.series.name,
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
                                              builder: (context) => VideoScreen(
                                                itemId: widget.series.id,
                                                videoUrl: widget.service
                                                    .getStreamUrl(
                                                        widget.series.id),
                                                title: widget.series.name,
                                                service: widget.service,
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
                        ],
                      )),
                ),
                Expanded(child: content),
              ],
            ),
          )
        : Scaffold(
            body: content,
          );
  }
}

// Add BackdropCarousel class from MovieDetailsScreen
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
    if (widget.imageUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          onPageChanged: (index) => setState(() => _currentPage = index),
          itemCount: widget.imageUrls.length,
          itemBuilder: (context, index) {
            final url = widget.imageUrls[index];
            if (url.isEmpty) return const SizedBox.shrink();

            return Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                print('Error loading image: $error');
                return const Center(child: Icon(Symbols.error));
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
            );
          },
        ),
        // Overlay gradients for better visibility
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black45,
                  Colors.transparent,
                  Colors.black87,
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
