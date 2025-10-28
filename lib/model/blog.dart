import 'package:meta/meta.dart';
import 'blog_image.dart';
import 'tag.dart';

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

  /// NEW: url ảnh cover (lấy trực tiếp từ BE)
  final String? coverUrl;

  final List<BlogImage> images;
  final List<Tag> tags;

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
    this.images = const [],
    this.tags = const [],
  });

  /// URL ảnh cover ưu tiên:
  /// 1) `coverUrl` từ BE
  /// 2) Ảnh `position == 0`
  /// 3) Ảnh đầu tiên (nếu có)
  String? get coverImageUrl {
    if ((coverUrl ?? '').trim().isNotEmpty) return coverUrl;
    if (images.isEmpty) return null;
    final sorted = [...images]..sort((a, b) => a.position.compareTo(b.position));
    final zero = sorted.where((e) => e.position == 0).toList();
    return (zero.isNotEmpty ? zero.first.imageUrl : sorted.first.imageUrl);
  }

  factory Blog.fromJson(Map<String, dynamic> j) => Blog(
    blogId: (j['blogId'] ?? '').toString(),
    title: (j['title'] ?? '').toString(),
    content: j['content']?.toString(),
    createdAt: j['createdAt'] != null ? DateTime.tryParse(j['createdAt'].toString()) : null,
    updatedAt: j['updatedAt'] != null ? DateTime.tryParse(j['updatedAt'].toString()) : null,
    authorId: j['authorId']?.toString(),
    bookId: j['bookId']?.toString(),
    isActived: (j['isActived'] ?? '').toString(),
    coverUrl: j['coverUrl']?.toString(),
    images: (j['images'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => BlogImage.fromJson(e.cast<String, dynamic>()))
        .toList(),
    tags: (j['tags'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => Tag.fromJson(e.cast<String, dynamic>()))
        .toList(),
  );
}
