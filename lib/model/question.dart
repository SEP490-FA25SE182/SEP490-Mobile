import 'package:meta/meta.dart';

@immutable
class Question {
  final String questionId;
  final int score;
  final int answerCount;
  final String content;
  final DateTime? updatedAt;
  final DateTime? createdAt;
  final String isActived;
  final String quizId;

  const Question({
    required this.questionId,
    this.score = 0,
    this.answerCount = 0,
    required this.content,
    this.updatedAt,
    this.createdAt,
    this.isActived = 'ACTIVE',
    required this.quizId,
  });

  factory Question.fromJson(Map<String, dynamic> j) => Question(
    questionId: (j['questionId'] ?? '').toString(),
    score: j['score'] is int
        ? j['score'] as int
        : int.tryParse('${j['score'] ?? 0}') ?? 0,
    answerCount: j['answerCount'] is int
        ? j['answerCount'] as int
        : int.tryParse('${j['answerCount'] ?? 0}') ?? 0,
    content: (j['content'] ?? '').toString(),
    updatedAt: j['updatedAt'] != null
        ? DateTime.tryParse('${j['updatedAt']}')
        : null,
    createdAt: j['createdAt'] != null
        ? DateTime.tryParse('${j['createdAt']}')
        : null,
    isActived: (j['isActived'] ?? '').toString(),
    quizId: (j['quizId'] ?? '').toString(),
  );
}
