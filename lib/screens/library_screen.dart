import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:nahcon/screens/movie_details_screen.dart';
import 'package:nahcon/widgets/movie_card.dart';

import '../models/jellyfin_item.dart';
import '../services/jellyfin_service.dart';

class LibraryScreen extends StatefulWidget {
  final JellyfinService service;

  const LibraryScreen({super.key, required this.service});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: isDesktop
          ? PreferredSize(
              preferredSize: Size.zero,
              child: Container(),
            )
          : AppBar(title: const Text('Jellyfin')),
      body: Padding(
        padding: isDesktop
            ? EdgeInsets.zero
            : EdgeInsets.symmetric(horizontal: 16.0),
        child: CustomScrollView(
          slivers: [
            // Continue Playing Section
            SliverToBoxAdapter(
              child: ListTile(
                leading: const Icon(Symbols.resume_rounded),
                title: Text(
                  'Continue Playing',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),

            FutureBuilder<List<JellyfinItem>>(
              future: widget.service.getContinuePlaying(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  final items = snapshot.data!;
                  return SliverToBoxAdapter(
                    child: SizedBox(
                      height: 250,
                      child: CarouselView(
                        itemExtent: 350,
                        shrinkExtent: 0.8,
                        itemSnapping: true,
                        enableSplash: false,
                        children: items.map((item) {
                          return Material(
                            borderRadius: BorderRadius.circular(8.0),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () {
                                if (isDesktop) {
                                  showModalBottomSheet(
                                    context: context,
                                    scrollControlDisabledMaxHeightRatio: 0.9,
                                    constraints: BoxConstraints(minWidth: 300, maxWidth: 1200),
                                    clipBehavior: Clip.antiAlias,
                                    builder: (context) => Center(
                                      child: MovieDetailsScreen(
                                        movie: item,
                                        service: widget.service,
                                      ),
                                    ),
                                  );
                                } else {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => MovieDetailsScreen(
                                        movie: item,
                                        service: widget.service,
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (item.imageUrl != null)
                                    Expanded(
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image.network(
                                            widget.service
                                                .getImageUrl(item.imageUrl),
                                            fit: BoxFit.cover,
                                          ),
                                          Positioned(
                                            top: 0,
                                            left: 0,
                                            right: 0,
                                            bottom: 0,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.transparent,
                                                    Colors.black87,
                                                  ],
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                ),
                                              ),
                                              width: double.infinity,
                                              height: double.infinity,
                                            ),
                                          ),
                                          Positioned(
                                            top: 0,
                                            left: 0,
                                            right: 0,
                                            bottom: 0,
                                            child: Center(
                                              child: CircleAvatar(
                                                backgroundColor: Colors.black54,
                                                child: Icon(
                                                    Symbols.play_arrow_rounded,
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 40,
                                            left: 20,
                                            right: 20,
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    item.name,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium!
                                                        .copyWith(
                                                            color:
                                                                Colors.white),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 20,
                                            left: 20,
                                            right: 20,
                                            child: LinearProgressIndicator(
                                              value: item.playbackProgress,
                                              minHeight: 4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    const Expanded(
                                      child: Icon(Symbols.movie, size: 48),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  );
                }
                return const SliverToBoxAdapter(child: SizedBox());
              },
            ),
            // Next Up Section
            SliverToBoxAdapter(
              child: ListTile(
                leading: const Icon(Symbols.skip_next),
                title: Text(
                  'Next Up',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
            FutureBuilder<List<JellyfinItem>>(
              future: widget.service.getNextUp(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  final items = snapshot.data!;
                  return SliverToBoxAdapter(
                    child: SizedBox(
                      height: 250,
                      child: CarouselView(
                        itemExtent: 350,
                        shrinkExtent: 0.8,
                        itemSnapping: true,
                        enableSplash: false,
                        children: items.map((item) {
                          return Material(
                            borderRadius: BorderRadius.circular(8.0),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () {
                                if (isDesktop) {
                                  showModalBottomSheet(
                                    context: context,
                                    scrollControlDisabledMaxHeightRatio: 0.9,
                                    constraints: BoxConstraints(minWidth: 300, maxWidth: 1200),
                                    clipBehavior: Clip.antiAlias,
                                    builder: (context) => Center(
                                      child: MovieDetailsScreen(
                                        movie: item,
                                        service: widget.service,
                                      ),
                                    ),
                                  );
                                } else {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => MovieDetailsScreen(
                                        movie: item,
                                        service: widget.service,
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (item.imageUrl != null)
                                    Expanded(
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image.network(
                                            widget.service
                                                .getImageUrl(item.imageUrl),
                                            fit: BoxFit.cover,
                                          ),
                                          Positioned(
                                            top: 0,
                                            left: 0,
                                            right: 0,
                                            bottom: 0,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.transparent,
                                                    Colors.black87,
                                                  ],
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                ),
                                              ),
                                              width: double.infinity,
                                              height: double.infinity,
                                            ),
                                          ),
                                          Positioned(
                                            top: 0,
                                            left: 0,
                                            right: 0,
                                            bottom: 0,
                                            child: Center(
                                              child: CircleAvatar(
                                                backgroundColor: Colors.black54,
                                                child: Icon(
                                                    Symbols.play_arrow_rounded,
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 20,
                                            left: 20,
                                            right: 20,
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    item.name,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium!
                                                        .copyWith(
                                                            color:
                                                                Colors.white),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    const Expanded(
                                      child: Icon(Symbols.movie, size: 48),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  );
                }
                return const SliverToBoxAdapter(child: SizedBox());
              },
            ),
            SliverToBoxAdapter(
              child: ListTile(
                leading: const Icon(Symbols.shuffle_rounded),
                title: Text(
                  'Suggestions',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
            FutureBuilder<List<JellyfinItem>>(
              future: widget.service.getSuggestions(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  final items = snapshot.data!;
                  return SliverToBoxAdapter(
                    child: SizedBox(
                      height: 300,
                      child: CarouselView(
                        itemExtent: 200,
                        shrinkExtent: 0.8,
                        itemSnapping: true,
                        enableSplash: false,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        children: items.map((item) {
                          return MovieCard(
                            title: item.name,
                            posterUrl: item.imageUrl != null
                                ? widget.service.getImageUrl(item.imageUrl)
                                : null,
                            rating: item.rating,
                            onTap: () {
                              if (isDesktop) {
                                showModalBottomSheet(
                                  context: context,
                                  scrollControlDisabledMaxHeightRatio: 0.9,
                                  constraints: BoxConstraints(minWidth: 300, maxWidth: 1200),
                                  clipBehavior: Clip.antiAlias,
                                  builder: (context) => Center(
                                    child: MovieDetailsScreen(
                                      movie: item,
                                      service: widget.service,
                                    ),
                                  ),
                                );
                              } else {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => MovieDetailsScreen(
                                      movie: item,
                                      service: widget.service,
                                    ),
                                  ),
                                );
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  );
                }
                return const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
