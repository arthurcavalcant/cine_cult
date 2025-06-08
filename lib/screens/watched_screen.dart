// filepath: c:\Users\arthu\AndroidStudioProjects\cine_cult\lib\screens\watched_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/user_list_service.dart';
import 'media_detail_screen.dart';
import 'add_edit_rating_screen.dart';

class WatchedScreen extends StatelessWidget {
  const WatchedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserListService>(
      builder: (context, userListService, child) {
        final watchedList = userListService.watchedList;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Já Assisti'),
          ),
          body: watchedList.isEmpty
              ? const Center(
                  child: Text(
                    'Sua lista "Já Assisti" está vazia.\nAdicione itens marcando-os como assistidos!',
                    style: TextStyle(fontSize: 18.0, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: watchedList.length,
                  itemBuilder: (context, index) {
                    final userItem = watchedList[index];
                    final item = userItem.mediaItem;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6.0),
                      elevation: 3,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        leading: item.posterUrl != null && item.posterUrl!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(4.0),
                                child: Image.network(
                                  item.posterUrl!,
                                  width: 60,
                                  height: 90,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.movie, size: 50),
                                ),
                              )
                            : const Icon(Icons.movie, size: 50),
                        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${item.type?.toUpperCase() ?? "N/A"} - ${item.releaseYear ?? "N/A"}'),
                            if (userItem.userRating != null && userItem.userRating! > 0)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(5, (i) => Icon(
                                  i < userItem.userRating! ? Icons.star : Icons.star_border,
                                  color: Colors.amber,
                                  size: 18,
                                )),
                              ),
                            if (userItem.userComment != null && userItem.userComment!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'Comentário: ${userItem.userComment}',
                                  style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_note, color: Colors.blueAccent),
                              tooltip: 'Editar avaliação',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddEditRatingScreen(userMediaItem: userItem),
                                  ),
                                );
                                // UserListService will be notified by AddEditRatingScreen upon saving
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              tooltip: 'Remover da lista',
                              onPressed: () {
                                userListService.removeFromWatched(item.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('"${item.title}" removido da lista.')),
                                );
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => MediaDetailScreen(searchResultItem: item)),
                          );
                        },
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
