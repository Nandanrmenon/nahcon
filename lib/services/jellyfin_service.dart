import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:nahcon/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/jellyfin_item.dart';

class JellyfinService {
  static final JellyfinService _instance = JellyfinService._internal();

  factory JellyfinService() => _instance;

  JellyfinService._internal();

  String? baseUrl;
  String? accessToken;
  String? userId;
  String? username;
  String? serverName;
  static const String _clientName = kAppName;
  static const String _deviceId = 'flutter_app_1';
  static const String _deviceName = 'Flutter Mobile';
  static const String _version = kAppVersion;
  static const String _apiVersion = '10.11.0';

  static const String _profilesKey = 'user_profiles';
  static const String _currentProfileKey = 'current_profile_id';

  Map<String, String> get _defaultHeaders => {
        'x-emby-authorization': 'MediaBrowser '
            'Client="$_clientName", '
            'Device="$_deviceName", '
            'DeviceId="$_deviceId", '
            'Version="$_version"',
        'Content-Type': 'application/json',
      };

  String _profileId(String serverUrl, String username) =>
      '${serverUrl.trim()}|${username.trim()}';

  Future<void> saveProfile({
    required String serverUrl,
    required String username,
    required String password,
    String? accessToken,
    String? userId,
    String? serverName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final profiles = prefs.getStringList(_profilesKey) ?? [];
    final id = _profileId(serverUrl, username);
    final profile = jsonEncode({
      'id': id,
      'serverUrl': serverUrl,
      'username': username,
      'password': password,
      'accessToken': accessToken,
      'userId': userId,
      'serverName': serverName,
    });

    // Remove old if exists
    profiles.removeWhere((p) => jsonDecode(p)['id'] == id);
    profiles.add(profile);
    await prefs.setStringList(_profilesKey, profiles);
    await prefs.setString(_currentProfileKey, id);
  }

  // Get all saved profiles
  Future<List<Map<String, dynamic>>> getProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final profiles = prefs.getStringList(_profilesKey) ?? [];
    return profiles.map((p) => jsonDecode(p) as Map<String, dynamic>).toList();
  }

