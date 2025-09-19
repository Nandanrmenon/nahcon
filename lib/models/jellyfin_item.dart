class JellyfinItem {
  final String id;
  final String name;
  final String type;
  final String? imageUrl;
  final String? overview;
  final double? rating;
  final int? runtime; // minutes
  final String? officialRating;
  final List<String>? genres;
  final int? year;
  final bool isFavorite;

  final int? runTimeTicks;
  final int? playbackPositionTicks;
  final List<MediaSource>? mediaSources;

  JellyfinItem({
    required this.id,
    required this.name,
    required this.type,
    this.imageUrl,
    this.overview,
    this.rating,
    this.runtime,
    this.officialRating,
    this.genres,
    this.year,
    this.runTimeTicks,
    this.playbackPositionTicks,
    this.mediaSources,
    this.isFavorite = false,
  });

  factory JellyfinItem.fromJson(Map<String, dynamic> json) {
    final runTimeTicks = json['RunTimeTicks'];
    final runTimeMinutes = json['RunTimeMinutes'];

    int? calculatedRuntime;
    if (runTimeMinutes != null) {
      calculatedRuntime = runTimeMinutes;
    } else if (runTimeTicks != null) {
      calculatedRuntime = (runTimeTicks / 10000000 / 60).round();
    }

    return JellyfinItem(
      id: json['Id'],
      name: json['Name'],
      type: json['Type'],
      imageUrl: json['ImageTags']?['Primary'] != null
          ? '/Items/${json['Id']}/Images/Primary'
          : null,
      overview: json['Overview'],
      rating: json['CommunityRating']?.toDouble(),
      runtime: calculatedRuntime,
      officialRating: json['OfficialRating'],
      genres: json['Genres'] != null ? List<String>.from(json['Genres']) : null,
      year: json['ProductionYear'],
      runTimeTicks: runTimeTicks,
      playbackPositionTicks: json['UserData']?['PlaybackPositionTicks'],
      mediaSources: (json['MediaSources'] as List?)
          ?.map((s) => MediaSource.fromJson(s))
          .toList(),
      isFavorite: json['UserData']?['IsFavorite'] ?? false,
    );
  }

  /// Computed value for UI progress bar
  double get playbackProgress {
    if (runTimeTicks == null || runTimeTicks == 0) return 0;
    return (playbackPositionTicks ?? 0) / runTimeTicks!;
  }
}

class MediaStream {
  final String? codec;
  final String? language;
  final String? displayTitle;
  final int? width;
  final int? height;
  final String? videoRange; // SDR / HDR
  final int? bitRate;
  final String? type; // Video / Audio / Subtitle

  MediaStream({
    this.codec,
    this.language,
    this.displayTitle,
    this.width,
    this.height,
    this.videoRange,
    this.bitRate,
    this.type,
  });

  factory MediaStream.fromJson(Map<String, dynamic> json) {
    return MediaStream(
      codec: json['Codec'],
      language: json['Language'],
      displayTitle: json['DisplayTitle'],
      width: json['Width'],
      height: json['Height'],
      videoRange: json['VideoRange'],
      bitRate: json['BitRate'],
      type: json['Type'],
    );
  }
}

class MediaSource {
  final String? id;
  final String? container;
  final int? bitrate;
  final List<MediaStream>? streams;

  MediaSource({
    this.id,
    this.container,
    this.bitrate,
    this.streams,
  });

  factory MediaSource.fromJson(Map<String, dynamic> json) {
    return MediaSource(
      id: json['Id'],
      container: json['Container'],
      bitrate: json['Bitrate'],
      streams: (json['MediaStreams'] as List?)
          ?.map((s) => MediaStream.fromJson(s))
          .toList(),
    );
  }
}

class VideoStream {
  final String codec;
  final int width;
  final int height;
  final int? bitrate;
  final String? videoRangeType; // SDR, HDR10, etc.

  VideoStream({
    required this.codec,
    required this.width,
    required this.height,
    this.bitrate,
    this.videoRangeType,
  });

  factory VideoStream.fromJson(Map<String, dynamic> json) {
    return VideoStream(
      codec: json['Codec'],
      width: json['Width'],
      height: json['Height'],
      bitrate: json['BitRate'],
      videoRangeType: json['VideoRangeType'],
    );
  }
}

class AudioStream {
  final String codec;
  final String? language;
  final int? channels;

  AudioStream({
    required this.codec,
    this.language,
    this.channels,
  });

  factory AudioStream.fromJson(Map<String, dynamic> json) {
    return AudioStream(
      codec: json['Codec'],
      language: json['Language'],
      channels: json['Channels'],
    );
  }
}
