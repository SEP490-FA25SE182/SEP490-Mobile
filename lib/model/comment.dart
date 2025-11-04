import 'package:meta/meta.dart';

@immutable
class Comment {
  final String commentId;
  final String? content;
  final String? name;
  final bool isPublished;
  final DateTime? updatedAt;
  final DateTime? createdAt;
  final String isActived;
  final String userId;
  final String blogId;

  const Comment({
    required this.commentId,
    this.content,
    this.name,
    this.isPublished = true,
    this.updatedAt,
    this.createdAt,
    this.isActived = 'ACTIVE',
    required this.userId,
    required this.blogId,
  });

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    return DateTime.tryParse(s);
  }

  static bool _parseBool(dynamic v) {
    if (v is bool) return v;
    if (v == null) return false;
    final s = v.toString().toLowerCase();
    return s == 'true' || s == '1';
  }

  factory Comment.fromJson(Map<String, dynamic> j) => Comment(
    commentId : (j['commentId'] ?? '').toString(),
    content   : j['content']?.toString(),
    name      : j['name']?.toString(),
    isPublished: _parseBool(j['isPublished']),
    updatedAt : _parseDate(j['updatedAt']),
    createdAt : _parseDate(j['createdAt']),
    isActived : (j['isActived'] ?? 'ACTIVE').toString(),
    userId    : (j['userId'] ?? '').toString(),
    blogId    : (j['blogId'] ?? '').toString(),
  );

  Map<String, dynamic> toJson() => {
    'commentId' : commentId,
    'content'   : content,
    'name'      : name,
    'isPublished': isPublished,
    'updatedAt' : updatedAt?.toIso8601String(),
    'createdAt' : createdAt?.toIso8601String(),
    'isActived' : isActived,
    'userId'    : userId,
    'blogId'    : blogId,
  };
}
