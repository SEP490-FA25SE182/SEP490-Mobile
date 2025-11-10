import 'package:meta/meta.dart';
import '../util/model.dart';
import 'page.dart';

@immutable
class Chapter {
  final String chapterId;
  final String? chapterName;
  final int chapterNumber;
  final String? decription;
  final String? review;
  final String? isActived;
  final DateTime? updatedAt;
  final DateTime? createdAt;
  final DateTime? publishedDate;
  final int? progressStatus;
  final int? publicationStatus;
  final String bookId;
  final List<PageModel> pages;

  const Chapter({
    required this.chapterId,
    this.chapterName,
    required this.chapterNumber,
    this.decription,
    this.review,
    this.isActived,
    this.updatedAt,
    this.createdAt,
    this.publishedDate,
    this.progressStatus,
    this.publicationStatus,
    required this.bookId,
    this.pages = const [],
  });

  factory Chapter.fromJson(Map<String, dynamic> j) {
    int _int(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '0') ?? 0;

    final rawPages = (j['pages'] as List?) ?? const [];
    final parsedPages = rawPages
        .whereType<Map>()
        .map((e) => PageModel.fromJson(e.cast<String, dynamic>()))
        .toList();

    return Chapter(
      chapterId: (j['chapterId'] ?? '').toString(),
      chapterName: j['chapterName']?.toString(),
      chapterNumber: _int(j['chapterNumber']),
      decription: j['decription']?.toString(),
      review: j['review']?.toString(),
      isActived: j['isActived']?.toString(),
      updatedAt: parseInstant(j['updatedAt']),
      createdAt: parseInstant(j['createdAt']),
      publishedDate: parseInstant(j['publishedDate']),
      progressStatus: j['progressStatus'] is int
          ? j['progressStatus']
          : int.tryParse(j['progressStatus']?.toString() ?? ''),
      publicationStatus: j['publicationStatus'] is int
          ? j['publicationStatus']
          : int.tryParse(j['publicationStatus']?.toString() ?? ''),
      bookId: (j['bookId'] ?? '').toString(),
      pages: parsedPages,
    );
  }

  Map<String, dynamic> toJson() => {
    'chapterId': chapterId,
    if (chapterName != null) 'chapterName': chapterName,
    'chapterNumber': chapterNumber,
    if (decription != null) 'decription': decription,
    if (review != null) 'review': review,
    if (isActived != null) 'isActived': isActived,
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (publishedDate != null) 'publishedDate': publishedDate!.toIso8601String(),
    if (progressStatus != null) 'progressStatus': progressStatus,
    if (publicationStatus != null) 'publicationStatus': publicationStatus,
    'bookId': bookId,
    'pages': pages.map((e) => e.toJson()).toList(),
  };
}
