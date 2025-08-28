import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:nahcon/screens/login_screen.dart';
import 'package:nahcon/utils/constants.dart';

import '../services/jellyfin_service.dart';

class SettingsScreen extends StatelessWidget {
  final JellyfinService service;

  const SettingsScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        children: [
          ListTile(
            leading: FutureBuilder<bool>(
              future: service.hasUserImage(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data == true) {
                  return CircleAvatar(
                    radius: 20,
                    backgroundImage: null,
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: service.getUserImageUrl(),
                        httpHeaders: service.getVideoHeaders(),
                        width: 40,
                        height: 40,
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
            title: const Text('Account'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service.username ?? ''),
                Text(
                  service.serverName ?? service.baseUrl ?? '',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            isThreeLine: true,
            onTap: () {
              // TODO: Account settings
            },
          ),
          ListTile(
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
          ListTile(
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
          ListTile(
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
          const AboutListTile(
            icon: Icon(Symbols.info),
            applicationName: kAppName,
            applicationVersion: kAppVersion,
          ),
        ],
      ),
    );
  }
}
