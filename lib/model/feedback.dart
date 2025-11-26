import 'package:meta/meta.dart';
import '../util/model.dart';

enum FeedbackStatus {
  published,
  pending,
  denied;

  @override
  String toString() => name.toUpperCase();
}

enum IsActived {
  active,
  inactive,
  banned;

  @override
  String toString() => name.toUpperCase();
}

@immutable
class BookFeedback {
  final String feedbackId;
  final String? content;
  final int rating;
  final DateTime createdAt;
  final DateTime updatedAt;
  final IsActived isActived;
  final String userId;
  final String bookId;
  final String orderDetailId;
  final List<String>? imageUrls;
  final FeedbackStatus status;

  const BookFeedback({
    required this.feedbackId,
    this.content,
    required this.rating,
    required this.createdAt,
    required this.updatedAt,
    required this.isActived,
    required this.userId,
    required this.bookId,
    required this.orderDetailId,
    this.imageUrls,
    required this.status,
  });

  factory BookFeedback.fromJson(Map<String, dynamic> j) {
    return BookFeedback(
      feedbackId: (j['feedbackId'] ?? j['id'] ?? '').toString(),
      content: j['content']?.toString(),
      rating: _parseByte(j['rating']),
      createdAt: parseInstant(j['createdAt']) ?? DateTime.now(),
      updatedAt: parseInstant(j['updatedAt']) ?? DateTime.now(),
      isActived: _parseIsActived(j['isActived'] ?? j['is_actived']),
      userId: (j['userId'] ?? j['user_id'] ?? '').toString(),
      bookId: (j['bookId'] ?? j['book_id'] ?? '').toString(),
      orderDetailId: (j['orderDetailId'] ?? j['order_detail_id'] ?? '').toString(),
      imageUrls: (j['imageUrls'] as List?)?.cast<String>(),
      status: _parseStatus(j['status']),
    );
  }

  Map<String, dynamic> toJson() => {
    'content': content,
    'rating': rating,
    'userId': userId,
    'bookId': bookId,
    'orderDetailId': orderDetailId,
    if (imageUrls != null && imageUrls!.isNotEmpty) 'imageUrls': imageUrls,
    'status': status.name.toUpperCase(),
  };

  String get id => feedbackId;
}

// Helper parsers
int _parseByte(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

IsActived _parseIsActived(dynamic value) {
  if (value is String) {
    final upper = value.toUpperCase();
    return IsActived.values.firstWhere(
          (e) => e.name.toUpperCase() == upper,
      orElse: () => IsActived.active,
    );
  }
  return IsActived.active;
}

FeedbackStatus _parseStatus(dynamic value) {
  if (value is String) {
    final upper = value.toUpperCase();
    return FeedbackStatus.values.firstWhere(
          (e) => e.name.toUpperCase() == upper,
      orElse: () => FeedbackStatus.pending,
    );
  }
  return FeedbackStatus.pending;
}