// filepath: c:\Users\arthu\AndroidStudioProjects\cine_cult\lib\models\user_media_item.dart
import 'media_item.dart';

enum MediaStatus { wantToWatch, watched }

class UserMediaItem {
  final MediaItem mediaItem;
  MediaStatus status;
  int? userRating; // 1-5 stars
  String? userComment;
  DateTime dateAdded;

  UserMediaItem({
    required this.mediaItem,
    required this.status,
    this.userRating,
    this.userComment,
    DateTime? dateAdded,
  }) : dateAdded = dateAdded ?? DateTime.now();

  // Helper to update watched details
  void updateWatchedDetails({int? rating, String? comment}) {
    if (status == MediaStatus.watched) {
      userRating = rating;
      userComment = comment;
    }
  }

  // For Database
  Map<String, dynamic> toMapForDb() {
    return {
      // 'user_media_item_id': id, // This will be autogenerated by SQLite
      'media_item_id': mediaItem.id,
      'status': status.toString().split('.').last, // e.g., "watched"
      'userRating': userRating,
      'userComment': userComment,
      'dateAdded': dateAdded.toIso8601String(),
    };
  }

  factory UserMediaItem.fromDbMap(Map<String, dynamic> map, MediaItem mediaItem) {
    return UserMediaItem(
      mediaItem: mediaItem,
      status: MediaStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => MediaStatus.wantToWatch, // Default if status is invalid
      ),
      userRating: map['userRating'] as int?,
      userComment: map['userComment'] as String?,
      dateAdded: map['dateAdded'] != null ? DateTime.parse(map['dateAdded']) : DateTime.now(),
    );
  }
}
