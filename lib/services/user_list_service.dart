// filepath: c:\Users\arthu\AndroidStudioProjects\cine_cult\lib\services\user_list_service.dart
import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../models/media_item.dart';
import '../models/user_media_item.dart';
import 'database_helper.dart'; // Import DatabaseHelper

class UserListService extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper(); // Instance of DatabaseHelper
  List<UserMediaItem> _wantToWatchList = [];
  List<UserMediaItem> _watchedList = [];

  UnmodifiableListView<UserMediaItem> get wantToWatchList => UnmodifiableListView(_wantToWatchList);
  UnmodifiableListView<UserMediaItem> get watchedList => UnmodifiableListView(_watchedList);

  // Initialization method to load data from DB
  Future<void> init() async {
    await _dbHelper.database; // Ensure database is initialized
    await _loadListsFromDb();
    notifyListeners();
  }

  Future<void> _loadListsFromDb() async {
    _wantToWatchList = await _dbHelper.getUserMediaItemsByStatus(MediaStatus.wantToWatch);
    _watchedList = await _dbHelper.getUserMediaItemsByStatus(MediaStatus.watched);
  }

  // Check if an item is in any list and return its status
  MediaStatus? getMediaStatus(String mediaId) {
    if (_wantToWatchList.any((item) => item.mediaItem.id == mediaId)) {
      return MediaStatus.wantToWatch;
    }
    if (_watchedList.any((item) => item.mediaItem.id == mediaId)) {
      return MediaStatus.watched;
    }
    return null;
  }

  UserMediaItem? getUserMediaItem(String mediaId) {
    UserMediaItem? item = _wantToWatchList.firstWhere((item) => item.mediaItem.id == mediaId,
        orElse: () => _watchedList.firstWhere((item) => item.mediaItem.id == mediaId,
            orElse: () => UserMediaItem(mediaItem: MediaItem(id: '', title: ''), status: MediaStatus.wantToWatch) // Placeholder
        )
    );
    return item.mediaItem.id.isNotEmpty ? item : null;
  }

  Future<void> addToWantToWatch(MediaItem mediaItem) async {
    await _dbHelper.deleteUserMediaItem(mediaItem.id); // Remove from any list first in DB
    _removeFromWatched(mediaItem.id); // Remove from in-memory watched list

    if (!_wantToWatchList.any((item) => item.mediaItem.id == mediaItem.id)) {
      final userItem = UserMediaItem(mediaItem: mediaItem, status: MediaStatus.wantToWatch);
      await _dbHelper.insertUserMediaItem(userItem);
      _wantToWatchList.add(userItem);
      notifyListeners();
    }
  }

  Future<void> addToWatched(MediaItem mediaItem, {int? rating, String? comment}) async {
    await _dbHelper.deleteUserMediaItem(mediaItem.id); // Remove from any list first in DB
    _removeFromWantToWatch(mediaItem.id); // Remove from in-memory wantToWatch list

    final userItem = UserMediaItem(
      mediaItem: mediaItem,
      status: MediaStatus.watched,
      userRating: rating,
      userComment: comment,
    );

    await _dbHelper.insertUserMediaItem(userItem);

    // Update in-memory list
    int existingIndex = _watchedList.indexWhere((item) => item.mediaItem.id == mediaItem.id);
    if (existingIndex != -1) {
      _watchedList[existingIndex] = userItem;
    } else {
      _watchedList.add(userItem);
    }
    notifyListeners();
  }

  Future<void> removeFromWantToWatch(String mediaId) async {
    await _dbHelper.deleteUserMediaItem(mediaId);
    _wantToWatchList.removeWhere((item) => item.mediaItem.id == mediaId);
    notifyListeners();
  }

  void _removeFromWantToWatch(String mediaId) { // Internal helper for in-memory removal
    _wantToWatchList.removeWhere((item) => item.mediaItem.id == mediaId);
  }

  Future<void> removeFromWatched(String mediaId) async {
    await _dbHelper.deleteUserMediaItem(mediaId);
    _watchedList.removeWhere((item) => item.mediaItem.id == mediaId);
    notifyListeners();
  }

  void _removeFromWatched(String mediaId) { // Internal helper for in-memory removal
    _watchedList.removeWhere((item) => item.mediaItem.id == mediaId);
  }

  Future<void> moveToWatched(UserMediaItem userMediaItem, {int? rating, String? comment}) async {
    // This method assumes userMediaItem is from wantToWatchList
    await removeFromWantToWatch(userMediaItem.mediaItem.id); // Removes from DB and in-memory wantToWatch
    await addToWatched(userMediaItem.mediaItem, rating: rating, comment: comment); // Adds to DB and in-memory watched
    // notifyListeners() is called by addToWatched
  }

  Future<void> updateRatingAndComment(String mediaId, int? rating, String? comment) async {
    int index = _watchedList.indexWhere((item) => item.mediaItem.id == mediaId);
    if (index != -1) {
      _watchedList[index].userRating = rating;
      _watchedList[index].userComment = comment;
      _watchedList[index].status = MediaStatus.watched; // Ensure status is correct
      await _dbHelper.updateUserMediaItem(_watchedList[index]);
      notifyListeners();
    }
  }
}

// Simple Service Locator pattern
class ServiceLocator {
  static final UserListService _userListService = UserListService();
  static UserListService get userListService => _userListService;
}
