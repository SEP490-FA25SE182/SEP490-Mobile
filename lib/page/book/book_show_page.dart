import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

import '../../model/book.dart';
import '../../model/chapter.dart';
import '../../provider.dart';
import '../../repository/chapter_repository.dart';
import '../../widget/gs_image.dart';

/// ================== ICON QUIZ ==================
const _quizIconUrl =
    'gs://sep490-fa25se182.firebasestorage.app/icon/quiz.png';
const _quizEnterIconUrl =
    'gs://sep490-fa25se182.firebasestorage.app/icon/enter.png';
const _quizMiniIconUrl =
    'gs://sep490-fa25se182.firebasestorage.app/icon/quiz_mini.png';

/// Provider: Lấy chương đang đọc gần nhất
final lastReadChapterProvider =
FutureProvider.family<Chapter?, String>((ref, bookId) async {
  final prefs = await SharedPreferences.getInstance();
  final lastChapterId = prefs.getString('last_read_chapter_$bookId');
  if (lastChapterId == null) return null;

  try {
    final repo = ref.read(chapterRepoProvider);
    return await repo.getById(lastChapterId);
  } catch (_) {
    return null;
  }
});

/// ================== PAGE ==================

class BookShowPage extends ConsumerStatefulWidget {
  final String bookId;
  const BookShowPage({super.key, required this.bookId});

  @override
  ConsumerState<BookShowPage> createState() => _BookShowPageState();
}

class _BookShowPageState extends ConsumerState<BookShowPage> {
  /// chapterId đang expand phần quiz bên dưới
  String? _expandedChapterId;

  Future<void> _saveLastReadChapter(String chapterId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_read_chapter_${widget.bookId}', chapterId);
    ref.invalidate(lastReadChapterProvider(widget.bookId)); // refresh UI
  }

