  import 'package:meta/meta.dart';
import '../util/model.dart';
import 'book.dart';

@immutable
class Bookshelve {
  final String bookshelveId;
  final String? bookshelveName;
  final String? decription;
  final DateTime? updatedAt;
  final DateTime? createdAt;
  final IsActived isActived;
  final String userId;
  final List<Book> books;       

  const Bookshelve({
    required this.bookshelveId,
    this.bookshelveName,
    this.decription,
    this.updatedAt,
    this.createdAt,
    this.isActived = IsActived.ACTIVE,
    required this.userId,
    this.books = const [],
  });

  factory Bookshelve.fromJson(Map<String, dynamic> j) {
    final bs = ((j['books'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(Book.fromJson)
        .toList();

    return Bookshelve(
      bookshelveId : (j['bookshelveId'] ?? '').toString(),
      bookshelveName: j['bookshelveName']?.toString(),
      decription   : j['decription']?.toString(),
      updatedAt    : parseInstant(j['updatedAt']),
      createdAt    : parseInstant(j['createdAt']),
      isActived    : parseIsActived(j['isActived']),
      userId       : (j['userId'] ?? '').toString(),
      books        : bs,
    );
  }

  Map<String, dynamic> toJson() => {
    'bookshelveId'  : bookshelveId,
    'bookshelveName': bookshelveName,
    'decription'    : decription,
    'updatedAt'     : updatedAt?.toIso8601String(),
    'createdAt'     : createdAt?.toIso8601String(),
    'isActived'     : isActivedToJson(isActived),
    'userId'        : userId,
    'books'         : books.map((e) => e.toJson()).toList(),
  };
}
