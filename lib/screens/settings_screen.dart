import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:nahcon/screens/login_screen.dart';
import 'package:nahcon/utils/constants.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/jellyfin_item.dart';
import '../services/jellyfin_service.dart';
import 'movie_details_screen.dart';

class SettingsScreen extends StatelessWidget {
  final JellyfinService service;

  const SettingsScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;

    Future<void> _launchUrl(Uri _url) async {
      if (!await launchUrl(_url)) {
        throw Exception('Could not launch $_url');
      }
    }

    final items = [
      if (UniversalPlatform.isWeb)
        ListItemData(
          title: 'Get the app',
          subtitle:
              'For better experience, use the ${isDesktop ? 'desktop' : 'mobile'} app',
          leading: Icon(Symbols.download),
          onTap: () async {
            await _launchUrl(
                Uri.parse('https://github.com/Nandanrmenon/nahcon/releases'));
          },
        ),
      ListItemData(
        title: 'Github',
        subtitle: 'Check out the source code',
        leading: Icon(Symbols.code),
        onTap: () async {
          await _launchUrl(
              Uri.parse('https://github.com/Nandanrmenon/nahcon/'));
        },
      ),
      ListItemData(
        title: 'Report Issues',
        subtitle: '',
        leading: Icon(Symbols.report_problem),
        onTap: () async {
          await _launchUrl(
              Uri.parse('https://github.com/Nandanrmenon/nahcon/issues'));
        },
      ),
      ListItemData(
        title: 'Support Me',
        subtitle: 'Buy me a coffee',
        leading: Icon(Symbols.money),
        onTap: () async {
          await _launchUrl(Uri.parse('https://ko-fi.com/P5P41KEC9N'));
        },
      ),
      ListItemData(
        title: 'Clear Cache',
        subtitle: 'Helps clear out your storage',
        leading: Icon(Symbols.info),
        onTap: () async {
          await service.clearCache();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cache cleared'),
              ),
            );
          }
        },
      ),
      ListItemData(
        title: 'Logout',
        subtitle: '',
        leading: Icon(Symbols.logout_rounded),
        onTap: () {},
      ),
      ListItemData(
        title: 'Info',
        subtitle: '',
        leading: Icon(Symbols.info_rounded),
        onTap: () {
          showAboutDialog(context: context);
        },
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: isDesktop
              ? EdgeInsets.zero
              : EdgeInsets.symmetric(horizontal: 16.0),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                  child: SizedBox(
                height: 24,
              )),
              SliverToBoxAdapter(
                child: Row(
                  spacing: 24.0,
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
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        spacing: 8.0,
                        children: [
                          Column(
                            spacing: 4.0,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service.username ?? '',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                service.serverName ?? service.baseUrl ?? '',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          FilledButton.tonal(
                              onPressed: () async {
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
                              child: isDesktop
                                  ? Text('Switch Account')
                                  : Icon(Symbols.switch_account))
                        ],
                      ),
                    ),
                  ],
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (item.imageUrl != null)
                                      Expanded(
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            Image.network(
                                              service
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
              SliverList.separated(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  bool _isLastItem(int index) {
                    if (UniversalPlatform.isWeb) {
                      // one item hidden → last index is items.length - 1
                      return index == items.length - 1;
                    } else {
                      // all items visible → last index is still items.length - 1
                      return index == items.length - 1;
                    }
                  }

                  return ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: index == 0
                          ? Radius.circular(16.0)
                          : Radius.circular(4.0),
                      topRight: index == 0
                          ? Radius.circular(16.0)
                          : Radius.circular(4.0),
                      bottomLeft: _isLastItem(index)
                          ? const Radius.circular(16.0)
                          : const Radius.circular(4.0),
                      bottomRight: _isLastItem(index)
                          ? const Radius.circular(16.0)
                          : const Radius.circular(4.0),
                    ),
                    child: Material(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      child: ListTile(
                        title: Text(items[index].title),
                        leading: items[index].leading,
                        subtitle: items[index].subtitle.isNotEmpty
                            ? Text(items[index].subtitle)
                            : null,
                        onTap: () => items[index].onTap(),
                      ),
                    ),
                  );
                },
                separatorBuilder: (context, index) {
                  return SizedBox(
                    height: 4,
                  );
                },
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 100,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class ListItemData {
  final String title;
  final String subtitle;
  final Function onTap;
  final Widget leading;

  ListItemData({
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.leading,
  });
}
