import 'package:meta/meta.dart';
import '../util/model.dart';
import 'audio.dart';
import 'illustration.dart';

enum PageType { text, picture, unknown }

@immutable
class PageModel {
  final String pageId;
  final int pageNumber;
  final String? content;
  final DateTime? updatedAt;
  final DateTime? createdAt;
  final String? isActived;
  final String chapterId;
  final List<IllustrationModel> illustrations;
  final List<AudioModel> audios;
  final PageType pageType;

  const PageModel({
    required this.pageId,
    required this.pageNumber,
    this.content,
    this.updatedAt,
    this.createdAt,
    this.isActived,
    required this.chapterId,
    this.illustrations = const [],
    this.audios = const [],
    this.pageType = PageType.unknown,
  });

  factory PageModel.fromJson(Map<String, dynamic> j) {
    int _int(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '0') ?? 0;

    final typeStr = (j['pageType'] ?? j['type'] ?? '').toString().toUpperCase();
    PageType pageType = PageType.unknown;
    if (typeStr.contains('TEXT')) pageType = PageType.text;
    if (typeStr.contains('PICTURE') || typeStr.contains('IMAGE')) pageType = PageType.picture;

    return PageModel(
      pageId: (j['pageId'] ?? '').toString(),
      pageNumber: _int(j['pageNumber']),
      content: j['content']?.toString(),
      updatedAt: parseInstant(j['updatedAt']),
      createdAt: parseInstant(j['createdAt']),
      isActived: j['isActived']?.toString(),
      chapterId: (j['chapterId'] ?? '').toString(),
      illustrations: (j['illustrations'] as List<dynamic>?)
          ?.map((e) => IllustrationModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      audios: (j['audios'] as List<dynamic>?)
          ?.map((e) => AudioModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      pageType: pageType,
    );
  }

  bool get isTextPage => pageType == PageType.text || (content?.trim().isNotEmpty == true && illustrations.isEmpty);
  bool get isPicturePage => pageType == PageType.picture || illustrations.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'pageId': pageId,
    'pageNumber': pageNumber,
    if (content != null) 'content': content,
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (isActived != null) 'isActived': isActived,
    'chapterId': chapterId,
    'pageType': pageType.toString().split('.').last,
  };
}
