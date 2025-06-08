// filepath: c:\Users\arthu\AndroidStudioProjects\cine_cult\lib\screens\want_to_watch_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/user_list_service.dart';
import 'media_detail_screen.dart';
import 'add_edit_rating_screen.dart';

class WantToWatchScreen extends StatelessWidget {
  const WantToWatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Consumer to listen to changes in UserListService
    return Consumer<UserListService>(
      builder: (context, userListService, child) {
        final wantToWatchList = userListService.wantToWatchList;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Quero Ver'),
          ),
          body: wantToWatchList.isEmpty
              ? const Center(
                  child: Text(
                    'Sua lista "Quero Ver" está vazia.\nAdicione filmes e séries da tela de busca!',
                    style: TextStyle(fontSize: 18.0, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: wantToWatchList.length,
                  itemBuilder: (context, index) {
                    final userItem = wantToWatchList[index];
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
                        subtitle: Text('${item.type?.toUpperCase() ?? "N/A"} - ${item.releaseYear ?? "N/A"}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                              tooltip: 'Marcar como assistido',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddEditRatingScreen(userMediaItem: userItem),
                                  ),
                                ).then((savedRatingData) {
                                  if (savedRatingData is Map<String, dynamic>) {
                                     userListService.moveToWatched(
                                        userItem,
                                        rating: savedRatingData['rating'],
                                        comment: savedRatingData['comment'],
                                      );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('"${item.title}" movido para "Já Assisti" com avaliação.')),
                                    );
                                  } else if (savedRatingData == true) { // Moved without explicit rating save
                                    userListService.moveToWatched(userItem);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('"${item.title}" movido para "Já Assisti".')),
                                    );
                                  }
                                  // If user backs out, savedRatingData might be null, do nothing.
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              tooltip: 'Remover da lista',
                              onPressed: () {
                                userListService.removeFromWantToWatch(item.id);
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
