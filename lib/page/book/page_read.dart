import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

import '../../model/page.dart';
import '../../provider.dart';
import '../../widget/gs_image.dart';
import '../../widget/audio_player.dart';
import '../../repository/marker_repository.dart';
import '../../core/config.dart';

class PageReadPage extends ConsumerStatefulWidget {
  final String bookId;
  final String chapterId;
  const PageReadPage({
    super.key,
    required this.bookId,
    required this.chapterId,
  });

  @override
  ConsumerState<PageReadPage> createState() => _PageReadPageState();
}

class _PageReadPageState extends ConsumerState<PageReadPage> {
  late final PageController _pageController;
  int _currentPage = 0;
  bool _showControls = true;
  bool _isDarkMode = true;
  late final String _themeKey;
  late final MarkerRepository _markerRepo;

  @override
  void initState() {
    super.initState();
    _themeKey = 'reader_theme_${widget.bookId}_${widget.chapterId}';
    _pageController = PageController();
    _markerRepo = MarkerRepository(AppConfig.fromEnv().apiBaseUrl);
    _loadTheme();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_currentPage == 0) {
      _loadLastPositionSafe();
    }
  }


  // Load vị trí đã đọc
  Future<void> _loadLastPositionSafe() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt('read_pos_${widget.bookId}_${widget.chapterId}') ?? 0;

    // Dùng Future.microtask để đảm bảo PageView đã attach
    await Future.microtask(() => null);

    if (!mounted) return;
    if (!_pageController.hasClients) return;

    final pages = ref.read(pagesWithMediaProvider(widget.chapterId)).value;
    if (pages == null || pages.isEmpty) return;

    if (saved > 0 && saved < pages.length) {
      _pageController.jumpToPage(saved);
      setState(() => _currentPage = saved);
      ref.read(currentPageIndexProvider.notifier).state = saved;
    }
  }

  // Lưu vị trí đọc
  Future<void> _savePosition(int page) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('read_pos_${widget.bookId}_${widget.chapterId}', page);
  }

  // Theme
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _isDarkMode = prefs.getBool(_themeKey) ?? true);
  }

  Future<void> _saveTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
  }

  void _toggleControls() => setState(() => _showControls = !_showControls);

  // AR Dialog
  Future<void> _showArDialogForPage(PageModel page) async {
    try {
      final marker = await _markerRepo.findFirstByPageId(page.pageId);
      if (!mounted) return;

      if (marker == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy marker cho trang này')),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Trải nghiệm AR'),
          content: const Text('Bắt đầu trải nghiệm thực tế tăng cường nào!'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            TextButton(
              onPressed: () {
                ref.read(audioPlayerProvider).pause();
                Navigator.pop(context);
                context.go('/unity?markerId=${marker.markerId}');
              },
              child: const Text('Mở AR'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi AR: $e')));
    }
  }

  // Text Page
  Widget _buildTextPage(PageModel page) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 28,
          right: 28,
          top: _showControls ? 180 : 50,
          bottom: _showControls ? 100 : 70,
        ),
        child: Html(
          data: page.content ?? '',
          style: {
            "body": Style(
              fontSize: FontSize(18.5),
              lineHeight: LineHeight(1.9),
              color: _isDarkMode ? Colors.white : Colors.black87,
              margin: Margins.zero,
            ),
            "p": Style(margin: Margins.symmetric(vertical: 16)),
            "a": Style(color: const Color(0xFF2ECC71), textDecoration: TextDecoration.underline),
            "sup": Style(fontSize: FontSize(11), verticalAlign: VerticalAlign.sup),
          },
          onLinkTap: (url, _, __) async {
            if (url != null) {
              await launchUrl(Uri.parse(url), mode: LaunchMode.inAppWebView);
            }
          },
        ),
      ),
    );
  }

  // Image Page (full màn hình)
  Widget _buildImagePage(String imageUrl) {
    return SafeArea(
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: _toggleControls,
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 5.0,
              child: GsImage(url: imageUrl, fit: BoxFit.contain),
            ),
          ),
          if (_showControls)
            Positioned(
              bottom: 90,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentPage + 1} / ${ref.read(pagesWithMediaProvider(widget.chapterId)).value?.length ?? 0}',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chapterAsync = ref.watch(chapterByIdProvider(widget.chapterId));
    final bookAsync = ref.watch(bookByIdProvider(widget.bookId));
    final pagesAsync = ref.watch(pagesWithMediaProvider(widget.chapterId));

    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.black : Colors.white,
      body: chapterAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (e, _) => Center(child: Text('Lỗi chapter: $e', style: const TextStyle(color: Colors.red))),
        data: (chapter) => bookAsync.when(
          loading: () => const SizedBox(),
          error: (_, __) => const Text('Lỗi sách'),
          data: (book) => pagesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
            error: (e, _) => Center(child: Text('Lỗi trang: $e', style: const TextStyle(color: Colors.red))),
            data: (pages) {
              if (pages.isEmpty) {
                return const Center(child: Text('Chương trống', style: TextStyle(color: Colors.grey)));
              }
              final currentPageModel = pages[_currentPage];
              return GestureDetector(
                onTap: _toggleControls,
                child: Stack(
                  children: [
                    // Nội dung trang
                    PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() => _currentPage = index);
                        _savePosition(index);
                        ref.read(currentPageIndexProvider.notifier).state = index;
                      },
                      itemCount: pages.length,
                      itemBuilder: (context, index) {
                        final page = pages[index];

                        final bool showText = page.isTextPage;
                        final bool showImage = page.isPicturePage;

                        if (showImage && page.illustrations.isNotEmpty) {
                          return _buildImagePage(page.illustrations.first.imageUrl);
                        } else if (showText && page.content?.trim().isNotEmpty == true) {
                          return _buildTextPage(page);
                        } else {
                          return const Center(child: Text('Trang trống', style: TextStyle(color: Colors.grey)));
                        }
                      },
                    ),

                    // Header + Controls
                    if (_showControls)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          color: _isDarkMode ? Colors.black : Colors.white,
                          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                          child: Column(
                            children: [
                              // Back + Title
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                                child: Row(
                                  children: [
                                    IconButton(
                                      onPressed: () => context.pop(),
                                      icon: Icon(Icons.arrow_back_ios,
                                          color: _isDarkMode ? Colors.white : Colors.black),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            book.bookName,
                                            style: TextStyle(
                                                color: _isDarkMode ? Colors.white70 : Colors.black54,
                                                fontSize: 14),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Consumer(
                                            builder: (context, ref, child) {
                                              final pages = ref.watch(pagesWithMediaProvider(widget.chapterId));
                                              return pages.when(
                                                data: (pageList) {
                                                  if (pageList.isEmpty) return const SizedBox();
                                                  final currentPageModel = pageList[_currentPage];
                                                  final pageNum = currentPageModel.pageNumber ?? _currentPage + 1;
                                                  return Text(
                                                    '${chapter.chapterName ?? 'Chương ${chapter.chapterNumber}'} – Trang $pageNum',
                                                    style: TextStyle(
                                                      color: _isDarkMode ? Colors.white : Colors.black,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  );
                                                },
                                                loading: () => Text(
                                                  chapter.chapterName ?? 'Chương ${chapter.chapterNumber}',
                                                  style: TextStyle(
                                                      color: _isDarkMode ? Colors.white : Colors.black,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16),
                                                ),
                                                error: (_, __) => const SizedBox(),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),



                              if (currentPageModel.isTextPage)
                                BookAudioPlayer(
                                  bookId: widget.bookId,
                                  chapterId: widget.chapterId,
                                  isDarkMode: _isDarkMode,
                                ),

                              if (currentPageModel.isPicturePage)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 32),
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.view_in_ar, size: 20),
                                    label: const Text('Trải nghiệm AR', style: TextStyle(fontSize: 16)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2ECC71),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                      elevation: 10,
                                    ),
                                    onPressed: () => _showArDialogForPage(currentPageModel),
                                  ),
                                ),

                              if (currentPageModel.isTextPage || currentPageModel.isPicturePage)
                                const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),

                    // Dark Mode Toggle
                    if (_showControls)
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 16,
                        right: 16,
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _isDarkMode = !_isDarkMode);
                            _saveTheme(_isDarkMode);
                          },
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: _isDarkMode ? Colors.white10 : Colors.black12,
                            child: Icon(
                              _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                              color: _isDarkMode ? Colors.yellow : Colors.orange,
                              size: 20,
                            ),
                          ),
                        ),
                      ),

                    // Bottom Page Indicator
                    if (_showControls)
                      Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: _currentPage > 0
                                  ? () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.ease)
                                  : null,
                              icon: const Icon(Icons.chevron_left, size: 40, color: Colors.white70),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                '${_currentPage + 1} / ${pages.length}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            IconButton(
                              onPressed: _currentPage < pages.length - 1
                                  ? () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease)
                                  : null,
                              icon: const Icon(Icons.chevron_right, size: 40, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}