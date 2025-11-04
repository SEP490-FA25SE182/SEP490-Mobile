import 'package:meta/meta.dart';
import '../util/model.dart';

@immutable
class AppNotification {
  final String notificationId;
  final String? message;
  final String? title;
  final bool? isRead;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? userId;
  final String? bookId;
  final String? orderId;

  const AppNotification({
    required this.notificationId,
    this.message,
    this.title,
    this.isRead,
    this.createdAt,
    this.updatedAt,
    this.userId,
    this.bookId,
    this.orderId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
    notificationId: j['notificationId'] ?? '',
    message: j['message'],
    title: j['title'],
    isRead: j['isRead'] ?? false,
    createdAt: parseInstant(j['createdAt']),
    updatedAt: parseInstant(j['updatedAt']),
    userId: j['userId'],
    bookId: j['bookId'],
    orderId: j['orderId'],
  );

  Map<String, dynamic> toJson() => {
    'notificationId': notificationId,
    'message': message,
    'title': title,
    'isRead': isRead,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'userId': userId,
    'bookId': bookId,
    'orderId': orderId,
  };
}
