import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../firebase_options.dart';
import '../../model/marker.dart';
import '../../model/page.dart';
import '../../repository/marker_repository.dart';
import '../../core/config.dart';
import '../../provider.dart';
import 'package:go_router/go_router.dart';

final audioPlayerProvider = Provider<AudioPlayer>((ref) => AudioPlayer());

class PageReadPage extends ConsumerStatefulWidget {
  final String bookId;
  final String chapterId;
  const PageReadPage({super.key, required this.bookId, required this.chapterId});

  @override
  ConsumerState<PageReadPage> createState() => _PageReadPageState();
}

class _PageReadPageState extends ConsumerState<PageReadPage> {
  late PageController _pageController;
  int _currentPage = 0;
  bool _showControls = true;
  late AudioPlayer _audioPlayer;
  bool _isDarkMode = true;
  late String _themeKey;
  bool _isMuted = false;
  late final MarkerRepository _markerRepo;

  @override
  void initState() {
    super.initState();
    _themeKey = 'reader_theme_${widget.bookId}_${widget.chapterId}';
    _audioPlayer = ref.read(audioPlayerProvider);
    _pageController = PageController();
    final config = AppConfig.fromEnv();
    _markerRepo = MarkerRepository(config.apiBaseUrl);
    _loadLastPosition();
    _loadTheme();
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      const String gsAudioUrl =
          'gs://sep490-fa25se182.firebasestorage.app/audios/13bf361a-8cc2-4800-97cf-2c75a154568c.wav';

      final String audioUrl = DefaultFirebaseOptions.toHttpsUrl(gsAudioUrl);
      debugPrint('Audio playing: $audioUrl');
      await _audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(audioUrl)));
      await _audioPlayer.load();
      await _audioPlayer.play();

      debugPrint('Audio playing: $audioUrl');
    } catch (e) {
      debugPrint('Audio error: $e');
    }
  }

  // HÀM AN TOÀN: Lùi 10s – KHÔNG ÂM
  void _rewind10() {
    final newPos = _audioPlayer.position - const Duration(seconds: 10);
    _audioPlayer.seek(newPos > Duration.zero ? newPos : Duration.zero);
  }

  // HÀM AN TOÀN: Tua 10s – KHÔNG VƯỢT MAX
  void _forward10() {
    final duration = _audioPlayer.duration ?? Duration.zero;
    final newPos = _audioPlayer.position + const Duration(seconds: 10);
    _audioPlayer.seek(newPos < duration ? newPos : duration - const Duration(seconds: 1));
  }

  // NÚT RESTART: Quay về đầu
  void _restart() {
    _audioPlayer.seek(Duration.zero);
    if (!_audioPlayer.playing) _audioPlayer.play();
  }

  Future<void> _loadLastPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt('read_pos_${widget.bookId}_${widget.chapterId}') ?? 0;
    final pages = await ref.read(pagesByChapterProvider(widget.chapterId).future);
    if (saved > 0 && saved < pages.length) {
      _pageController.jumpToPage(saved);
      setState(() => _currentPage = saved);
    }
  }

  Future<void> _savePosition(int page) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('read_pos_${widget.bookId}_${widget.chapterId}', page);
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _isDarkMode = prefs.getBool(_themeKey) ?? true);
  }

  Future<void> _saveTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
  }

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
          title: const Text('Trải nghiệm Thực tế tăng cường'),
          content: const Text(
            'Bắt đầu trải nghiệm thực tế tăng cường cùng Rookies nào',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                _audioPlayer.stop();
                Navigator.of(context).pop();
                final markerId = marker.markerId;

                context.go('/unity?markerId=$markerId');
              },
              child: const Text('Mở AR'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải marker: $e')),
      );
    }
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _audioPlayer.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  void _toggleControls() => setState(() => _showControls = !_showControls);

  void _goToPage(int page, int totalPages) {
    if (page >= 0 && page < totalPages) _pageController.jumpToPage(page);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chapterAsync = ref.watch(chapterByIdProvider(widget.chapterId));
    final pagesAsync = ref.watch(pagesByChapterProvider(widget.chapterId));
    final bookAsync = ref.watch(bookByIdProvider(widget.bookId));

    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.black : Colors.white,
      body: chapterAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (e, _) => Center(child: Text('Lỗi chapter: $e', style: TextStyle(color: Colors.red))),
        data: (chapter) => bookAsync.when(
          loading: () => const SizedBox(),
          error: (_, __) => const SizedBox(),
          data: (book) => pagesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
            error: (e, _) => Center(child: Text('Lỗi nội dung: $e', style: TextStyle(color: Colors.red))),
            data: (pages) {
              final totalPages = pages.length;
              if (_currentPage >= totalPages && totalPages > 0) _currentPage = totalPages - 1;

              return GestureDetector(
                onTap: _toggleControls,
                child: Stack(
                  children: [
                    // --- NỘI DUNG TRANG ---
                    PageView.builder(
                      controller: _pageController,
                      onPageChanged: (page) {
                        setState(() => _currentPage = page);
                        _savePosition(page);
                      },
                      itemCount: totalPages,
                      itemBuilder: (context, index) {
                        final page = pages[index];
                        return SafeArea(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.only(
                              left: 24,
                              right: 24,
                              top: _showControls ? 170 : 60,
                              bottom: _showControls ? 90 : 60,
                            ),
                            child: Text(
                              page.content ?? '',
                              style: TextStyle(
                                color: _isDarkMode ? Colors.white : Colors.black,
                                fontSize: 18,
                                height: 1.8,
                                fontFamily: 'Roboto',
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // --- HEADER + AUDIO + NÚT AR (PHÍA TRÊN TRANG) ---
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
                              // Thanh trên cùng: back + tiêu đề sách + chương
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.arrow_back_ios,
                                        color: _isDarkMode ? Colors.white : Colors.black,
                                      ),
                                      onPressed: () => context.pop(),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            book.bookName,
                                            style: TextStyle(
                                              color: _isDarkMode ? Colors.white70 : Colors.black54,
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            chapter.chapterName ?? 'Chương ${chapter.chapterNumber}',
                                            style: TextStyle(
                                              color: _isDarkMode ? Colors.white : Colors.black,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // AUDIO BAR – NHƯ CŨ
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 32),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: _isDarkMode
                                      ? Colors.white.withOpacity(0.16)
                                      : Colors.black.withOpacity(0.16),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                      color: _isDarkMode ? Colors.white24 : Colors.black26, width: 0.6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.replay,
                                              size: 28,
                                              color: _isDarkMode ? Colors.white70 : Colors.black54),
                                          onPressed: _restart,
                                          tooltip: 'Phát lại từ đầu',
                                        ),
                                        StreamBuilder<PlayerState>(
                                          stream: _audioPlayer.playerStateStream,
                                          builder: (context, snapshot) {
                                            final playing = snapshot.data?.playing ?? false;
                                            return IconButton(
                                              icon: Icon(
                                                playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                                size: 32,
                                                color: _isDarkMode ? Colors.white : Colors.black,
                                              ),
                                              onPressed: () =>
                                              playing ? _audioPlayer.pause() : _audioPlayer.play(),
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.replay_10,
                                              size: 28,
                                              color: _isDarkMode ? Colors.white70 : Colors.black54),
                                          onPressed: _rewind10,
                                        ),
                                        Expanded(
                                          child: StreamBuilder<Duration>(
                                            stream: _audioPlayer.positionStream,
                                            builder: (context, snapshot) {
                                              final position = snapshot.data ?? Duration.zero;
                                              final duration = _audioPlayer.duration ?? Duration.zero;
                                              final max = duration.inSeconds > 0
                                                  ? duration.inSeconds.toDouble()
                                                  : 1.0;
                                              final value =
                                              position.inSeconds.toDouble().clamp(0.0, max);
                                              return Slider(
                                                value: value,
                                                min: 0.0,
                                                max: max,
                                                onChanged: duration.inSeconds > 0
                                                    ? (v) => _audioPlayer
                                                    .seek(Duration(seconds: v.round()))
                                                    : null,
                                                activeColor: const Color(0xFF2ECC71),
                                                inactiveColor:
                                                _isDarkMode ? Colors.white24 : Colors.black26,
                                              );
                                            },
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.forward_10,
                                              size: 28,
                                              color: _isDarkMode ? Colors.white70 : Colors.black54),
                                          onPressed: _forward10,
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        StreamBuilder<Duration>(
                                          stream: _audioPlayer.positionStream,
                                          builder: (context, snapshot) {
                                            final position = snapshot.data ?? Duration.zero;
                                            final duration = _audioPlayer.duration ?? Duration.zero;
                                            return Text(
                                              '${_formatDuration(position)} / ${_formatDuration(duration)}',
                                              style: TextStyle(
                                                color:
                                                _isDarkMode ? Colors.white70 : Colors.black54,
                                                fontSize: 11,
                                              ),
                                            );
                                          },
                                        ),
                                        const Spacer(),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            GestureDetector(
                                              onTap: _toggleMute,
                                              child: Icon(
                                                _isMuted ? Icons.volume_off : Icons.volume_up,
                                                size: 18,
                                                color:
                                                _isDarkMode ? Colors.white70 : Colors.black54,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            SizedBox(
                                              width: 120,
                                              child: StreamBuilder<double>(
                                                stream: _audioPlayer.volumeStream,
                                                builder: (context, snapshot) {
                                                  final volume = snapshot.data ?? 1.0;
                                                  return Slider(
                                                    value: volume,
                                                    min: 0.0,
                                                    max: 1.0,
                                                    onChanged: (v) {
                                                      _audioPlayer.setVolume(v);
                                                      setState(() => _isMuted = v == 0.0);
                                                    },
                                                    activeColor: const Color(0xFF2ECC71),
                                                    inactiveColor: _isDarkMode
                                                        ? Colors.white24
                                                        : Colors.black26,
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 8),

                              // NÚT AR – THÊM MỚI, PHÍA TRÊN TRANG
                              if (totalPages > 0)
                                ElevatedButton(
                                  onPressed: () {
                                    final page = pages[_currentPage];
                                    _showArDialogForPage(page);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                  ),
                                  child: const Text('Trải nghiệm Thực tế tăng cường'),
                                ),

                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),

                    // NÚT ĐỔI SÁNG/TỐI (GIỮ NGUYÊN)
                    if (_showControls)
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 16,
                        right: 16,
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _isDarkMode = !_isDarkMode);
                            _saveTheme(_isDarkMode);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _isDarkMode ? Colors.white10 : Colors.black12,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: _isDarkMode ? Colors.white24 : Colors.black26),
                            ),
                            child: Icon(
                              _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                              color: _isDarkMode ? Colors.yellow : Colors.orange,
                              size: 20,
                            ),
                          ),
                        ),
                      ),

                    // THANH CHUYỂN TRANG DƯỚI ĐÁY – NHƯ CŨ
                    if (_showControls)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          color: _isDarkMode ? Colors.black : Colors.white,
                          padding: const EdgeInsets.only(bottom: 30),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: Icon(Icons.chevron_left,
                                    color:
                                    _isDarkMode ? Colors.white70 : Colors.black54,
                                    size: 36),
                                onPressed: _currentPage > 0
                                    ? () => _goToPage(_currentPage - 1, totalPages)
                                    : null,
                              ),
                              Container(
                                padding:
                                const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                                decoration: BoxDecoration(
                                  color: _isDarkMode ? Colors.white10 : Colors.black12,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Text(
                                  '${_currentPage + 1} / $totalPages',
                                  style: TextStyle(
                                    color: _isDarkMode ? Colors.white : Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.chevron_right,
                                    color:
                                    _isDarkMode ? Colors.white70 : Colors.black54,
                                    size: 36),
                                onPressed: _currentPage < totalPages - 1
                                    ? () => _goToPage(_currentPage + 1, totalPages)
                                    : null,
                              ),
                            ],
                          ),
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

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}