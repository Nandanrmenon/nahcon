import 'package:flutter/material.dart';
import 'package:nahcon/screens/video_screen.dart';

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
    return Scaffold(
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([_seriesDetailsFuture, _seasonsFuture]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final seriesDetails = snapshot.data![0] as JellyfinItem;
          final seasons = snapshot.data![1] as List<JellyfinItem>;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: widget.series.imageUrl != null
                      ? Image.network(
                          widget.service.getImageUrl(widget.series.imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
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
                          Text(
                            widget.series.name,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                children: [
                                  if (seriesDetails.officialRating != null)
                                    Chip(
                                      avatar: Icon(
                                        Icons.family_restroom,
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
                                      avatar: const Icon(Icons.star,
                                          color: Colors.amber, size: 18),
                                      label: Text(widget.series.rating!
                                          .toStringAsFixed(1)),
                                    ),
                                  if (seriesDetails.runtime != null)
                                    Chip(
                                      avatar: Icon(
                                        Icons.timer_outlined,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        size: 18,
                                      ),
                                      label:
                                          Text('${seriesDetails.runtime} min'),
                                    ),
                                ],
                              ),
                              if (seriesDetails.genres != null)
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
                                  child: Text(
                                      _selectedSeason?.name ?? 'Select Season'),
                                ),
                              ),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: episodes.length,
                                itemBuilder: (context, index) {
                                  final episode = episodes[index];
                                  return Container(
                                    color: index.isEven
                                        ? Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerLowest
                                        : Theme.of(context).colorScheme.surface,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8, horizontal: 16),
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => VideoScreen(
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
                                                  widget.service.getImageUrl(
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
                                                      Icons.play_circle_fill,
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
                                                if (episode.overview != null)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 4.0),
                                                    child: Text(
                                                      episode.overview!,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall,
                                                    ),
                                                  ),
                                                if (episode.runtime != null)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 2.0),
                                                    child: Text(
                                                      '${episode.runtime} min',
                                                      style: Theme.of(context)
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
                          child: Text(_selectedSeason?.name ?? 'Select Season'),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
