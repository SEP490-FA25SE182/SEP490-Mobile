import 'package:flutter/material.dart';
import '../model/book.dart';
import '../widget/gs_image.dart';
import '../page/book/book_detail_page.dart';

/// "Mới nhất": viewport luôn thấy 2 cuốn to.
/// - Lấy tối đa 10 cuốn.
/// - Vuốt trái/phải.
/// - Có nút < và >; ẩn khi ở sát biên.
class NewBooksSection extends StatefulWidget {
  final List<Book> books;
  const NewBooksSection({super.key, required this.books});

  @override
  State<NewBooksSection> createState() => _NewBooksSectionState();
}

class _NewBooksSectionState extends State<NewBooksSection> {
  final _controller = ScrollController();
  bool _showLeft = false;
  bool _showRight = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateButtons);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateButtons());
  }

  @override
  void dispose() {
    _controller.removeListener(_updateButtons);
    _controller.dispose();
    super.dispose();
  }

  void _updateButtons() {
    if (!_controller.hasClients) return;
    final offset = _controller.offset;
    final max = _controller.position.maxScrollExtent;

    final atStart = offset <= 0.5;
    final atEnd = (max - offset) <= 0.5;

    final left = !atStart;
    final right = !atEnd;

    if (left != _showLeft || right != _showRight) {
      setState(() {
        _showLeft = left;
        _showRight = right;
      });
    }
  }

  Future<void> _scrollBy(double delta) async {
    if (!_controller.hasClients) return;
    final max = _controller.position.maxScrollExtent;
    final target = (_controller.offset + delta).clamp(0.0, max);
    await _controller.animateTo(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final books = widget.books.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mới nhất',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),

        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 14.0;
            final cardWidth = (constraints.maxWidth - spacing) / 2;
            const cardHeight = 320.0;

            return SizedBox(
              height: cardHeight,
              child: Stack(
                children: [
                  ListView.separated(
                    controller: _controller,
                    physics: const BouncingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(right: 56),
                    itemCount: books.length,
                    separatorBuilder: (_, __) =>
                    const SizedBox(width: spacing),
                    itemBuilder: (_, i) {
                      final book = books[i];
                      return SizedBox(
                        width: cardWidth,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    BookDetailPage(bookId: book.bookId),
                              ),
                            );
                          },
                          child: _BookBigCard(book: book),
                        ),
                      );
                    },
                  ),

                  // Nút điều hướng trái
                  if (_showLeft)
                    Positioned(
                      left: 0,
                      top: cardHeight / 2 - 20,
                      child: _NavButton(
                        icon: Icons.chevron_left,
                        onTap: () => _scrollBy(-(cardWidth + spacing)),
                      ),
                    ),

                  // Nút điều hướng phải
                  if (_showRight)
                    Positioned(
                      right: 0,
                      top: cardHeight / 2 - 20,
                      child: _NavButton(
                        icon: Icons.chevron_right,
                        onTap: () => _scrollBy(cardWidth + spacing),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF2D62F0),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black45)],
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _BookBigCard extends StatelessWidget {
  final Book book;
  const _BookBigCard({required this.book});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Hero(
          tag: 'book_${book.bookId}',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 3 / 4.2,
              child: GsImage(url: book.coverUrl, fit: BoxFit.cover),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          book.bookName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (book.price != null)
          Text(
            '${book.price!.toStringAsFixed(0)} VNĐ',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
      ],
    );
  }
}