  @override
  Widget build(BuildContext context) {
    final bookAsync = ref.watch(bookByIdProvider(widget.bookId));
    final chaptersAsync = ref.watch(chaptersByBookProvider(widget.bookId));
    final lastReadAsync = ref.watch(lastReadChapterProvider(widget.bookId));

    return Scaffold(
      backgroundColor: const Color(0xFF09121F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E2A47),
        title: const Text('Đọc sách'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: bookAsync.when(
        loading: () =>
        const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (e, _) => Center(
          child: Text(
            'Lỗi: $e',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
        data: (book) {
          final authorAsync = ref.watch(userByIdProvider(book.authorId ?? ''));

          return Column(
            children: [
              /// ================== HEADER ==================
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: GsImage(
                        url: book.coverUrl,
                        width: 90,
                        height: 130,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.bookName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          authorAsync.when(
                            data: (author) => Text(
                              author.fullName,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                              ),
                            ),
                            loading: () => const Text(
                              'Đang tải...',
                              style: TextStyle(color: Colors.white54),
                            ),
                            error: (_, __) => const Text(
                              'Không rõ',
                              style: TextStyle(color: Colors.white54),
                            ),
                          ),
                          const SizedBox(height: 12),
                          lastReadAsync.when(
                            data: (chapter) {
                              if (chapter != null) {
                                return ElevatedButton.icon(
                                  onPressed: () {
                                    _saveLastReadChapter(chapter.chapterId);
                                    context.push(
                                      '/reader/${book.bookId}/${chapter.chapterId}',
                                    );
                                  },
                                  icon:
                                  const Icon(Icons.play_arrow, size: 18),
                                  label: Text(
                                      'Tiếp tục chương ${chapter.chapterNumber}'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                    const Color(0xFF2ECC71),
                                  ),
                                );
                              }
                              return OutlinedButton.icon(
                                onPressed:
                                chaptersAsync.valueOrNull?.isNotEmpty ==
                                    true
                                    ? () {
                                  final first =
                                      chaptersAsync.value!.first;
                                  _saveLastReadChapter(
                                      first.chapterId);
                                  context.push(
                                    '/reader/${book.bookId}/${first.chapterId}',
                                  );
                                }
                                    : null,
                                icon: const Icon(Icons.menu_book, size: 18),
                                label: const Text('Bắt đầu đọc'),
                              );
                            },
                            loading: () => const SizedBox(),
                            error: (_, __) => const SizedBox(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: Colors.white10),

              /// ================== TITLE DANH SÁCH CHƯƠNG ==================
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Danh sách chương',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Tổng: ${chaptersAsync.value?.length ?? 0} chương',
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),

              /// ================== LIST CHƯƠNG + QUIZ ==================
              Expanded(
                child: chaptersAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  error: (e, _) => Center(child: Text('Lỗi: $e')),
                  data: (chapters) {
                    if (chapters.isEmpty) {
                      return const Center(
                        child: Text(
                          'Chưa có chương nào.',
                          style: TextStyle(color: Colors.white54),
                        ),
                      );
                    }

                    final lastReadChapter = lastReadAsync.value;

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: chapters.length,
                      itemBuilder: (_, i) {
                        final chapter = chapters[i];
                        final isLastRead =
                            lastReadChapter?.chapterId == chapter.chapterId;
                        final isExpanded =
                            _expandedChapterId == chapter.chapterId;

                        // Provider quiz cho chapter này
                        final quizzesAsync =
                        ref.watch(quizzesByChapterProvider(
                          chapter.chapterId,
                        ));

                        return Card(
                          color: const Color(0xFF1C2942),
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// ----- HÀNG CHƯƠNG -----
                              ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isLastRead
                                      ? const Color(0xFF2ECC71)
                                      : const Color(0xFF814BF6),
                                  child: Text(
                                    '${chapter.chapterNumber}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  chapter.chapterName ??
                                      'Chương ${chapter.chapterNumber}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: isLastRead
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                  ),
                                ),
                                subtitle: chapter.publishedDate != null
                                    ? Text(
                                  DateFormat('dd/MM/yyyy')
                                      .format(chapter.publishedDate!),
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 12,
                                  ),
                                )
                                    : null,
                                // trailing: icon play (nếu là lastRead) + icon quiz
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isLastRead)
                                      const Icon(
                                        Icons.play_arrow,
                                        color: Color(0xFF2ECC71),
                                      ),
                                    const SizedBox(width: 4),
                                    InkWell(
                                      onTap: () {
                                        debugPrint(
                                            '[BookShowPage] BẤM ICON QUIZ, chapterId=${chapter.chapterId}');
                                        setState(() {
                                          _expandedChapterId =
                                          isExpanded ? null : chapter.chapterId;
                                        });
                                      },
                                      child: GsImage(
                                        url: _quizIconUrl,
                                        width: 28,
                                        height: 28,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  _saveLastReadChapter(chapter.chapterId);
                                  context.push(
                                    '/reader/${book.bookId}/${chapter.chapterId}',
                                  );
                                },
                              ),

                              /// ----- PHẦN QUIZ BÊN DƯỚI -----
                              if (isExpanded)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 0, 16, 12),
                                  child: quizzesAsync.when(
                                    loading: () => const Padding(
                                      padding: EdgeInsets.all(8),
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                    error: (e, _) => Text(
                                      'Không tải được quiz: $e',
                                      style: const TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 12,
                                      ),
                                    ),
                                      data: (quizzes) {
                                        if (quizzes.isEmpty) {
                                          return const Text(
                                            'Hiện chưa có quiz cho chương này',
                                            style: TextStyle(
                                              color: Colors.white54,
                                              fontSize: 12,
                                            ),
                                          );
                                        }

                                        return Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Icon mũi tên bên trái (enter.png)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 8),
                                              child: GsImage(
                                                url: _quizEnterIconUrl,
                                                width: 22,
                                                height: 22,
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                            const SizedBox(width: 8),

                                            // Danh sách quiz dạng "viên thuốc" gradient
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: quizzes
                                                    .map(
                                                      (q) => Padding(
                                                    padding: const EdgeInsets.only(bottom: 8),
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        context.push('/quiz/${q.quizId}');
                                                      },
                                                      child: Container(
                                                        width: double.infinity,
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 8,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          borderRadius: BorderRadius.circular(24),
                                                          gradient: const LinearGradient(
                                                            begin: Alignment.centerLeft,
                                                            end: Alignment.centerRight,
                                                            colors: [
                                                              Color(0xFFFF9FD5), // hồng
                                                              Color(0xFFB47CFF), // tím
                                                            ],
                                                          ),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            // icon quiz_mini.png ở đầu
                                                            GsImage(
                                                              url: _quizMiniIconUrl,
                                                              width: 20,
                                                              height: 20,
                                                              fit: BoxFit.contain,
                                                            ),
                                                            const SizedBox(width: 8),
                                                            // tiêu đề quiz
                                                            Expanded(
                                                              child: Text(
                                                                q.title,
                                                                style: const TextStyle(
                                                                  color: Colors.white,
                                                                  fontSize: 14,
                                                                  fontWeight: FontWeight.w600,
                                                                ),
                                                                maxLines: 2,
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                )
                                                    .toList(),
                                              ),
                                            ),
                                          ],
                                        );
                                      }
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
