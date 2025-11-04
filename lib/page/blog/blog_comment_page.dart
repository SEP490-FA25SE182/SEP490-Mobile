import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../model/comment.dart';
import '../../model/user.dart';
import '../../provider.dart';
import '../../screen/edit_comment_screen.dart';
import '../../style/input_text.dart';
import '../../widget/gs_image.dart';

class BlogCommentSection extends ConsumerStatefulWidget {
  final String blogId;
  const BlogCommentSection({super.key, required this.blogId});

  @override
  ConsumerState<BlogCommentSection> createState() => _BlogCommentSectionState();
}

class _BlogCommentSectionState extends ConsumerState<BlogCommentSection> {
  int _mode = 0; // 0: tài khoản của bạn, 1: ẩn danh
  final _anonNameCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  bool _posting = false;
  bool _showAll = false;

  @override
  void dispose() {
    _anonNameCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    final me = ref.read(currentUserIdProvider);
    final isAnon = _mode == 1;
    final content = _contentCtrl.text.trim();

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập nội dung')),
      );
      return;
    }

    String? name;
    String? userId;
    if (isAnon) {
      name = _anonNameCtrl.text.trim();
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng nhập nickname')),
        );
        return;
      }
    } else {
      userId = (me ?? '');
      if (userId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bạn cần đăng nhập để bình luận bằng tài khoản')),
        );
        return;
      }
    }

    setState(() => _posting = true);
    try {
      await ref.read(commentRepoProvider).create(
        blogId: widget.blogId,
        userId: userId,
        name: name,
        content: content,
      );
      // refresh
      ref.invalidate(commentCountProvider(widget.blogId));
      ref.invalidate(commentsByBlogProvider(widget.blogId));
      _contentCtrl.clear();
      _anonNameCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã đăng bình luận')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi đăng bình luận: $e')),
      );
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final countAsync = ref.watch(commentCountProvider(widget.blogId));
    final listAsync  = ref.watch(commentsByBlogProvider(widget.blogId));
    final userId     = ref.watch(currentUserIdProvider); // <-- userId hiện tại

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 18),

        // ====== Tiêu đề
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Để lại comment',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
          ),
        ),
        const SizedBox(height: 8),

        // ====== Đăng với tư cách
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Radio<int>(
                value: 0,
                groupValue: _mode,
                onChanged: (v) => setState(() => _mode = v ?? 0),
                activeColor: Colors.pinkAccent,
              ),
              const Text('Tài khoản của bạn', style: TextStyle(color: Colors.white)),
              const SizedBox(width: 16),
              Radio<int>(
                value: 1,
                groupValue: _mode,
                onChanged: (v) => setState(() => _mode = v ?? 0),
                activeColor: Colors.pinkAccent,
              ),
              const Text('Ẩn danh', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),

        if (_mode == 1)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: InputFieldBox(
              child: TextField(
                controller: _anonNameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Nhập nickname nào ...',
                  hintStyle: TextStyle(color: Colors.white54),
                ),
              ),
            ),
          ),

        const SizedBox(height: 8),

        // Nội dung comment
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: InputFieldBox(
            height: 110,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: TextField(
              controller: _contentCtrl,
              maxLines: null,
              minLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Nhập nội dung bình luận...',
                hintStyle: TextStyle(color: Colors.white54),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 120,
              height: 40,
              child: FilledButton(
                onPressed: _posting ? null : _post,
                child: _posting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Đăng'),
              ),
            ),
          ),
        ),

        // Divider
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Divider(color: Colors.white24, height: 1),
        ),

        // ====== Header đếm
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: countAsync.when(
            loading: () => const SizedBox(height: 24),
            error: (e, _) => Text('Lỗi đếm comment: $e', style: const TextStyle(color: Colors.redAccent)),
            data: (n) => Text(
              '$n comments',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // ====== Danh sách comment
        listAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Lỗi tải comment: $e', style: const TextStyle(color: Colors.redAccent)),
          ),
          data: (all) {
            final items = _showAll ? all : (all.length > 10 ? all.sublist(0, 10) : all);

            return Column(
              children: [
                for (final c in items)
                  _CommentItem(
                    comment: c,
                    blogId: widget.blogId,
                    userId: userId,
                  ),

                const SizedBox(height: 8),
                if (!_showAll && all.length > 10)
                  TextButton(
                    onPressed: () => setState(() => _showAll = true),
                    child: const Text('Xem thêm >>', style: TextStyle(color: Colors.white70)),
                  ),
                const SizedBox(height: 12),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _CommentItem extends ConsumerWidget {
  final Comment comment;
  final String blogId;
  final String? userId; // <-- nhận userId

  const _CommentItem({
    required this.comment,
    required this.blogId,
    required this.userId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMine = (userId != null && userId!.isNotEmpty && userId == comment.userId);

    final hasUser = comment.userId.isNotEmpty;
    final userAsync = hasUser
        ? ref.watch(userByIdProvider(comment.userId))
        : const AsyncValue<User>.loading();

    final dt = comment.updatedAt ?? comment.createdAt;
    final timeLabel = dt == null
        ? ''
        : '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        'at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    const editIconUrl = 'gs://sep490-fa25se182.firebasestorage.app/icon/edit.png';
    const anonAvatar  = 'gs://sep490-fa25se182.firebasestorage.app/avatar/sample_avatar.png';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white10,
            child: ClipOval(
              child: SizedBox(
                width: 36, height: 36,
                child: hasUser
                    ? userAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const Icon(Icons.person, color: Colors.white54, size: 18),
                  data: (u) => (u.avatarUrl != null && u.avatarUrl!.isNotEmpty)
                      ? GsImage(url: u.avatarUrl!, fit: BoxFit.cover)
                      : const Icon(Icons.person, color: Colors.white54, size: 18),
                )
                    : const GsImage(url: anonAvatar, fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Nội dung
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tên + nút edit
                Row(
                  children: [
                    Expanded(
                      child: hasUser
                          ? userAsync.when(
                        loading: () => const SizedBox(height: 18),
                        error: (_, __) =>
                        const Text('(Lỗi user)', style: TextStyle(color: Colors.white)),
                        data: (u) => Text(
                          u.fullName.isEmpty ? '(Không tên)' : u.fullName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                        ),
                      )
                          : Text(
                        comment.name ?? 'Ẩn danh',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (isMine)
                      InkWell(
                        onTap: () async {
                          final updated = await showDialog<bool>(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => EditCommentScreen(
                              comment: comment,
                              blogId: blogId,
                              userId: userId,
                            ),
                          );
                          if (updated == true) {
                            ref.invalidate(commentsByBlogProvider(blogId));
                            ref.invalidate(commentCountProvider(blogId));
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: GsImage(
                            url: editIconUrl,
                            width: 16,
                            height: 16,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                  ],
                ),

                // Nội dung comment
                Text(comment.content ?? '', style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 4),

                // Thời gian
                Text(timeLabel, style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
