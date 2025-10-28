import 'package:meta/meta.dart';

@immutable
class BlogImage {
  final String blogImageId;
  final String imageUrl;
  final String? altText;
  final int position;
  final String blogId;
  final String isActived; 

  const BlogImage({
    required this.blogImageId,
    required this.imageUrl,
    this.altText,
    this.position = 0,
    required this.blogId,
    this.isActived = 'ACTIVE',
  });

  bool get isCover => position == 0;

  factory BlogImage.fromJson(Map<String, dynamic> j) => BlogImage(
    blogImageId: (j['blogImageId'] ?? '').toString(),
    imageUrl: (j['imageUrl'] ?? '').toString(),
    altText: j['altText']?.toString(),
    position: int.tryParse('${j['position'] ?? 0}') ?? 0,
    blogId: (j['blogId'] ?? '').toString(),
    isActived: (j['isActived'] ?? '').toString(),
  );
}
