import 'package:flutter/material.dart';
import 'package:nahcon/screens/movie_details_screen.dart';
import 'package:nahcon/widgets/movie_card.dart';

import '../models/jellyfin_item.dart';
import '../services/jellyfin_service.dart';

class LibraryScreen extends StatelessWidget {
  final JellyfinService service;

  const LibraryScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      appBar: isDesktop
          ? PreferredSize(
              preferredSize: Size.zero,
              child: Container(),
            )
          : AppBar(title: const Text('Jellyfin')),
      body: CustomScrollView(
        slivers: [
          // Continue Playing Section
          SliverToBoxAdapter(
            child: ListTile(
              leading: const Icon(Icons.play_circle_outline),
              title: Text(
                'Next Up',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ),
          FutureBuilder<List<JellyfinItem>>(
            future: service.getNextUp(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                final items = snapshot.data!;
                return SliverToBoxAdapter(
                  child: SizedBox(
                    height: 250,
                    child: CarouselView(
                      itemExtent: 350, // width of each carousel item
                      shrinkExtent: 0.8, // optional: shrink side items
                      itemSnapping: true,
                      children: items.map((item) {
                        return Material(
                          borderRadius: BorderRadius.circular(8.0),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => MovieDetailsScreen(
                                    movie: item,
                                    service: service,
                                  ),
                                ),
                              );
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
                                          service.getImageUrl(item.imageUrl),
                                          fit: BoxFit.cover,
                                        ),
                                        const Positioned(
                                          bottom: 8,
                                          right: 8,
                                          child: CircleAvatar(
                                            backgroundColor: Colors.black54,
                                            child: Icon(Icons.play_arrow,
                                                color: Colors.white),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 20,
                                          left: 20,
                                          child: Text(
                                            item.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium!
                                                .copyWith(color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  const Expanded(
                                    child: Icon(Icons.movie, size: 48),
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
              leading: const Icon(Icons.shuffle),
              title: Text(
                'Random',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ),
          // FutureBuilder<List<JellyfinItem>>(
          //   future: service.getRandomMovies(),
          //   builder: (context, snapshot) {
          //     if (snapshot.hasData) {
          //       return SliverToBoxAdapter(
          //         child: SizedBox(
          //           height: 350,
          //           child: ListView.builder(
          //             scrollDirection: Axis.horizontal,
          //             itemCount: snapshot.data!.length,
          //             itemBuilder: (context, index) {
          //               final item = snapshot.data![index];
          //               return Container(
          //                 margin: const EdgeInsets.symmetric(horizontal: 8.0),
          //                 width: 250,
          //                 child: MovieCard(
          //                   title: item.name,
          //                   posterUrl: item.imageUrl != null
          //                       ? service.getImageUrl(item.imageUrl)
          //                       : null,
          //                   rating: item.rating,
          //                   onTap: () {
          //                     Navigator.of(context).push(
          //                       MaterialPageRoute(
          //                         builder: (context) => MovieDetailsScreen(
          //                           movie: item,
          //                           service: service,
          //                         ),
          //                       ),
          //                     );
          //                   },
          //                 ),
          //               );
          //             },
          //           ),
          //         ),
          //       );
          //     }
          //     return const SliverToBoxAdapter(
          //       child: Center(child: CircularProgressIndicator()),
          //     );
          //   },
          // ),
          FutureBuilder<List<JellyfinItem>>(
            future: service.getRandomMovies(),
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
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      children: items.map((item) {
                        return MovieCard(
                          title: item.name,
                          posterUrl: item.imageUrl != null
                              ? service.getImageUrl(item.imageUrl)
                              : null,
                          rating: item.rating,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => MovieDetailsScreen(
                                  movie: item,
                                  service: service,
                                ),
                              ),
                            );
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
    );
  }
}
