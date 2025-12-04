import 'dart:convert';
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:flutter_embed_unity/flutter_embed_unity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../provider.dart';

const MethodChannel _unityBridgeChannel = MethodChannel('flutter_unity_bridge');

class UnityPage extends ConsumerStatefulWidget {
  final String mode; // 'marker' hoặc 'quiz'
  final String markerId;
  final String quizId;
  final String backendBase;

  const UnityPage({
    super.key,
    required this.mode,
    required this.markerId,
    required this.quizId,
    required this.backendBase,
  });

  @override
  ConsumerState<UnityPage> createState() => _UnityPageState();
}

class _UnityPageState extends ConsumerState<UnityPage> {
  bool _sceneReady = false;
  String? _lastMessage;

  @override
  void initState() {
    super.initState();

    // Lắng nghe message từ UnityBridge.java
    _unityBridgeChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onUnityMessage':
          final msg = call.arguments as String?;
          if (msg != null) {
            debugPrint('[Flutter][bridge] <- Unity: $msg');
            _onUnityMessage(msg);
          }
          break;

        case 'onUnitySceneLoaded':
        // Nếu cần xử lý scene loaded thì parse map
          break;
      }
      return null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.mode == 'marker') {
        _sendMarkerToUnity();
      } else if (widget.mode == 'quiz') {
        _sendQuizToUnity();
      }
    });
  }

  @override
  void dispose() {
    _unityBridgeChannel.setMethodCallHandler(null);
    super.dispose();
  }

  // ============ GỬI MARKER ============
  void _sendMarkerToUnity() {
    if (widget.markerId.isEmpty) return;

    final payload = jsonEncode({
      'markerId': widget.markerId,
      'backendBase': widget.backendBase,
    });

    debugPrint('[Flutter] -> Unity (marker): $payload');

    sendToUnity(
      'FlutterBridge',
      'SetMarkerJson',
      payload,
    );
  }

  // ============ GỬI QUIZ JSON SANG UNITY ============
  Future<void> _sendQuizToUnity() async {
    if (widget.quizId.isEmpty) return;

    try {
      final repo = ref.read(quizRepoProvider);
      final raw = await repo.getPlayDataRaw(widget.quizId);
      final quizJson = jsonEncode(raw);

      final payload = jsonEncode({
        'quizJson': quizJson,
      });

      debugPrint('[Flutter] -> Unity (quiz): $payload');

      sendToUnity(
        'FlutterBridge',
        'SetQuizJson',
        payload,
      );
    } catch (e, st) {
      debugPrint('Lỗi gửi quiz sang Unity: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải quiz AR: $e')),
      );
    }
  }

  // ============ NHẬN MESSAGE TỪ UNITY ============
  void _onUnityMessage(String data) {
    debugPrint('[Flutter] <- Unity: $data');
    setState(() => _lastMessage = data);

    // ====== Unity bấm nút Back ======
    if (data == 'GoHome') {
      if (!mounted) return;

      // Tạm dừng Unity
      pauseUnity();

      context.goNamed('home');

      return;
    }

    // 1) Nếu Unity gửi chuỗi kiểu "QUIZ_SUBMIT|{json}"
    if (data.startsWith('QUIZ_SUBMIT|')) {
      final jsonPart = data.substring('QUIZ_SUBMIT|'.length);
      try {
        final Map<String, dynamic> msg =
        (jsonDecode(jsonPart) as Map).cast<String, dynamic>();
        _handleQuizSubmit(msg);
      } catch (e, st) {
        debugPrint('Lỗi parse QUIZ_SUBMIT payload: $e\n$st');
      }
      return;
    }

    // 2) Thử parse JSON trực tiếp (Unity gửi thuần JSON)
    dynamic decoded;
    try {
      decoded = jsonDecode(data);
    } catch (_) {
      decoded = null;
    }

    if (decoded is Map) {
      final map = decoded.cast<String, dynamic>();
      final typeVal = (map['type'] ?? '').toString().toLowerCase();

      if (typeVal == 'quiz_submit' || typeVal == 'quiz-result' || typeVal == 'quiz_result') {
        _handleQuizSubmit(map);
        return;
      }
    }

    // 3) Các message text bình thường (marker / scene ready)
    if (data == 'SceneReady' || data == 'QuizSceneReady') {
      setState(() => _sceneReady = true);
    }
  }

  /// Xử lý khi Unity gửi JSON submit quiz
  ///
  /// Kỳ vọng JSON từ Unity:
  /// {
  ///   "type": "quiz_submit",
  ///   "quizId": "...",
  ///   "answers": [
  ///     {
  ///       "questionId": "...",
  ///       "answerIds": ["...", "..."]
  ///     }
  ///   ]
  /// }
  Future<void> _handleQuizSubmit(Map<String, dynamic> msg) async {
    // 1) quizId: ưu tiên cái Unity gửi, fallback quiz đang mở
    final quizId = (msg['quizId'] ?? widget.quizId).toString();

    // 2) userId hiện tại
    final userId = ref.read(currentUserIdProvider);
    if (userId == null || userId.isEmpty) {
      if (!mounted) return;
      debugPrint('[Flutter] quiz_submit: userId null -> chưa đăng nhập');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn cần đăng nhập để lưu kết quả quiz.')),
      );
      return;
    }

    // 3) build answers cho backend
    final rawAnswers = (msg['answers'] as List?) ?? const [];
    final List<Map<String, dynamic>> submitAnswers = rawAnswers.map((e) {
      final m = (e as Map).cast<String, dynamic>();
      final qId = (m['questionId'] ?? '').toString();

      final one = m['answerId'];
      final many = m['answerIds'];

      List<String> ids;
      if (many is List) {
        ids = many.map((x) => x.toString()).toList();
      } else if (one != null) {
        ids = [one.toString()];
      } else {
        ids = const [];
      }

      return <String, dynamic>{
        'questionId': qId,
        'answerIds': ids,
      };
    }).toList();

    debugPrint(
        '[Flutter] submitQuiz -> quizId=$quizId, userId=$userId, answers=$submitAnswers');

    try {
      final repo = ref.read(userQuizResultRepoProvider);
      final result = await repo.submitQuiz(
        quizId: quizId,
        userId: userId,
        answers: submitAnswers,
      );

      debugPrint('[Flutter] submitQuiz OK, resultId=${result.resultId}');

      if (!mounted) return;

      pauseUnity();

      // Điều hướng sang trang kết quả, đồng thời đóng UnityPage
      context.goNamed(
        'quiz_result',
        queryParameters: {
          'quizId': quizId,
          'resultId': result.resultId,
        },
      );
    } catch (e, st) {
      debugPrint('[Flutter] submitQuiz ERROR: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi lưu kết quả quiz: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleCode = widget.mode == 'quiz'
        ? 'Quiz AR (${widget.quizId})'
        : (widget.markerId.isEmpty ? '(no id)' : widget.markerId);

    return Scaffold(
      appBar: AppBar(
        title: Text('AR — $titleCode'),
        actions: [
          IconButton(
            tooltip: 'Reload',
            icon: const Icon(Icons.refresh),
            onPressed: _sceneReady
                ? () {
              if (widget.mode == 'marker') {
                _sendMarkerToUnity();
              } else if (widget.mode == 'quiz') {
                _sendQuizToUnity();
              }
            }
                : null,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: EmbedUnity(
              onMessageFromUnity: _onUnityMessage,
            ),
          ),
          if (_lastMessage != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'Unity: $_lastMessage',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}
