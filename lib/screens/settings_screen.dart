import 'package:flutter/material.dart';
import 'package:nahcon/services/jellyfin_service.dart';
import 'package:nahcon/widgets/m_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_platform/universal_platform.dart';

class SettingsScreen extends StatefulWidget {
  final JellyfinService service;
  const SettingsScreen({super.key, required this.service});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SharedPreferences pref;
  bool enableHW = true;

  @override
  void initState() {
    loadPref();
    super.initState();
  }

  Future<void> loadPref() async {
    pref = await SharedPreferences.getInstance();
    setState(() {
      enableHW = pref.getBool("is_hw_enabled") ?? true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final itemPlaybackSettings = [
      MListItemData(
          title: 'Hardware Acceleration',
          subtitle: 'Uses your GPU to render video',
          suffix: Switch.adaptive(
            value: enableHW,
            onChanged: (value) {
              setState(() {
                enableHW = value;
                pref.setBool('is_hw_enabled', value);
              });
            },
          ),
          onTap: () {
            setState(() {
              enableHW = !enableHW;
              pref.setBool('is_hw_enabled', enableHW);
            });
          }),
    ];
    final itemTroubleshooting = [
      MListItemData(
        title: 'Clear Cache',
        subtitle: 'Helps clear out your storage',
        onTap: () async {
          await widget.service.clearCache();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cache cleared'),
              ),
            );
          }
        },
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            spacing: 24.0,
            children: [
              Column(
                spacing: 8.0,
                children: [
                  MListHeader(
                    title: 'Playback Settings',
                  ),
                  MListView(items: itemPlaybackSettings),
                ],
              ),
              Column(
                spacing: 8.0,
                children: [
                  MListHeader(
                    title: 'Troubleshooting',
                  ),
                  MListView(items: itemTroubleshooting),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget settingContent(final items) {
    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        bool isLastItem(int index) {
          if (UniversalPlatform.isWeb) {
            return index == items.length - 1;
          } else {
            return index == items.length - 1;
          }
        }

        return ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: index == 0 ? Radius.circular(16.0) : Radius.circular(4.0),
            topRight: index == 0 ? Radius.circular(16.0) : Radius.circular(4.0),
            bottomLeft: isLastItem(index)
                ? const Radius.circular(16.0)
                : const Radius.circular(4.0),
            bottomRight: isLastItem(index)
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
    );
  }
}
