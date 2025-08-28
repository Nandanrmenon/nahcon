import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
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

  AudioTrack? _selectedAudio;
  VideoTrack? _selectedVideo;
  SubtitleTrack? _selectedSubtitle;

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
    player.stream.tracks.listen((tracks) {
      setState(() {
        _selectedVideo = player.state.track.video;
        _selectedAudio = player.state.track.audio;
        _selectedSubtitle = player.state.track.subtitle;
      });
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    player.dispose();
    super.dispose();
  }

  void _showTrackSelector() async {
    final tracks = player.state.tracks;
    final currentAudio = player.state.track.audio;
    final currentVideo = player.state.track.video;
    final currentSubtitle = player.state.track.subtitle;

    showDialog(
      useSafeArea: false,
      context: context,
      builder: (context) {
        return Dialog.fullscreen(
          backgroundColor: Colors.transparent,
          child: Scaffold(
            backgroundColor: Colors.black54,
            appBar: AppBar(),
            body: SafeArea(
              child: StatefulBuilder(
                builder: (context, setModalState) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        if (tracks.audio.isNotEmpty) ...[
                          const Text('Audio Tracks',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          ...tracks.audio.map((track) {
                            return RadioGroup<AudioTrack>(
                                onChanged: (val) async {
                                  if (val != null) {
                                    await player.setAudioTrack(val);
                                    setModalState(() => _selectedAudio = val);
                                    setState(() => _selectedAudio = val);
                                  }
                                },
                                groupValue: _selectedAudio ?? currentAudio,
                                child: ListTile(
                                  leading: Radio<AudioTrack>(
                                      toggleable: true, value: track),
                                  title: Text(track.title ?? 'Audio'),
                                  subtitle: track.language != null
                                      ? Text(track.language!)
                                      : null,
                                ));
                          }),
                          const Divider(),
                        ],
                        if (tracks.video.isNotEmpty) ...[
                          const Text('Video Tracks',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          ...tracks.video.map((track) {
                            return RadioGroup<VideoTrack>(
                                onChanged: (val) async {
                                  if (val != null) {
                                    await player.setVideoTrack(val);
                                    setModalState(() => _selectedVideo = val);
                                    setState(() => _selectedVideo = val);
                                  }
                                },
                                groupValue: _selectedVideo ?? currentVideo,
                                child: ListTile(
                                  leading: Radio<VideoTrack>(
                                      toggleable: true, value: track),
                                  title: Text(track.title ?? 'Video'),
                                  subtitle: track.language != null
                                      ? Text(track.language!)
                                      : null,
                                ));
                          }),
                          const Divider(),
                        ],
                        if (tracks.subtitle.isNotEmpty) ...[
                          const Text('Subtitles',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          RadioGroup<SubtitleTrack>(
                              onChanged: (val) async {
                                await player.setSubtitleTrack(val!);
                                setModalState(() => _selectedSubtitle = val);
                                setState(() => _selectedSubtitle = val);
                              },
                              groupValue: _selectedSubtitle ?? currentSubtitle,
                              child: ListTile(
                                leading: Radio<SubtitleTrack>(
                                    toggleable: true,
                                    value: SubtitleTrack.no()),
                                title: Text('None'),
                              )),
                          ...tracks.subtitle.map((track) {
                            return RadioGroup<SubtitleTrack>(
                                onChanged: (val) async {
                                  if (val != null) {
                                    await player.setSubtitleTrack(val);
                                    setModalState(
                                        () => _selectedSubtitle = val);
                                    setState(() => _selectedSubtitle = val);
                                  }
                                },
                                groupValue:
                                    _selectedSubtitle ?? currentSubtitle,
                                child: ListTile(
                                  leading: Radio<SubtitleTrack>(
                                      toggleable: true, value: track),
                                  title: Text(track.title ?? 'Subtitle'),
                                  subtitle: track.language != null
                                      ? Text(track.language!)
                                      : null,
                                ));
                          }),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
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
              icon: const Icon(Symbols.arrow_back)),
          const Spacer(),
          Text(widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              )),
          const Spacer(),
          MaterialDesktopCustomButton(
            onPressed: () async {
              _showTrackSelector();
              // debugPrint('Custom "Settings" button pressed.');
            },
            icon: const Icon(Symbols.settings),
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
        brightnessGesture: true,
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
