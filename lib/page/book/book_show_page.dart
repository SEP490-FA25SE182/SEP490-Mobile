import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../model/book.dart';
import '../../model/chapter.dart';
import '../../provider.dart';
import '../../repository/chapter_repository.dart';
import '../../widget/gs_image.dart';
import 'package:go_router/go_router.dart';

// Provider: Lấy danh sách chương
final chaptersByBookProvider = FutureProvider.family<List<Chapter>, String>((ref, bookId) {
  final repo = ref.read(chapterRepoProvider);
  return repo.getByBookId(bookId);
});

// Provider: Lấy chương đang đọc gần nhất
final lastReadChapterProvider = FutureProvider.family<Chapter?, String>((ref, bookId) async {
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

class BookShowPage extends ConsumerWidget {
  final String bookId;
  const BookShowPage({super.key, required this.bookId});

  Future<void> _saveLastReadChapter(String chapterId, WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_read_chapter_$bookId', chapterId);
    ref.invalidate(lastReadChapterProvider(bookId)); // refresh UI
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookAsync = ref.watch(bookByIdProvider(bookId));
    final chaptersAsync = ref.watch(chaptersByBookProvider(bookId));
    final lastReadAsync = ref.watch(lastReadChapterProvider(bookId));

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
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (e, _) => Center(child: Text('Lỗi: $e', style: const TextStyle(color: Colors.redAccent))),
        data: (book) {
          final authorAsync = ref.watch(userByIdProvider(book.authorId ?? ''));

          return Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: GsImage(url: book.coverUrl, width: 90, height: 130, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.bookName,
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          authorAsync.when(
                            data: (author) => Text(author.fullName, style: const TextStyle(color: Colors.white70, fontSize: 15)),
                            loading: () => const Text('Đang tải...', style: TextStyle(color: Colors.white54)),
                            error: (_, __) => const Text('Không rõ', style: TextStyle(color: Colors.white54)),
                          ),
                          const SizedBox(height: 12),
                          lastReadAsync.when(
                            data: (chapter) {
                              if (chapter != null) {
                                return ElevatedButton.icon(
                                  onPressed: () {
                                    _saveLastReadChapter(chapter.chapterId, ref);
                                    context.push('/reader/${book.bookId}/${chapter.chapterId}'); // ĐÃ SỬA
                                  },
                                  icon: const Icon(Icons.play_arrow, size: 18),
                                  label: Text('Tiếp tục chương ${chapter.chapterNumber}'),
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2ECC71)),
                                );
                              }
                              return OutlinedButton.icon(
                                onPressed: chaptersAsync.valueOrNull?.isNotEmpty == true
                                    ? () {
                                  final first = chaptersAsync.value!.first;
                                  _saveLastReadChapter(first.chapterId, ref);
                                  context.push('/reader/${book.bookId}/${first.chapterId}'); // ĐÃ SỬA
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

              // Danh sách chương
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Danh sách chương', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Tổng: ${chaptersAsync.value?.length ?? 0} chương', style: const TextStyle(color: Colors.white54)),
                  ],
                ),
              ),

              Expanded(
                child: chaptersAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
                  error: (e, _) => Center(child: Text('Lỗi: $e')),
                  data: (chapters) {
                    if (chapters.isEmpty) {
                      return const Center(child: Text('Chưa có chương nào.', style: TextStyle(color: Colors.white54)));
                    }

                    final lastReadChapter = lastReadAsync.value;

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: chapters.length,
                      itemBuilder: (_, i) {
                        final chapter = chapters[i];
                        final isLastRead = lastReadChapter?.chapterId == chapter.chapterId;

                        return Card(
                          color: const Color(0xFF1C2942),
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isLastRead ? const Color(0xFF2ECC71) : const Color(0xFF814BF6),
                              child: Text('${chapter.chapterNumber}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                            title: Text(
                              chapter.chapterName ?? 'Chương ${chapter.chapterNumber}',
                              style: TextStyle(color: Colors.white, fontWeight: isLastRead ? FontWeight.bold : FontWeight.w600),
                            ),
                            subtitle: chapter.publishedDate != null
                                ? Text(DateFormat('dd/MM/yyyy').format(chapter.publishedDate!), style: const TextStyle(color: Colors.white38, fontSize: 12))
                                : null,
                            trailing: isLastRead ? const Icon(Icons.play_arrow, color: Color(0xFF2ECC71)) : const Icon(Icons.chevron_right),
                            onTap: () {
                              _saveLastReadChapter(chapter.chapterId, ref);
                              context.push('/reader/${book.bookId}/${chapter.chapterId}'); // ĐÃ SỬA
                            },
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