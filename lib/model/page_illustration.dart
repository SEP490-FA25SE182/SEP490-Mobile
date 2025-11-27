class PageIllustrationModel {
  final String pageIllustrationId;
  final String pageId;
  final String illustrationId;

  const PageIllustrationModel({
    required this.pageIllustrationId,
    required this.pageId,
    required this.illustrationId,
  });

  factory PageIllustrationModel.fromJson(Map<String, dynamic> json) {
    return PageIllustrationModel(
      pageIllustrationId: json['pageIllustrationId'] ?? '',
      pageId: json['pageId'] ?? '',
      illustrationId: json['illustrationId'] ?? '',
    );
  }
}