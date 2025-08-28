class JellyfinItem {
  final String id;
  final String name;
  final String type;
  final String? imageUrl;
  final String? overview;
  final double? rating;
  final int? runtime;
  final String? officialRating;
  final List<String>? genres;

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
  });

  factory JellyfinItem.fromJson(Map<String, dynamic> json) {
    final runTimeTicks = json['RunTimeTicks'];
    final runTimeMinutes = json['RunTimeMinutes'];

    // print(
    //     'Runtime debug - Ticks: $runTimeTicks, Minutes: $runTimeMinutes'); // Debug

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
    );
  }
}
