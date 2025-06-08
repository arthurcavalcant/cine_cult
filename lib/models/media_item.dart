import 'dart:convert';

class MediaItem {
  final String id; // imdbID from OMDb
  final String title;
  final String? posterUrl;
  final String? synopsis; // OMDb 'Plot'
  final List<String>? cast; // OMDb 'Actors' (string, needs parsing)
  final String? releaseYear; // OMDb 'Year' or 'Released'
  final double? publicRating; // OMDb 'imdbRating'
  final String? type; // OMDb 'Type' (e.g., movie, series, episode)
  final String? genre; // OMDb 'Genre'
  final String? runtime; // OMDb 'Runtime'

  MediaItem({
    required this.id,
    required this.title,
    this.posterUrl,
    this.synopsis,
    this.cast,
    this.releaseYear,
    this.publicRating,
    this.type,
    this.genre,
    this.runtime,
  });

  // Factory constructor for OMDb search results (less detail)
  factory MediaItem.fromOMDbJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['imdbID'] ?? 'N/A',
      title: json['Title'] ?? 'N/A',
      releaseYear: json['Year'],
      posterUrl: (json['Poster'] != null && json['Poster'] != 'N/A') ? json['Poster'] : null,
      type: json['Type'],
      // Fields not typically in search results are left null or default
      // synopsis, cast, publicRating, genre, runtime would be fetched by getMediaDetails
    );
  }

  // Factory constructor for OMDb detailed information
  factory MediaItem.fromOMDbDetailJson(Map<String, dynamic> json) {
    double? rating;
    if (json['imdbRating'] != null && json['imdbRating'] != 'N/A') {
      rating = double.tryParse(json['imdbRating']);
    }

    List<String>? parsedCast;
    final dynamic actorsField = json['Actors'];
    if (actorsField != null) {
      if (actorsField is String && actorsField.toUpperCase() != 'N/A') {
        parsedCast = actorsField
            .split(',')
            .map((actor) => actor.trim())
            .where((actor) => actor.isNotEmpty)
            .toList();
      } else if (actorsField is List) {
        parsedCast = actorsField
            .where((actor) => actor != null) // Filter out nulls in the list
            .map((actor) => actor.toString().trim()) // Convert each to string and trim
            .where((actor) => actor.isNotEmpty && actor.toUpperCase() != 'N/A') // Filter out empty or "N/A" strings
            .toList();
      }
      // If after processing, parsedCast is an empty list, set it to null
      // as it implies no valid actors were found.
      if (parsedCast != null && parsedCast.isEmpty) {
        parsedCast = null;
      }
    }

    // Similar robust parsing for Genre, though it's a String?
    // OMDb usually provides Genre as a comma-separated string.
    // If it could also be a list, it should be joined.
    String? parsedGenre = json['Genre'];
    if (json['Genre'] != null && json['Genre'] != 'N/A') {
        if (json['Genre'] is List) {
            // If Genre is a list, join it into a string
            parsedGenre = (json['Genre'] as List)
                .map((g) => g.toString().trim())
                .where((g) => g.isNotEmpty)
                .join(', ');
            if (parsedGenre.isEmpty) {
              parsedGenre = null;
            }
        } else if (json['Genre'] is String) {
            // Ensure string genre is not "N/A"
            if (json['Genre'].toString().toUpperCase() == 'N/A') {
                parsedGenre = null;
            } else {
                parsedGenre = json['Genre'].toString().trim();
            }
        }
    } else {
        parsedGenre = null; // Handles null or "N/A" string directly
    }


    return MediaItem(
      id: json['imdbID'] ?? 'N/A',
      title: json['Title'] ?? 'N/A',
      releaseYear: json['Year'], // Or json['Released'] for more specific date
      posterUrl: (json['Poster'] != null && json['Poster'] != 'N/A') ? json['Poster'] : null,
      synopsis: (json['Plot'] != null && json['Plot'] != 'N/A') ? json['Plot'] : null,
      cast: parsedCast,
      publicRating: rating,
      type: json['Type'],
      genre: parsedGenre,
      runtime: (json['Runtime'] != null && json['Runtime'] != 'N/A') ? json['Runtime'] : null,
    );
  }

  // For Database
  Map<String, dynamic> toMapForDb() {
    return {
      'id': id,
      'title': title,
      'posterUrl': posterUrl,
      'synopsis': synopsis,
      'releaseYear': releaseYear,
      'publicRating': publicRating,
      'type': type,
      'genre': genre,
      'runtime': runtime,
      'cast': cast != null ? jsonEncode(cast) : null, // Store cast as JSON string
    };
  }

  factory MediaItem.fromDbMap(Map<String, dynamic> map) {
    List<String>? castList;
    if (map['cast'] != null) {
      try {
        // Attempt to decode, ensure it's a list of strings
        var decodedCast = jsonDecode(map['cast']);
        if (decodedCast is List) {
          castList = decodedCast.map((e) => e.toString()).toList();
        }
      } catch (e) {
        // If decoding fails or it's not a list, treat as null or handle error
        print('Error decoding cast from DB: $e');
        castList = null;
      }
    }
    return MediaItem(
      id: map['id'] ?? 'N/A',
      title: map['title'] ?? 'N/A',
      posterUrl: map['posterUrl'],
      synopsis: map['synopsis'],
      releaseYear: map['releaseYear'],
      publicRating: map['publicRating'] != null ? (map['publicRating'] as num).toDouble() : null,
      type: map['type'],
      genre: map['genre'],
      runtime: map['runtime'],
      cast: castList,
    );
  }
}
