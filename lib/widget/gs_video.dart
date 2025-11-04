import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class GsVideo extends StatefulWidget {
  final String url;
  final bool autoPlay;
  final bool loop;
  final bool mute;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const GsVideo({
    super.key,
    required this.url,
    this.autoPlay = true,
    this.loop = true,
    this.mute = true,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  State<GsVideo> createState() => _GsVideoState();

  static String _gsToHttps(String gsUrl) {
    final uri = Uri.parse(gsUrl);
    final bucket = uri.host;
    final path = uri.pathSegments.join('/');
    final encoded = Uri.encodeComponent(path);
    return 'https://firebasestorage.googleapis.com/v0/b/$bucket/o/$encoded?alt=media';
  }
}

class _GsVideoState extends State<GsVideo> {
  VideoPlayerController? _controller;
  Future<void>? _initFut;

  @override
  void initState() {
    super.initState();
    final isGs = widget.url.startsWith('gs://');
    final playUrl = isGs ? GsVideo._gsToHttps(widget.url) : widget.url;

    _controller = VideoPlayerController.networkUrl(Uri.parse(playUrl));
    _initFut = _controller!.initialize().then((_) async {
      _controller!.setLooping(widget.loop);
      if (widget.mute) await _controller!.setVolume(0.0);
      if (widget.autoPlay) await _controller!.play();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final br = widget.borderRadius ?? BorderRadius.circular(1000);
    final w = widget.width;
    final h = widget.height;

    return ClipRRect(
      borderRadius: br,
      child: SizedBox(
        width: w,
        height: h,
        child: FutureBuilder(
          future: _initFut,
          builder: (_, snap) {
            if (snap.connectionState != ConnectionState.done || _controller == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: VideoPlayer(_controller!),
              ),
            );
          },
        ),
      ),
    );
  }
}
