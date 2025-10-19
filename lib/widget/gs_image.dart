import 'package:flutter/material.dart';

/// Chuyển gs
String gsToHttp(String url) {
  if (url.isEmpty || !url.startsWith('gs://')) return url;
  final without = url.substring(5);
  final idx = without.indexOf('/');
  if (idx <= 0) return url;
  final bucket = without.substring(0, idx);
  final path = Uri.encodeComponent(without.substring(idx + 1));
  return 'https://firebasestorage.googleapis.com/v0/b/$bucket/o/$path?alt=media';
}

class GsImage extends StatelessWidget {
  /// Nhận url dạng `gs://...` hoặc `https://...`
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;

  const GsImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final httpUrl = url.startsWith('gs://') ? gsToHttp(url) : url;

    // debug để biết URL đã được convert đúng chưa
    // ignore: avoid_print
    print('[GsImage] $url  ->  $httpUrl');

    return Image.network(
      httpUrl,
      width: width,
      height: height,
      fit: fit,
      filterQuality: FilterQuality.medium,
      loadingBuilder: (c, child, p) =>
      p == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFF0E1B33),
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported_rounded, color: Colors.redAccent),
      ),
    );
  }
}
