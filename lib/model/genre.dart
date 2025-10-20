import 'package:meta/meta.dart';
import '../util/model.dart';

@immutable
class Genre {
  final String genreId;
  final String genreName;
  final String? description;
  final DateTime? createdAt;

  const Genre({
    required this.genreId,
    required this.genreName,
    this.description,
    this.createdAt,
  });

  factory Genre.fromJson(Map<String, dynamic> j) => Genre(
    genreId    : (j['genreId'] ?? j['id'] ?? '').toString(),
    genreName  : (j['genreName'] ?? j['name'] ?? '').toString(),
    description: j['description']?.toString(),
    createdAt  : parseInstant(j['createdAt']),
  );

  Map<String, dynamic> toJson() => {
    'genreId'    : genreId,
    'genreName'  : genreName,
    'description': description,
    'createdAt'  : createdAt?.toIso8601String(),
  };

  String get id => genreId;
  String get name => genreName;
}
