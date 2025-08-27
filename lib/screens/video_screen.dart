import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../services/jellyfin_service.dart';

class VideoScreen extends StatefulWidget {
  final String videoUrl;
  final String title;
  final JellyfinService service;

  const VideoScreen({
    super.key,
    required this.videoUrl,
    required this.title,
    required this.service,
  });

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  late final player = Player();
  late final controller = VideoController(player);
  bool _showAppBar = true;
  Timer? _hideTimer;

  void _toggleAppBar() {
    setState(() {
      _showAppBar = !_showAppBar;
    });
    _resetHideTimer();
  }

  void _resetHideTimer() {
    _hideTimer?.cancel();
    if (_showAppBar) {
      _hideTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _showAppBar = false);
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    player.open(
      Media(
        widget.videoUrl,
        httpHeaders: widget.service.getVideoHeaders(),
      ),
    );
    _resetHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialVideoControlsTheme(
      normal: MaterialVideoControlsThemeData(
        // Modify theme options:

        buttonBarButtonSize: 24.0,
        buttonBarButtonColor: Colors.white,
        // Modify top button bar:

        topButtonBar: [
          IconButton(
              color: Colors.white,
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back)),
          const Spacer(),
          Text(widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              )),
          const Spacer(),
          MaterialDesktopCustomButton(
            onPressed: () {
              debugPrint('Custom "Settings" button pressed.');
            },
            icon: const Icon(Icons.settings),
          ),
        ],
        bottomButtonBarMargin: EdgeInsets.only(bottom: 48, left: 48, right: 48),
        bottomButtonBar: [
          MaterialPositionIndicator(),
        ],
        seekBarColor: Colors.white12,
        seekBarPositionColor: Theme.of(context).colorScheme.primaryFixed,
        seekBarThumbColor: Theme.of(context).colorScheme.primaryContainer,
        seekOnDoubleTap: true,
        seekBarMargin: EdgeInsets.only(left: 48, bottom: 48, right: 48),
        seekBarHeight: 4,
        // brightnessGesture: true,
        volumeGesture: true,
      ),
      fullscreen: const MaterialVideoControlsThemeData(
        // Modify fullscreen options:

        buttonBarButtonSize: 32.0,
        buttonBarButtonColor: Colors.white,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        body: GestureDetector(
          onTap: _toggleAppBar,
          child: Video(
            controller: controller,
            wakelock: true,
            controls: MaterialVideoControls,
          ),
        ),
      ),
    );
  }
}
