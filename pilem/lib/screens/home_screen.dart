import 'package:flutter/material.dart';
import 'package:pilem/screens/detail_screen.dart';
import 'package:pilem/models/movie.dart';
import 'package:pilem/services/api_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();

  List<Movie> _allMovies = [];
  List<Movie> _trendingMovies = [];
  List<Movie> _popularMovies = [];

  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  Future<void> _loadMovies() async {
    final List<Map<String, dynamic>> allMoviesData =
        await _apiService.getAllMovies();
    final List<Map<String, dynamic>> trendingMoviesData =
        await _apiService.getTrendingMovie();
    final List<Map<String, dynamic>> popularMoviesData =
        await _apiService.getPopularMovie();

    setState(() {
      _allMovies = allMoviesData.map((e) => Movie.fromJson(e)).toList();
      _trendingMovies = trendingMoviesData.map((e) => Movie.fromJson(e)).toList();
      _popularMovies = popularMoviesData.map((e) => Movie.fromJson(e)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilem'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMoviesList('All Movies', _allMovies),
            _buildMoviesList('Trending Movies', _trendingMovies),
            _buildMoviesList('Popular Movies', _popularMovies),
          ],
        ),
      ),
    );
  }

  Widget _buildMoviesList(String title, List<Movie> movies) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: movies.length,
            itemBuilder: (BuildContext context, int index) {
              final movie = movies[index]; // Ambil movie dari index
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailScreen(movie: movie),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Image.network(
                        'https://image.tmdb.org/t/p/w500${movie.posterPath}',
                        height: 150,
                        width: 100,
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        movie.title.length > 14
                            ? '${movie.title.substring(0, 10)}...'
                            : movie.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        )
      ],
    );
  }
}