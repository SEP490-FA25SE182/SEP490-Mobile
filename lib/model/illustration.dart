class IllustrationModel {
  final String illustrationId;
  final String imageUrl; // gs://...
  final String? title;
  final int? width;
  final int? height;

  const IllustrationModel({
    required this.illustrationId,
    required this.imageUrl,
    this.title,
    this.width,
    this.height,
  });

  factory IllustrationModel.fromJson(Map<String, dynamic> json) {
    return IllustrationModel(
      illustrationId: json['illustrationId'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      title: json['title'],
      width: json['width'],
      height: json['height'],
    );
  }
}