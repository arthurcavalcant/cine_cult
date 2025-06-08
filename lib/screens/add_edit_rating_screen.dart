// filepath: c:\Users\arthu\AndroidStudioProjects\cine_cult\lib\screens\add_edit_rating_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_media_item.dart';
import '../services/user_list_service.dart';

class AddEditRatingScreen extends StatefulWidget {
  final UserMediaItem userMediaItem;

  const AddEditRatingScreen({super.key, required this.userMediaItem});

  @override
  State<AddEditRatingScreen> createState() => _AddEditRatingScreenState();
}

class _AddEditRatingScreenState extends State<AddEditRatingScreen> {
  late int _currentRating;
  late TextEditingController _commentController;
  final _formKey = GlobalKey<FormState>(); // For optional validation

  @override
  void initState() {
    super.initState();
    _currentRating = widget.userMediaItem.userRating ?? 0;
    _commentController = TextEditingController(text: widget.userMediaItem.userComment ?? '');
  }

  void _submitRating() {
    // No need for form validation if fields are optional or handled by UI (stars)
    // if (_formKey.currentState!.validate()) {
    //   _formKey.currentState!.save();

    final userListService = Provider.of<UserListService>(context, listen: false);
    final mediaItem = widget.userMediaItem.mediaItem; // Get the MediaItem
    final newRating = _currentRating > 0 ? _currentRating : null;
    final newComment = _commentController.text.trim();

    // If the item is already in the watched list, update it.
    // Otherwise, the previous screen (MediaDetailScreen or WantToWatchScreen)
    // will handle adding it to the watched list using the data returned by this screen.
    if (userListService.getMediaStatus(mediaItem.id) == MediaStatus.watched) {
      userListService.updateRatingAndComment(mediaItem.id, newRating, newComment);
    } else {
      // This case is for when navigating from WantToWatch or directly from MediaDetail (not yet watched)
      // The UserListService.addToWatched or moveToWatched will be called by the previous screen
      // using the rating data we pop back.
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Avaliação para "${mediaItem.title}" salva!'))
    );
    // Return the rating data so the previous screen can update the service if it was a new add.
    Navigator.pop(context, {'rating': newRating, 'comment': newComment});
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Avaliar "${widget.userMediaItem.mediaItem.title}"'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_alt_outlined),
            tooltip: 'Salvar Avaliação',
            onPressed: _submitRating,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form( // Form is kept for structure, can be removed if no validation needed
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                widget.userMediaItem.mediaItem.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (widget.userMediaItem.mediaItem.posterUrl != null && widget.userMediaItem.mediaItem.posterUrl!.isNotEmpty)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      widget.userMediaItem.mediaItem.posterUrl!,
                      height: 200,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 100),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                'Sua Avaliação (Estrelas):',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _currentRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 40, // Increased star size
                    ),
                    onPressed: () {
                      setState(() {
                        if (_currentRating == index + 1) { // If tapping the same star again
                          _currentRating = 0; // Deselect/clear rating
                        } else {
                          _currentRating = index + 1;
                        }
                      });
                    },
                  );
                }),
              ),
              if (_currentRating > 0)
                Center(
                  child: Text(
                    '$_currentRating de 5 estrelas',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                )
              else
                const Center(
                  child: Text(
                    'Toque nas estrelas para avaliar',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              const SizedBox(height: 24),
              Text(
                'Seu Comentário (Opcional):',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _commentController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Escreva seu comentário aqui...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[50],
                ),
                // No validator needed for optional field
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save_alt_outlined),
                  label: const Text('Salvar Avaliação'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Theme.of(context).colorScheme.onSecondary,
                  ),
                  onPressed: _submitRating,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
