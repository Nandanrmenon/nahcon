import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:nahcon/screens/login_screen.dart';
import 'package:nahcon/utils/constants.dart';

import '../models/jellyfin_item.dart';
import '../services/jellyfin_service.dart';
import 'movie_details_screen.dart';

class SettingsScreen extends StatelessWidget {
  final JellyfinService service;

  const SettingsScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: Padding(
        padding: isDesktop ? EdgeInsets.zero : EdgeInsets.symmetric(horizontal: 16.0),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                child: Column(
                  children: [
                    FutureBuilder<bool>(
                      future: service.hasUserImage(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data == true) {
                          return CircleAvatar(
                            radius: 50,
                            backgroundImage: null,
                            child: ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: service.getUserImageUrl(),
                                httpHeaders: service.getVideoHeaders(),
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) =>
                                const Icon(Icons.account_circle, size: 40),
                                placeholder: (context, url) =>
                                const Icon(Icons.account_circle, size: 40),
                              ),
                            ),
                          );
                        }
                        return const Icon(Symbols.account_circle, size: 40);
                      },
                    ),
                    Text(service.username ?? '', style: Theme.of(context).textTheme.titleMedium,),
                    Text(
                      service.serverName ?? service.baseUrl ?? '',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: ListTile(
                leading: const Icon(Symbols.resume_rounded),
                title: Text(
                  'History',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
            FutureBuilder<List<JellyfinItem>>(
              future: service.getHistory(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  final items = snapshot.data!;
                  return SliverToBoxAdapter(
                    child: SizedBox(
                      height: 300,
                      child: CarouselView(
                        itemExtent: 180,
                        shrinkExtent: 0.8,
                        enableSplash: false,
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
                              child:  Column(
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
                                            bottom: 20,
                                            left: 20,
                                            right: 20,
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    item.name,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium!
                                                        .copyWith(
                                                        color: Colors.white),
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
                leading: const Icon(Symbols.delete),
                title: const Text('Clear Cache'),
                onTap: () async {
                  await service.clearCache();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cache cleared')),
                    );
                  }
                },
              ),
            ),
            SliverToBoxAdapter(
              child: ListTile(
                leading: const Icon(Symbols.switch_account),
                title: const Text('Switch User'),
                onTap: () async {
                  await service.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (Route<dynamic> route) => false,
                    );
                  }
                },
              ),
            ),
            SliverToBoxAdapter(
              child: ListTile(
                leading: const Icon(Symbols.logout),
                title: const Text('Logout'),
                onTap: () async {
                  await service.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => LoginScreen(),
                        ),
                        (Route<dynamic> route) => false);
                  }
                },
              ),
            ),
            SliverToBoxAdapter(
              child: const AboutListTile(
                icon: Icon(Symbols.info),
                applicationName: kAppName,
                applicationVersion: kAppVersion,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
