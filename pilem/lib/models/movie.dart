class Movie {
  final String title;
  final String posterPath;
  final String backdropPath;
  final String overview;
  final String releaseDate;
  final double voteAverage;

  Movie({
    required this.title,
    required this.posterPath,
    required this.backdropPath,
    required this.overview,
    required this.releaseDate,
    required this.voteAverage,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      title: json['title'] ?? 'No Title',
      posterPath: json['poster_path'] ?? '',
      backdropPath: json['backdrop_path'] ?? '',
      overview: json['overview'] ?? 'No Overview',
      releaseDate: json['release_date'] ?? 'Unknown',
      voteAverage: (json['vote_average'] ?? 0).toDouble(),
    );
  }
}