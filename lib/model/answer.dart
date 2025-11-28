import 'package:meta/meta.dart';

@immutable
class Answer {
  final String answerId;
  final String content;
  final bool? isCorrect;
  final DateTime? updatedAt;
  final DateTime? createdAt;
  final String isActived;
  final String questionId;

  const Answer({
    required this.answerId,
    required this.content,
    this.isCorrect,
    this.updatedAt,
    this.createdAt,
    this.isActived = 'ACTIVE',
    required this.questionId,
  });

  factory Answer.fromJson(Map<String, dynamic> j) => Answer(
    answerId: (j['answerId'] ?? '').toString(),
    content: (j['content'] ?? '').toString(),
    isCorrect: _parseBool(j['isCorrect']),
    updatedAt: j['updatedAt'] != null
        ? DateTime.tryParse('${j['updatedAt']}')
        : null,
    createdAt: j['createdAt'] != null
        ? DateTime.tryParse('${j['createdAt']}')
        : null,
    isActived: (j['isActived'] ?? '').toString(),
    questionId: (j['questionId'] ?? '').toString(),
  );
}

/// Helper parse bool từ các dạng khác nhau (bool, "true"/"false", 1/0, ...)
bool? _parseBool(dynamic v) {
  if (v == null) return null;
  if (v is bool) return v;
  final s = v.toString().toLowerCase();
  if (s == 'true' || s == '1') return true;
  if (s == 'false' || s == '0') return false;
  return null;
}
