import 'package:meta/meta.dart';

@immutable
class Blog {
  final String blogId;
  final String title;
  final String? content;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? authorId;
  final String? bookId;
  final String isActived;

  /// BE mới:
  final String? coverUrl;
  final List<String> tagIds;
  final List<String> tagNames;

  const Blog({
    required this.blogId,
    required this.title,
    this.content,
    this.createdAt,
    this.updatedAt,
    this.authorId,
    this.bookId,
    this.isActived = 'ACTIVE',
    this.coverUrl,
    this.tagIds = const [],
    this.tagNames = const [],
  });

  /// Dùng cho UI
  String? get coverImageUrl =>
      (coverUrl != null && coverUrl!.trim().isNotEmpty) ? coverUrl : null;

  factory Blog.fromJson(Map<String, dynamic> j) => Blog(
    blogId   : (j['blogId'] ?? '').toString(),
    title    : (j['title'] ?? '').toString(),
    content  : j['content']?.toString(),
    createdAt: j['createdAt'] != null ? DateTime.tryParse('${j['createdAt']}') : null,
    updatedAt: j['updatedAt'] != null ? DateTime.tryParse('${j['updatedAt']}') : null,
    authorId : j['authorId']?.toString(),
    bookId   : j['bookId']?.toString(),
    isActived: (j['isActived'] ?? '').toString(),
    coverUrl : j['coverUrl']?.toString(),
    tagIds   : (j['tagIds']   as List? ?? const []).map((e) => '$e').toList(),
    tagNames : (j['tagNames'] as List? ?? const []).map((e) => '$e').toList(),
  );
}
