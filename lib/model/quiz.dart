import 'package:meta/meta.dart';

@immutable
class Quiz {
  final String quizId;
  final int totalScore;
  final String title;
  final int attemptCount;
  final int questionCount;
  final DateTime? updatedAt;
  final DateTime? createdAt;
  final String isActived;
  final String chapterId;

  const Quiz({
    required this.quizId,
    this.totalScore = 0,
    required this.title,
    this.attemptCount = 0,
    this.questionCount = 0,
    this.updatedAt,
    this.createdAt,
    this.isActived = 'ACTIVE',
    required this.chapterId,
  });

  factory Quiz.fromJson(Map<String, dynamic> j) => Quiz(
    quizId: (j['quizId'] ?? '').toString(),
    totalScore: j['totalScore'] is int
        ? j['totalScore'] as int
        : int.tryParse('${j['totalScore'] ?? 0}') ?? 0,
    title: (j['title'] ?? '').toString(),
    attemptCount: j['attemptCount'] is int
        ? j['attemptCount'] as int
        : int.tryParse('${j['attemptCount'] ?? 0}') ?? 0,
    questionCount: j['questionCount'] is int
        ? j['questionCount'] as int
        : int.tryParse('${j['questionCount'] ?? 0}') ?? 0,
    updatedAt: j['updatedAt'] != null
        ? DateTime.tryParse('${j['updatedAt']}')
        : null,
    createdAt: j['createdAt'] != null
        ? DateTime.tryParse('${j['createdAt']}')
        : null,
    isActived: (j['isActived'] ?? '').toString(),
    chapterId: (j['chapterId'] ?? '').toString(),
  );
}
