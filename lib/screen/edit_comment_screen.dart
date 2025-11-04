import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../model/comment.dart';
import '../../repository/comment_repository.dart';
import '../../style/input_text.dart';
import '../provider.dart';

class EditCommentScreen extends ConsumerStatefulWidget {
  final Comment comment;
  final String blogId;
  final String? userId;

  const EditCommentScreen({
    super.key,
    required this.comment,
    required this.blogId,
    required this.userId,
  });

  @override
  ConsumerState<EditCommentScreen> createState() => _EditCommentScreenState();
}

class _EditCommentScreenState extends ConsumerState<EditCommentScreen> {
  late final TextEditingController _contentCtrl;
  late bool _isPublished;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _contentCtrl = TextEditingController(text: widget.comment.content ?? '');
    _isPublished = widget.comment.isPublished;
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final content = _contentCtrl.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập nội dung')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(commentRepoProvider).update(
        widget.comment.commentId,
        blogId: widget.blogId,
        userId: widget.userId,
        content: content,
        isPublished: _isPublished,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lưu thất bại: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF11223A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Sửa bình luận',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text('Hiển thị công khai', style: TextStyle(color: Colors.white70)),
                const Spacer(),
                Switch(
                  value: _isPublished,
                  onChanged: (v) => setState(() => _isPublished = v),
                ),
              ],
            ),
            const SizedBox(height: 8),
            InputFieldBox(
              height: 140,
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: TextField(
                controller: _contentCtrl,
                maxLines: null,
                minLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Nội dung bình luận...',
                  hintStyle: TextStyle(color: Colors.white54),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Huỷ'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Lưu'),
        ),
      ],
    );
  }
}
