import 'package:meta/meta.dart';

@immutable
class UserQuizResult {
  final String resultId;
  final int score;
  final int attemptCount;
  final int correctCount;
  final int questionCount;
  final DateTime? updatedAt;
  final DateTime? createdAt;
  final bool? isComplete;
  final bool? isReward;
  final int coin;
  final String isActived;
  final String quizId;
  final String userId;

  const UserQuizResult({
    required this.resultId,
    this.score = 0,
    this.attemptCount = 0,
    this.correctCount = 0,
    this.questionCount = 0,
    this.updatedAt,
    this.createdAt,
    this.isComplete,
    this.isReward,
    this.coin = 0,
    this.isActived = 'ACTIVE',
    required this.quizId,
    required this.userId,
  });

  factory UserQuizResult.fromJson(Map<String, dynamic> j) => UserQuizResult(
    resultId: (j['resultId'] ?? '').toString(),
    score: j['score'] is int
        ? j['score'] as int
        : int.tryParse('${j['score'] ?? 0}') ?? 0,
    attemptCount: j['attemptCount'] is int
        ? j['attemptCount'] as int
        : int.tryParse('${j['attemptCount'] ?? 0}') ?? 0,
    correctCount: j['correctCount'] is int
        ? j['correctCount'] as int
        : int.tryParse('${j['correctCount'] ?? 0}') ?? 0,
    questionCount: j['questionCount'] is int
        ? j['questionCount'] as int
        : int.tryParse('${j['questionCount'] ?? 0}') ?? 0,
    updatedAt: j['updatedAt'] != null
        ? DateTime.tryParse('${j['updatedAt']}')
        : null,
    createdAt: j['createdAt'] != null
        ? DateTime.tryParse('${j['createdAt']}')
        : null,
    isComplete: _parseBool(j['isComplete']),
    isReward: _parseBool(j['isReward']),
    coin: j['coin'] is int
        ? j['coin'] as int
        : int.tryParse('${j['coin'] ?? 0}') ?? 0,
    isActived: (j['isActived'] ?? '').toString(),
    quizId: (j['quizId'] ?? '').toString(),
    userId: (j['userId'] ?? '').toString(),
  );
}

bool? _parseBool(dynamic v) {
  if (v == null) return null;
  if (v is bool) return v;
  final s = v.toString().toLowerCase();
  if (s == 'true' || s == '1') return true;
  if (s == 'false' || s == '0') return false;
  return null;
}
