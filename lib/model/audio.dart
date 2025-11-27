class AudioModel {
  final String audioId;
  final String audioUrl;
  final String? voice;
  final String? format;
  final String? language;
  final double? durationMs;
  final String? title;

  const AudioModel({
    required this.audioId,
    required this.audioUrl,
    this.voice,
    this.format,
    this.language,
    this.durationMs,
    this.title,
  });

  factory AudioModel.fromJson(Map<String, dynamic> json) {
    return AudioModel(
      audioId: json['audioId'] ?? '',
      audioUrl: json['audioUrl'] ?? '',
      voice: json['voice'],
      format: json['format'],
      language: json['language'],
      durationMs: (json['durationMs'] as num?)?.toDouble(),
      title: json['title'],
    );
  }
}