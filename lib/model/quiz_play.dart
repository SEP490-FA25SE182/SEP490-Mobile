import 'package:meta/meta.dart';

@immutable
class QuizPlay {
  final String quizId;
  final String title;
  final int totalScore;
  final int questionCount;
  final List<QuestionPlay> questions;

  const QuizPlay({
    required this.quizId,
    required this.title,
    this.totalScore = 0,
    this.questionCount = 0,
    this.questions = const [],
  });

  factory QuizPlay.fromJson(Map<String, dynamic> j) => QuizPlay(
    quizId: (j['quizId'] ?? '').toString(),
    title: (j['title'] ?? '').toString(),
    totalScore: j['totalScore'] is int
        ? j['totalScore'] as int
        : int.tryParse('${j['totalScore'] ?? 0}') ?? 0,
    questionCount: j['questionCount'] is int
        ? j['questionCount'] as int
        : int.tryParse('${j['questionCount'] ?? 0}') ?? 0,
    questions: (j['questions'] as List? ?? const [])
        .whereType<Map>()
        .map((e) =>
        QuestionPlay.fromJson(e.cast<String, dynamic>()))
        .toList(),
  );
}

@immutable
class QuestionPlay {
  final String questionId;
  final String content;
  final int score;
  final int answerCount;
  final List<AnswerPlay> answers;

  const QuestionPlay({
    required this.questionId,
    required this.content,
    this.score = 0,
    this.answerCount = 0,
    this.answers = const [],
  });

  factory QuestionPlay.fromJson(Map<String, dynamic> j) => QuestionPlay(
    questionId: (j['questionId'] ?? '').toString(),
    content: (j['content'] ?? '').toString(),
    score: j['score'] is int
        ? j['score'] as int
        : int.tryParse('${j['score'] ?? 0}') ?? 0,
    answerCount: j['answerCount'] is int
        ? j['answerCount'] as int
        : int.tryParse('${j['answerCount'] ?? 0}') ?? 0,
    answers: (j['answers'] as List? ?? const [])
        .whereType<Map>()
        .map((e) =>
        AnswerPlay.fromJson(e.cast<String, dynamic>()))
        .toList(),
  );
}

@immutable
class AnswerPlay {
  final String answerId;
  final String content;
  final bool? isCorrect;

  const AnswerPlay({
    required this.answerId,
    required this.content,
    this.isCorrect,
  });

  factory AnswerPlay.fromJson(Map<String, dynamic> j) => AnswerPlay(
    answerId: (j['answerId'] ?? '').toString(),
    content: (j['content'] ?? '').toString(),
    isCorrect: _parseBool(j['isCorrect']),
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
