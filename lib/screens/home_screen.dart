import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/media_item.dart';
import 'media_detail_screen.dart'; // Import the detail screen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  List<MediaItem> _searchResults = [];
  bool _isLoading = false;
  String _errorMessage = '';
  bool _hasSearched = false; // Track if a search has been performed

  void _performSearch() async {
    if (_searchController.text.isEmpty) {
      setState(() {
        _searchResults = [];
        _errorMessage = ''; // Clear error message when search text is empty
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _hasSearched = true; // Mark that a search has been performed
    });
    try {
      _searchResults = await _apiService.searchMedia(_searchController.text);
      if (_searchResults.isEmpty && _searchController.text.isNotEmpty) {
        _errorMessage = 'Nenhum resultado encontrado para "${_searchController.text}".';
      }
    } catch (e) {
      _errorMessage = 'Erro ao buscar: ${e.toString()}';
      _searchResults = [];
      print('Error searching: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToDetail(MediaItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MediaDetailScreen(searchResultItem: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cine Cult: Seu Catálogo'), // Updated title
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar Filmes ou Séries',
                hintText: 'Digite o nome do filme ou série',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _performSearch,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onSubmitted: (_) => _performSearch(),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_errorMessage.isNotEmpty)
              Center(child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 16), textAlign: TextAlign.center),
              ))
            else if (_searchResults.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final item = _searchResults[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        leading: item.posterUrl != null && item.posterUrl!.isNotEmpty && item.posterUrl! != 'N/A'
                            ? Image.network(
                                item.posterUrl!,
                                width: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.movie, size: 50); // Placeholder on error
                                },
                              )
                            : const Icon(Icons.movie, size: 50), // Placeholder if no poster
                        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${item.type?.toUpperCase() ?? "N/A"} - ${item.releaseYear ?? "N/A"}'),
                        onTap: () => _navigateToDetail(item),
                      ),
                    );
                  },
                ),
              )
            else if (_hasSearched && _searchResults.isEmpty && !_isLoading) // Show if search was done, no results, not loading
              const Center(child: Text('Nenhum resultado encontrado.', style: TextStyle(fontSize: 16)))
            else if (!_hasSearched && !_isLoading) // Show only if not loading and no search has been made yet
              const Center(child: Text('Digite algo para buscar filmes ou séries.', style: TextStyle(fontSize: 16, color: Colors.grey)))
            // The case for "no results found" is handled by _errorMessage or the specific condition above
          ],
        ),
      ),
    );
  }
}
