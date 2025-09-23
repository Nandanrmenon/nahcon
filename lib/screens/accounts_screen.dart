import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:nahcon/screens/login_screen.dart';
import 'package:nahcon/screens/settings_screen.dart';
import 'package:nahcon/widgets/m_list.dart';
import 'package:nahcon/widgets/movie_card.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/jellyfin_item.dart';
import '../services/jellyfin_service.dart';
import 'movie_details_screen.dart';

class AccountsScreen extends StatelessWidget {
  final JellyfinService service;

  const AccountsScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final isDesktop = UniversalPlatform.isDesktop
        ? (MediaQuery.of(context).size.width < 200 ||
            MediaQuery.of(context).size.width > 1200)
        : MediaQuery.of(context).size.width > 600;

    Future<void> openUrl(Uri url) async {
      if (!await launchUrl(url)) {
        throw Exception('Could not launch $url');
      }
    }

    final itemApp = [
      MListItemData(
        title: 'App Settings',
        subtitle: '',
        leading: Icon(Symbols.settings_rounded),
        onTap: () async {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SettingsScreen(
                  service: service,
                ),
              ));
        },
      ),
      MListItemData(
        title: 'Logout',
        subtitle: '',
        leading: Icon(Symbols.logout_rounded),
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
      MListItemData(
        title: 'Info',
        subtitle: '',
        leading: Icon(Symbols.info_rounded),
        onTap: () {
          showAboutDialog(context: context);
        },
      ),
    ];

    final itemLinks = [
      if (UniversalPlatform.isWeb)
        MListItemData(
          title: 'Get the app',
          subtitle:
              'For better experience, use the ${isDesktop ? 'desktop' : 'mobile'} app',
          leading: Icon(Symbols.download),
          onTap: () async {
            await openUrl(
                Uri.parse('https://github.com/Nandanrmenon/nahcon/releases'));
          },
        ),
      MListItemData(
        title: 'Github',
        subtitle: 'Check out the source code',
        leading: Icon(Symbols.code),
        onTap: () async {
          await openUrl(Uri.parse('https://github.com/Nandanrmenon/nahcon/'));
        },
      ),
      MListItemData(
        title: 'Report Issues',
        subtitle: '',
        leading: Icon(Symbols.report_problem),
        onTap: () async {
          await openUrl(
              Uri.parse('https://github.com/Nandanrmenon/nahcon/issues'));
        },
      ),
      MListItemData(
        title: 'Support Me',
        subtitle: 'Buy me a coffee',
        leading: Icon(Symbols.money),
        onTap: () async {
          await openUrl(Uri.parse('https://ko-fi.com/P5P41KEC9N'));
        },
      ),
    ];

    return Scaffold(
      body: isDesktop
          ? Row(
              children: [
                Expanded(
                  child: Material(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(16),
                        topLeft: Radius.circular(16),
                      ),
                    ),
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 24),
                      child: Column(
                        children: [
                          accountContent(context, isDesktop),
                          ListTile(
                            leading: const Icon(Symbols.resume_rounded),
                            title: Text(
                              'History',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                          historyContent(),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 48,
                ),
                Expanded(
                  child: Column(
                    spacing: 24.0,
                    children: [
                      SizedBox(
                        height: 4.0,
                      ),
                      Column(
                        spacing: 8.0,
                        children: [
                          MListHeader(title: 'Settings'),
                          MListView(items: itemApp),
                        ],
                      ),
                      Column(
                        spacing: 8.0,
                        children: [
                          MListHeader(title: 'Links'),
                          MListView(items: itemLinks),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            )
          : SafeArea(
              top: UniversalPlatform.isAndroid ? true : false,
              child: Padding(
                padding: isDesktop
                    ? EdgeInsets.zero
                    : EdgeInsets.symmetric(horizontal: 16.0),
                child: ListView(
                  children: [
                    SizedBox(
                      height: 24,
                    ),
                    accountContent(context, isDesktop),
                    ListTile(
                      leading: const Icon(Symbols.resume_rounded),
                      title: Text(
                        'History',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    historyContent(),
                    SizedBox(
                      height: 24,
                    ),
                    Column(
                      spacing: 24.0,
                      children: [
                        Column(
                          spacing: 8.0,
                          children: [
                            MListHeader(title: 'Settings'),
                            MListView(items: itemApp),
                          ],
                        ),
                        Column(
                          spacing: 8.0,
                          children: [
                            MListHeader(title: 'Links'),
                            MListView(items: itemLinks),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 100,
                    )
                  ],
                ),
              ),
            ),
    );
  }

  Widget accountContent(BuildContext context, isDesktop) {
    return Row(
      spacing: 24.0,
      mainAxisSize: MainAxisSize.min,
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
            return CircleAvatar(
                radius: 50,
                child: const Icon(
                  Symbols.account_circle,
                  size: 50,
                ));
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
    );
  }

  Widget historyContent() {
    return FutureBuilder<List<JellyfinItem>>(
      future: service.getHistory(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final items = snapshot.data!;
          return SizedBox(
            height: 380,
            child: CarouselView(
              itemExtent: 200,
              shrinkExtent: 0.8,
              itemSnapping: true,
              enableSplash: false,
              children: items.map((item) {
                return MovieCard(
                  title: item.name,
                  posterUrl: item.imageUrl != null
                      ? service.getImageUrl(item.imageUrl)
                      : null,
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
          );
        }
        return Card.filled(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              spacing: 16.0,
              children: [
                Icon(
                  Symbols.heart_broken_rounded,
                  fill: 1.0,
                  color: Colors.redAccent,
                ),
                Text(
                  'Start watching movies or series to see your watch history',
                  style: Theme.of(context).textTheme.labelMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Widget settingContent(final items) {
  //   return ListView.separated(
  //     shrinkWrap: true,
  //     physics: NeverScrollableScrollPhysics(),
  //     itemCount: items.length,
  //     itemBuilder: (context, index) {
  //       bool isLastItem(int index) {
  //         if (UniversalPlatform.isWeb) {
  //           return index == items.length - 1;
  //         } else {
  //           return index == items.length - 1;
  //         }
  //       }

  //       return ClipRRect(
  //         borderRadius: BorderRadius.only(
  //           topLeft: index == 0 ? Radius.circular(16.0) : Radius.circular(4.0),
  //           topRight: index == 0 ? Radius.circular(16.0) : Radius.circular(4.0),
  //           bottomLeft: isLastItem(index)
  //               ? const Radius.circular(16.0)
  //               : const Radius.circular(4.0),
  //           bottomRight: isLastItem(index)
  //               ? const Radius.circular(16.0)
  //               : const Radius.circular(4.0),
  //         ),
  //         child: Material(
  //           color: Theme.of(context).colorScheme.surfaceContainer,
  //           child: ListTile(
  //             title: Text(items[index].title),
  //             leading: items[index].leading,
  //             subtitle: items[index].subtitle.isNotEmpty
  //                 ? Text(items[index].subtitle)
  //                 : null,
  //             onTap: () => items[index].onTap(),
  //           ),
  //         ),
  //       );
  //     },
  //     separatorBuilder: (context, index) {
  //       return SizedBox(
  //         height: 4,
  //       );
  //     },
  //   );
  // }
}
