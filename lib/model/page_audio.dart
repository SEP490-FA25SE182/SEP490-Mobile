class PageAudioModel {
  final String pageAudioId;
  final String pageId;
  final String audioId;

  const PageAudioModel({
    required this.pageAudioId,
    required this.pageId,
    required this.audioId,
  });

  factory PageAudioModel.fromJson(Map<String, dynamic> json) {
    return PageAudioModel(
      pageAudioId: json['pageAudioId'] ?? '',
      pageId: json['pageId'] ?? '',
      audioId: json['audioId'] ?? '',
    );
  }
}