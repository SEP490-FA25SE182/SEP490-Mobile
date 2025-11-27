// lib/widget/audio_player.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../provider.dart';
import '../../firebase_options.dart';

class BookAudioPlayer extends ConsumerWidget {
  final String bookId;
  final String chapterId;
  final bool isDarkMode;

  const BookAudioPlayer({
    super.key,
    required this.bookId,
    required this.chapterId,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(audioPlayerProvider);
    final pagesAsync = ref.watch(pagesWithMediaProvider(chapterId));

    return pagesAsync.when(
      loading: () => _buildLoadingState(),
      error: (_, __) => _buildErrorState(),
      data: (pages) {
        final currentIndex = ref.watch(currentPageIndexProvider);
        if (currentIndex >= pages.length) return const SizedBox();

        final currentPage = pages[currentIndex];
        final audio = currentPage.audios.isNotEmpty ? currentPage.audios.first : null;

        // Không có audio → hiện thông báo
        if (audio == null) {
          return _buildNoAudioState();
        }

        final audioUrl = audio.audioUrl.startsWith('gs://')
            ? DefaultFirebaseOptions.toHttpsUrl(audio.audioUrl)
            : audio.audioUrl;

        // Khi chuyển trang → tự động set URL mới (nhưng KHÔNG play)
        ref.listen(currentPageIndexProvider, (prev, next) {
          if (prev != next && next < pages.length) {
            final newPage = pages[next];
            if (newPage.audios.isNotEmpty) {
              final newUrl = newPage.audios.first.audioUrl.startsWith('gs://')
                  ? DefaultFirebaseOptions.toHttpsUrl(newPage.audios.first.audioUrl)
                  : newPage.audios.first.audioUrl;
              player.setUrl(newUrl); // Chỉ set, không play
            }
          }
        });

        return StreamBuilder<PlayerState>(
          stream: player.playerStateStream,
          builder: (context, snapshot) {
            final state = snapshot.data ?? player.playerState;
            final processingState = state.processingState;
            final playing = state.playing;

            final isLoading = processingState == ProcessingState.loading ||
                processingState == ProcessingState.buffering;

            final isReady = processingState == ProcessingState.completed ||
                processingState == ProcessingState.ready;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.white.withOpacity(0.16) : Colors.black.withOpacity(0.16),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: isDarkMode ? Colors.white24 : Colors.black26, width: 0.6),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Opacity(
                opacity: isLoading ? 0.6 : 1.0,
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Rewind to start
                        IconButton(
                          icon: const Icon(Icons.replay),
                          onPressed: isLoading || !isReady ? null : () => player.seek(Duration.zero),
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),

                        // Play / Pause
                        StreamBuilder<bool>(
                          stream: player.playingStream,
                          builder: (context, snapshot) {
                            final isPlaying = snapshot.data ?? false;
                            return IconButton(
                              iconSize: 32,
                              icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                              color: isDarkMode ? Colors.white : Colors.black,
                              onPressed: isLoading
                                  ? null
                                  : () {
                                if (isPlaying) {
                                  player.pause();
                                } else {
                                  // Nếu chưa load → load trước, rồi play
                                  if (processingState == ProcessingState.idle) {
                                    player.setUrl(audioUrl).then((_) => player.play());
                                  } else {
                                    player.play();
                                  }
                                }
                              },
                            );
                          },
                        ),

                        // Rewind 10s
                        IconButton(
                          icon: const Icon(Icons.replay_10),
                          onPressed: isLoading || !isReady
                              ? null
                              : () {
                            final pos = player.position - const Duration(seconds: 10);
                            player.seek(pos > Duration.zero ? pos : Duration.zero);
                          },
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),

                        // Thanh tiến trình
                        Expanded(
                          child: StreamBuilder<Duration>(
                            stream: player.positionStream,
                            builder: (context, snapshot) {
                              final position = snapshot.data ?? Duration.zero;
                              final duration = player.duration ?? Duration.zero;
                              final max = duration.inSeconds > 0 ? duration.inSeconds.toDouble() : 1.0;

                              return Slider(
                                value: position.inSeconds.toDouble().clamp(0, max),
                                max: max,
                                onChanged: isLoading || !isReady ? null : (v) {
                                  player.seek(Duration(seconds: v.round()));
                                },
                                activeColor: const Color(0xFF2ECC71),
                                inactiveColor: Colors.grey[400],
                              );
                            },
                          ),
                        ),

                        // Forward 10s
                        IconButton(
                          icon: const Icon(Icons.forward_10),
                          onPressed: isLoading || !isReady
                              ? null
                              : () {
                            final dur = player.duration ?? Duration.zero;
                            final pos = player.position + const Duration(seconds: 10);
                            player.seek(pos < dur ? pos : dur - const Duration(milliseconds: 500));
                          },
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ],
                    ),

                    // Thời gian + Volume
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        StreamBuilder<Duration>(
                          stream: player.positionStream,
                          builder: (context, snapshot) {
                            final pos = snapshot.data ?? Duration.zero;
                            final dur = player.duration ?? Duration.zero;
                            final fmt = (Duration d) => '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
                            return Text(
                              '${fmt(pos)} / ${fmt(dur)}',
                              style: TextStyle(fontSize: 11, color: isDarkMode ? Colors.white70 : Colors.black54),
                            );
                          },
                        ),

                        // Volume control
                        StreamBuilder<double>(
                          stream: player.volumeStream,
                          builder: (context, snapshot) {
                            final vol = snapshot.data ?? 1.0;
                            final muted = vol == 0.0;
                            return Row(
                              children: [
                                GestureDetector(
                                  onTap: isLoading ? null : () => player.setVolume(muted ? 1.0 : 0.0),
                                  child: Icon(
                                    muted ? Icons.volume_off : Icons.volume_up,
                                    size: 18,
                                    color: isLoading ? Colors.grey : (isDarkMode ? Colors.white70 : Colors.black54),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 100,
                                  child: Slider(
                                    value: vol,
                                    min: 0.0,
                                    max: 1.0,
                                    onChanged: isLoading ? null : (v) => player.setVolume(v),
                                    activeColor: const Color(0xFF2ECC71),
                                    inactiveColor: Colors.grey[400],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Thông báo không có audio
  Widget _buildNoAudioState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.audiotrack_outlined, color: Colors.orange.shade700),
          const SizedBox(width: 12),
          Text(
            "Trang này hiện chưa có Audio",
            style: TextStyle(
              color: Colors.orange.shade800,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      padding: const EdgeInsets.all(16),
      child: const LinearProgressIndicator(backgroundColor: Colors.transparent),
    );
  }

  Widget _buildErrorState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      padding: const EdgeInsets.all(16),
      child: const Text("Lỗi tải dữ liệu audio", style: TextStyle(color: Colors.red)),
    );
  }
}