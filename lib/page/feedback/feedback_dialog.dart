import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../model/feedback.dart';
import '../../provider.dart';

class FeedbackDialog extends ConsumerStatefulWidget {
  final String bookId;
  final String orderDetailId;
  final String userId;

  const FeedbackDialog({
    super.key,
    required this.bookId,
    required this.orderDetailId,
    required this.userId,
  });

  @override
  ConsumerState<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends ConsumerState<FeedbackDialog> {
  int _rating = 0;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn số sao')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final feedback = BookFeedback(
        feedbackId: '',
        content: _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text.trim(),
        rating: _rating,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActived: IsActived.active,
        userId: widget.userId,
        bookId: widget.bookId,
        orderDetailId: widget.orderDetailId,
        imageUrls: null,
        status: FeedbackStatus.pending,
      );

      await ref.read(feedbackRepoProvider).create(feedback);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cảm ơn đánh giá của bạn!')),
        );
        Navigator.of(context).pop(true); // Success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF141B29),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Đánh giá sách',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Star Rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    i < _rating ? Icons.star : Icons.star_border,
                    color: const Color(0xFFFFD700),
                    size: 40,
                  ),
                  onPressed: () => setState(() => _rating = i + 1),
                );
              }),
            ),
            const SizedBox(height: 16),

            // Comment Box
            TextField(
              controller: _commentCtrl,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Viết nhận xét (tùy chọn)',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0x20FFFFFF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('Hủy', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5B6CF3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: _submitting
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
              : const Text('Gửi', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}