import 'package:flutter/material.dart';

import '../../model/quiz_result.dart';
import '../../widget/gs_image.dart';
import '../style/button.dart';

const _disappointedIconUrl =
    'gs://sep490-fa25se182.firebasestorage.app/icon/disappointed.png';
const _coinIconUrl =
    'gs://sep490-fa25se182.firebasestorage.app/icon/coin.png';

class ResultFailScreen extends StatelessWidget {
  final UserQuizResult result;
  final VoidCallback onBackHome;
  final VoidCallback onViewAnswer;

  const ResultFailScreen({
    super.key,
    required this.result,
    required this.onBackHome,
    required this.onViewAnswer,
  });

  @override
  Widget build(BuildContext context) {
    final correct = result.correctCount;
    final total = result.questionCount;
    final isComplete = result.isComplete == true;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0B2B5B),
            Color(0xFF04152C),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Thật tiếc quá',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: 120,
            height: 120,
            child: GsImage(
              url: _disappointedIconUrl,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 24),

          Text(
            isComplete
                ? 'Bạn đã hoàn thành quiz'
                : 'Bạn chưa hoàn thành quiz',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Bạn chỉ đúng $correct/$total câu',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Số điểm đạt được: ${result.score}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white70, width: 1.2),
              color: Colors.white.withOpacity(0.04),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lượt làm bài thứ: ${result.attemptCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Bạn được thưởng: ${result.coin}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GsImage(
                      url: _coinIconUrl,
                      width: 18,
                      height: 18,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ButtonSoft(
              text: 'Trở về trang chủ',
              onTap: onBackHome,
              borderRadius: 12,
            ),
          ),
        ],
      ),
    );
  }
}
