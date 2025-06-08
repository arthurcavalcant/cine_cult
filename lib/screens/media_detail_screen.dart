import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/media_item.dart';
import '../models/user_media_item.dart';
import '../services/api_service.dart';
import '../services/user_list_service.dart';
import 'add_edit_rating_screen.dart';

class MediaDetailScreen extends StatefulWidget {
  final MediaItem searchResultItem;

  const MediaDetailScreen({super.key, required this.searchResultItem});

  @override
  State<MediaDetailScreen> createState() => _MediaDetailScreenState();
}

class _MediaDetailScreenState extends State<MediaDetailScreen> {
  final ApiService _apiService = ApiService();
  MediaItem? _detailedItem;
  bool _isLoading = true;
  String? _errorMessage;
  UserMediaItem? _userMediaStatusItem;

  @override
  void initState() {
    super.initState();
    _fetchDetailsAndStatus();
  }

  Future<void> _fetchDetailsAndStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final item = await _apiService.getMediaDetails(widget.searchResultItem.id);
      if (mounted) {
        setState(() {
          _detailedItem = item ?? widget.searchResultItem; // Use search item as fallback
          // Check status after fetching details
          _userMediaStatusItem = Provider.of<UserListService>(context, listen: false)
              .getUserMediaItem(widget.searchResultItem.id);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao carregar detalhes: ${e.toString()}';
          _detailedItem = widget.searchResultItem; // Fallback in case of error
        });
      }
      print('Error fetching details: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemToDisplay = _detailedItem ?? widget.searchResultItem;
    final userListService = Provider.of<UserListService>(context);
    // Determine current status for button states after build method is called
    // This ensures we have the latest status if it changes elsewhere
    final currentStatus = userListService.getMediaStatus(itemToDisplay.id);
    final isInWantToWatch = currentStatus == MediaStatus.wantToWatch;
    final isInWatched = currentStatus == MediaStatus.watched;

    return Scaffold(
      appBar: AppBar(
        title: Text(itemToDisplay.title),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 16), textAlign: TextAlign.center),
                ))
              : itemToDisplay.title == 'N/A' && itemToDisplay.id == 'N/A'
                  ? const Center(child: Text('Detalhes não disponíveis.'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          if (itemToDisplay.posterUrl != null && itemToDisplay.posterUrl!.isNotEmpty)
                            Center(
                              child: Image.network(
                                itemToDisplay.posterUrl!,
                                height: 300,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 150),
                              ),
                            ),
                          const SizedBox(height: 16.0),
                          Text(
                            itemToDisplay.title,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8.0),
                          Text('Ano: ${itemToDisplay.releaseYear ?? "N/A"}'),
                          Text('Tipo: ${itemToDisplay.type?.toUpperCase() ?? "N/A"}'),
                          if (itemToDisplay.genre != null) Text('Gênero: ${itemToDisplay.genre}'),
                          if (itemToDisplay.runtime != null) Text('Duração: ${itemToDisplay.runtime}'),
                          if (itemToDisplay.publicRating != null) Text('Avaliação IMDb: ${itemToDisplay.publicRating}/10'),
                          const SizedBox(height: 16.0),
                          Text(
                            'Sinopse',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(itemToDisplay.synopsis ?? 'Sinopse não disponível.'),
                          const SizedBox(height: 16.0),
                          if (itemToDisplay.cast != null && itemToDisplay.cast!.isNotEmpty)
                            Text(
                              'Elenco',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          if (itemToDisplay.cast != null)
                            Wrap(
                              spacing: 6.0, // gap between adjacent chips
                              runSpacing: 4.0, // gap between lines
                              children: itemToDisplay.cast!.map((actor) => Chip(label: Text(actor))).toList(),
                            ),
                          const SizedBox(height: 24.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                icon: Icon(isInWantToWatch ? Icons.remove_red_eye : Icons.visibility_outlined),
                                label: Text(isInWantToWatch ? 'Na Lista Quero Ver' : 'Quero Ver'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isInWantToWatch ? Colors.blue[300] : Colors.blue[100],
                                  foregroundColor: isInWantToWatch ? Colors.white : Colors.black87,
                                ),
                                onPressed: () {
                                  if (isInWantToWatch) {
                                    userListService.removeFromWantToWatch(itemToDisplay.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('"${itemToDisplay.title}" removido da lista "Quero Ver"')),
                                    );
                                  } else {
                                    userListService.addToWantToWatch(itemToDisplay);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('"${itemToDisplay.title}" adicionado à lista "Quero Ver"')),
                                    );
                                  }
                                  // No need to call setState, Provider will update the UI
                                },
                              ),
                              ElevatedButton.icon(
                                icon: Icon(isInWatched ? Icons.check_circle : Icons.check_circle_outline),
                                label: Text(isInWatched ? 'Assistido' : 'Já Assisti'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isInWatched ? Colors.green[300] : Colors.green[100],
                                  foregroundColor: isInWatched ? Colors.white : Colors.black87,
                                ),
                                onPressed: () {
                                  if (isInWatched) {
                                    // Option to re-rate or view details - navigate to rating screen
                                    final existingUserItem = userListService.getUserMediaItem(itemToDisplay.id) ?? UserMediaItem(mediaItem: itemToDisplay, status: MediaStatus.watched);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AddEditRatingScreen(userMediaItem: existingUserItem),
                                      ),
                                    );
                                  } else {
                                    // Add to watched and then navigate to rating screen
                                    // Create a temporary UserMediaItem for the rating screen
                                    final newUserItem = UserMediaItem(mediaItem: itemToDisplay, status: MediaStatus.watched);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AddEditRatingScreen(userMediaItem: newUserItem),
                                      ),
                                    ).then((savedRatingData) {
                                      if (savedRatingData is Map<String, dynamic>) {
                                        userListService.addToWatched(
                                          itemToDisplay,
                                          rating: savedRatingData['rating'],
                                          comment: savedRatingData['comment'],
                                        );
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('"${itemToDisplay.title}" adicionado à lista "Já Assisti" com avaliação.')),
                                        );
                                      } else if (savedRatingData == true) { // Fallback if only boolean is returned
                                         userListService.addToWatched(itemToDisplay); // Add without rating if screen was popped without saving
                                         ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('"${itemToDisplay.title}" adicionado à lista "Já Assisti". Avalie mais tarde.')),
                                        );
                                      }
                                      // If user backs out, savedRatingData might be null, do nothing or add without rating
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16.0),
                          if (isInWatched && _userMediaStatusItem?.userRating != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Sua Avaliação:', style: Theme.of(context).textTheme.titleMedium),
                                  Row(
                                    children: List.generate(5, (i) => Icon(
                                      i < (_userMediaStatusItem!.userRating ?? 0) ? Icons.star : Icons.star_border,
                                      color: Colors.amber,
                                      size: 24,
                                    )),
                                  ),
                                  if (_userMediaStatusItem!.userComment != null && _userMediaStatusItem!.userComment!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text('Seu Comentário: ${_userMediaStatusItem!.userComment}'),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
    );
  }
}