  // Set current profile by id
  Future<void> setCurrentProfile(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentProfileKey, id);
    final profiles = prefs.getStringList(_profilesKey) ?? [];
    final profile = profiles
        .map((p) => jsonDecode(p))
        .firstWhere((p) => p['id'] == id, orElse: () => null);
    if (profile != null) {
      baseUrl = profile['serverUrl'];
      username = profile['username'];
      accessToken = profile['accessToken'];
      userId = profile['userId'];
      serverName = profile['serverName'];
    }
  }

  // Remove a profile by id
  Future<void> removeProfile(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final profiles = prefs.getStringList(_profilesKey) ?? [];
    profiles.removeWhere((p) => jsonDecode(p)['id'] == id);
    await prefs.setStringList(_profilesKey, profiles);
    // If current profile is removed, clear current_profile_id
    final currentId = prefs.getString(_currentProfileKey);
    if (currentId == id) {
      await prefs.remove(_currentProfileKey);
    }
  }

  // Get current profile
  Future<Map<String, dynamic>?> getCurrentProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_currentProfileKey);
    if (id == null) return null;
    final profiles = prefs.getStringList(_profilesKey) ?? [];
    final profile = profiles
        .map((p) => jsonDecode(p))
        .firstWhere((p) => p['id'] == id, orElse: () => null);
    return profile;
  }

  Future<void> fetchServerInfo() async {
    final response = await http.get(
      Uri.parse('$baseUrl/System/Info/Public'),
      headers: _defaultHeaders,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      serverName = data['ServerName'];
    }
  }

  Future<bool> login(String serverUrl, String username, String password) async {
    await clearCache();
    try {
      baseUrl = serverUrl.trim();
      if (baseUrl!.endsWith('/')) {
        baseUrl = baseUrl!.substring(0, baseUrl!.length - 1);
      }

      final response = await http.post(
        Uri.parse('$baseUrl/Users/AuthenticateByName'),
        headers: _defaultHeaders,
        body: json.encode({
          'Username': username,
          'Pw': password,
          'ApiVersion': _apiVersion,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        accessToken = data['AccessToken'];
        userId = data['User']['Id'];
        this.username = username;

        await fetchServerInfo();
        await saveProfile(
          serverUrl: baseUrl!,
          username: username,
          password: password,
          accessToken: accessToken,
          userId: userId,
          serverName: serverName,
        );
        return true;
      } else {
        throw Exception(
            'Login failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Login error details: $e');
      rethrow;
    }
  }

  Future<List<JellyfinItem>> getLibraries() async {
    final response = await http.get(
      Uri.parse('$baseUrl/Items'),
      headers: {
        'Authorization': 'MediaBrowser Token="$accessToken"',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['Items'] as List)
          .map((item) => JellyfinItem.fromJson(item))
          .toList();
    }
    throw Exception('Failed to load libraries');
  }

  Future<List<JellyfinItem>> getSuggestions({int limit = 10}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/Users/$userId/Suggestions').replace(queryParameters: {
        'limit': '$limit',
        'type': 'Movie,Series',
      }),
      headers: {
        'X-Emby-Authorization': _defaultHeaders['x-emby-authorization']!,
        'X-Emby-Token': accessToken!,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['Items'] as List)
          .map((item) => JellyfinItem.fromJson(item))
          .toList();
    }
    throw Exception('Failed to load suggestions');
  }

  Future<List<JellyfinItem>> getHistory({int limit = 20}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/Users/$userId/Items').replace(queryParameters: {
        'Limit': '$limit',
        'Filters': 'IsPlayed',
        'IncludeItemTypes': 'Movie,Series',
        'Recursive': 'true',
        'SortBy': 'DatePlayed',
        'SortOrder': 'Descending',
      }),
      headers: {
        'X-Emby-Authorization': _defaultHeaders['x-emby-authorization']!,
        'X-Emby-Token': accessToken!,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['Items'] as List)
          .map((item) => JellyfinItem.fromJson(item))
          .toList();
    }
    throw Exception('Failed to load history');
  }

  Future<List<String>> getMovieGenres() async {
    final response = await http.get(
      Uri.parse('$baseUrl/Genres?userId=$userId&IncludeItemTypes=Movie'),
      headers: {
        'X-Emby-Authorization': _defaultHeaders['x-emby-authorization']!,
        'X-Emby-Token': accessToken!,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['Items'] as List)
          .map((item) => item['Name'] as String)
          .toList();
    }
    throw Exception('Failed to load genres');
  }

  Future<List<JellyfinItem>> getAllMovies({String? genreId}) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'movies_cache_${genreId ?? 'all'}';
    final cachedData = prefs.getString(cacheKey);

    if (cachedData != null) {
      final List<dynamic> decoded = jsonDecode(cachedData);
      return decoded.map((item) => JellyfinItem.fromJson(item)).toList();
    }

    final response = await http.get(
      Uri.parse('$baseUrl/Items').replace(queryParameters: {
        'IncludeItemTypes': 'Movie',
        'Recursive': 'true',
        'SortBy': 'SortName',
        'userId': userId,
        if (genreId != null) 'Genres': genreId,
      }),
      headers: {
        'X-Emby-Authorization': _defaultHeaders['x-emby-authorization']!,
        'X-Emby-Token': accessToken!,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Cache the response
      await prefs.setString(cacheKey, jsonEncode(data['Items']));
      return (data['Items'] as List)
          .map((item) => JellyfinItem.fromJson(item))
          .toList();
    }
    throw Exception('Failed to load movies');
  }

  Future<List<JellyfinItem>> getAllSeries({String? genreId}) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'series_cache_${genreId ?? 'all'}';
    final cachedData = prefs.getString(cacheKey);
    final response = await http.get(
      Uri.parse(
          '$baseUrl/Items?IncludeItemTypes=Series&Recursive=true&SortBy=SortName'),
      headers: {
        'X-Emby-Authorization': _defaultHeaders['x-emby-authorization']!,
        'X-Emby-Token': accessToken!,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await prefs.setString(cacheKey, jsonEncode(data['Items']));
      return (data['Items'] as List)
          .map((item) => JellyfinItem.fromJson(item))
          .toList();
    }
    throw Exception('Failed to load series');
  }

  Future<List<String>> getSeriesGenres() async {
    final response = await http.get(
      Uri.parse('$baseUrl/Genres?userId=$userId&IncludeItemTypes=Series'),
      headers: {
        'X-Emby-Authorization': _defaultHeaders['x-emby-authorization']!,
        'X-Emby-Token': accessToken!,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['Items'] as List)
          .map((item) => item['Name'] as String)
          .toList();
    }
    throw Exception('Failed to load genres');
  }

  Future<JellyfinItem> getItemDetails(String itemId) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'item_details_$itemId';
    final cachedData = prefs.getString(cacheKey);

    if (cachedData != null) {
      return JellyfinItem.fromJson(jsonDecode(cachedData));
    }

    try {
      if (userId == null) {
        final success = await tryAutoLogin();
        if (!success) throw Exception('Not logged in');
      }

      final response = await http.get(
        Uri.parse(
            '$baseUrl/Users/$userId/Items/$itemId?Fields=MediaSources,Overview,Genres,ProductionYear'),
        headers: {
          'X-Emby-Authorization': _defaultHeaders['x-emby-authorization']!,
          'X-Emby-Token': accessToken!,
        },
      );
      final data = jsonDecode(response.body);
      // print('response');
      print(data);

      if (response.statusCode == 401) {
        final success = await tryAutoLogin();
        if (success) {
          return getItemDetails(itemId);
        }
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Cache the response
        await prefs.setString(cacheKey, jsonEncode(data));
        return JellyfinItem.fromJson(data);
      }
      throw Exception('Failed to load item details: ${response.statusCode}');
    } catch (e) {
      print('Error fetching details: $e');
      rethrow;
    }
  }

  Future<void> saveCredentials(
      String serverUrl, String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('serverUrl', serverUrl);
    await prefs.setString('username', username);
    await prefs.setString('password', password);
  }

  Future<bool> tryAutoLogin() async {
    final profile = await getCurrentProfile();
    if (profile != null) {
      try {
        baseUrl = profile['serverUrl'];
        username = profile['username'];
        accessToken = profile['accessToken'];
        userId = profile['userId'];
        serverName = profile['serverName'];

        return await login(
          profile['serverUrl'],
          profile['username'],
          profile['password'],
        );
      } catch (e) {
        baseUrl = null;
        accessToken = null;
        return false;
      }
    }
    return false;
  }

  String getStreamUrl(String itemId) {
    if (baseUrl == null || accessToken == null) {
      throw Exception('JellyfinService not initialized');
    }
    return '$baseUrl/Videos/$itemId/stream?Static=true&MediaSourceId=$itemId&PlaySessionId=${DateTime.now().millisecondsSinceEpoch}&api_key=$accessToken';
  }

  Map<String, String> getVideoHeaders() {
    if (baseUrl == null || accessToken == null) {
      throw Exception('JellyfinService not initialized');
    }
    return {
      'X-Emby-Authorization': _defaultHeaders['x-emby-authorization']!,
    };
  }

  String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    // Remove leading slash if present
    path = path.startsWith('/') ? path.substring(1) : path;
    return '$baseUrl/$path';
  }

  Future<List<JellyfinItem>> getNextUp() async {
    final response = await http.get(
      Uri.parse('$baseUrl/Shows/NextUp?userId=$userId'),
      headers: {
        'X-Emby-Authorization': _defaultHeaders['x-emby-authorization']!,
        'X-Emby-Token': accessToken!,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['Items'] as List)
          .map((item) => JellyfinItem.fromJson(item))
          .toList();
    }
    throw Exception('Failed to load next up items');
  }

  Future<List<JellyfinItem>> getContinuePlaying() async {
    final response = await http.get(
      Uri.parse('$baseUrl/Users/$userId/Items/Resume'),
      headers: {
        'X-Emby-Authorization': _defaultHeaders['x-emby-authorization']!,
        'X-Emby-Token': accessToken!,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['Items'] as List)
          .map((item) => JellyfinItem.fromJson(item))
          .toList();
    }
    throw Exception('Failed to load next up items');
  }

  Future<List<JellyfinItem>> getSimilarItems(String itemId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/Items/$itemId/Similar?userId=$userId&Limit=10'),
      headers: {
        'X-Emby-Authorization': _defaultHeaders['x-emby-authorization']!,
        'X-Emby-Token': accessToken!,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['Items'] as List)
          .map((item) => JellyfinItem.fromJson(item))
          .toList();
    }
    throw Exception('Failed to load similar items');
  }

  Future<List<JellyfinItem>> getSeasons(String seriesId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/Shows/$seriesId/Seasons?userId=$userId'),
      headers: {
        'X-Emby-Authorization': _defaultHeaders['x-emby-authorization']!,
        'X-Emby-Token': accessToken!,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['Items'] as List)
          .map((item) => JellyfinItem.fromJson(item))
          .toList();
    }
    throw Exception('Failed to load seasons');
  }

  Future<List<JellyfinItem>> getEpisodes(
      String seriesId, String seasonId) async {
    final response = await http.get(
      Uri.parse(
          '$baseUrl/Shows/$seriesId/Episodes?seasonId=$seasonId&userId=$userId'),
      headers: {
        'X-Emby-Authorization': _defaultHeaders['x-emby-authorization']!,
        'X-Emby-Token': accessToken!,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['Items'] as List)
          .map((item) => JellyfinItem.fromJson(item))
          .toList();
    }
    throw Exception('Failed to load episodes');
  }

  Future<List<String>> getBackdropUrls(String itemId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/Items/$itemId'),
        headers: {
          'X-Emby-Authorization': _defaultHeaders['x-emby-authorization']!,
          'X-Emby-Token': accessToken!,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final backdropIds = data['BackdropImageTags'] as List?;

        if (backdropIds != null && backdropIds.isNotEmpty) {
          return List.generate(
            backdropIds.length,
            (index) {
              final url = '$baseUrl/Items/$itemId/Images/Backdrop/$index';
              return url.isNotEmpty ? url : null;
            },
          ).where((url) => url != null).cast<String>().toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching backdrops: $e');
      return [];
    }
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) =>
        key.startsWith('movies_cache_') || key.startsWith('item_details_'));
    for (var key in keys) {
      await prefs.remove(key);
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentProfileKey);
    baseUrl = null;
    accessToken = null;
    userId = null;
    username = null;
  }

  Future<bool> validateServer(String serverUrl) async {
    try {
      final url = serverUrl.trim();
      final response = await http.get(
        Uri.parse('$url/System/Info/Public'),
        headers: _defaultHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        serverName = data['ServerName'];
        baseUrl = url;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<List<JellyfinItem>> search(String query) async {
    try {
      if (accessToken == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/Items').replace(queryParameters: {
          'SearchTerm': query,
          'IncludeItemTypes': 'Movie,Series',
          'Recursive': 'true',
          'userId': userId,
        }),
        headers: {
          'X-Emby-Authorization': _defaultHeaders['x-emby-authorization']!,
          'X-Emby-Token': accessToken!,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['Items'] as List)
            .map((item) => JellyfinItem.fromJson(item))
            .toList();
      }
      throw Exception('Failed to search items: ${response.statusCode}');
    } catch (e) {
      print('Search error: $e');
      return [];
    }
  }

  String getUserImageUrl() {
    if (baseUrl == null || userId == null) return '';
    return '$baseUrl/Users/$userId/Images/Primary';
  }

  Future<bool> hasUserImage() async {
    if (baseUrl == null || userId == null) return false;
    try {
      final response = await http.head(
        Uri.parse(getUserImageUrl()),
        headers: {
          'X-Emby-Authorization': _defaultHeaders['x-emby-authorization']!,
          'X-Emby-Token': accessToken!,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Duration?> getPlaybackPosition(String itemId) async {
    if (userId == null || accessToken == null || baseUrl == null) return null;
    final response = await http.get(
      Uri.parse('$baseUrl/Users/$userId/Items/$itemId'),
      headers: {
        'X-Emby-Authorization': _defaultHeaders['x-emby-authorization']!,
        'X-Emby-Token': accessToken!,
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final userData = data['UserData'];
      if (userData != null && userData['PlaybackPositionTicks'] != null) {
        final ticks = userData['PlaybackPositionTicks'] as int;
        return Duration(milliseconds: (ticks / 10000).round());
      }
    }
    return null;
  }

  Future<void> savePlaybackPosition({
    required String itemId,
    required Duration position,
    Duration? duration,
    bool isPaused = false,
  }) async {
    if (userId == null || accessToken == null || baseUrl == null) return;

    final url = '$baseUrl/Sessions/Playing/Progress';
    final body = {
      'ItemId': itemId,
      'PositionTicks': position.inMilliseconds * 10000,
      if (duration != null) 'DurationTicks': duration.inMilliseconds * 10000,
      'IsPaused': isPaused,
      'PlaySessionId': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    await http.post(
      Uri.parse(url),
      headers: {
        'X-Emby-Authorization': _defaultHeaders['x-emby-authorization']!,
        'X-Emby-Token': accessToken!,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
  }
}
