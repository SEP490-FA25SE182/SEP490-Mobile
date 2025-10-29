import 'package:meta/meta.dart';
import 'genre.dart';
import '../util/model.dart';

@immutable
class Book {
  final String bookId;
  final String bookName;
  final String? authorId;
  final double? price;
  final int? quantity;
  final String coverUrl;
  final String? description;
  final int? progressStatus;
  final int? publicationStatus;
  final String? bookshelveId;
  final String isActived;
  final DateTime? updatedAt;
  final DateTime? createdAt;
  final DateTime? publishedDate;
  final List<Genre> genres;

  const Book({
    required this.bookId,
    required this.bookName,
    required this.coverUrl,
    this.authorId,
    this.price,
    this.quantity,
    this.description,
    this.progressStatus,
    this.publicationStatus,
    this.bookshelveId,
    this.isActived = 'ACTIVE',
    this.updatedAt,
    this.createdAt,
    this.publishedDate,
    this.genres = const [],
  });

  factory Book.fromJson(Map<String, dynamic> j) {
    final g = ((j['genres'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(Genre.fromJson)
        .toList();

    int? _int(dynamic v) =>
        v is int ? v : int.tryParse(v?.toString() ?? '');

    double? _double(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return Book(
      bookId           : (j['bookId'] ?? '').toString(),
      bookName         : (j['bookName'] ?? '').toString(),
      authorId         : j['authorId']?.toString(),
      price            : _double(j['price']),
      quantity         : _int(j['quantity']),
      coverUrl         : (j['coverUrl'] ?? '').toString(),
      description      : (j['decription'] ?? j['description'])?.toString(),
      progressStatus   : _int(j['progressStatus']),
      publicationStatus: _int(j['publicationStatus']),
      bookshelveId     : j['bookshelveId']?.toString(),
      isActived        : (j['isActived'] ?? 'ACTIVE').toString(),
      updatedAt        : parseInstant(j['updatedAt']),
      createdAt        : parseInstant(j['createdAt']),
      publishedDate    : parseInstant(j['publishedDate']),
      genres           : g,
    );
  }

  Map<String, dynamic> toJson() => {
    'bookId'           : bookId,
    'bookName'         : bookName,
    'authorId'         : authorId,
    'price'            : price,
    'quantity'         : quantity,
    'coverUrl'         : coverUrl,
    'decription'       : description,
    'progressStatus'   : progressStatus,
    'publicationStatus': publicationStatus,
    'bookshelveId'     : bookshelveId,
    'isActived'        : isActived,
    'updatedAt'        : updatedAt?.toIso8601String(),
    'createdAt'        : createdAt?.toIso8601String(),
    'publishedDate'    : publishedDate?.toIso8601String(),
    'genres'           : genres.map((e) => e.toJson()).toList(),
  };
}
