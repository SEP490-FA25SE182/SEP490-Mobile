class Book {
  final String bookId;
  final String bookName;
  final String? authorId;
  final String coverUrl;
  final String? description;
  final int? progressStatus;
  final int? publicationStatus;
  final String? bookshelveId;
  final String isActived;
  final DateTime? updatedAt;
  final DateTime? createdAt;
  final DateTime? publishedDate;

  const Book({
    required this.bookId,
    required this.bookName,
    required this.coverUrl,
    this.authorId,
    this.description,
    this.progressStatus,
    this.publicationStatus,
    this.bookshelveId,
    this.isActived = 'ACTIVE',
    this.updatedAt,
    this.createdAt,
    this.publishedDate,
  });

  factory Book.fromJson(Map<String, dynamic> j) => Book(
    bookId: j['bookId'] ?? '',
    bookName: j['bookName'] ?? '',
    authorId: j['authorId'],
    coverUrl: j['coverUrl'] ?? '',
    description: j['decription'] ?? j['description'],
    progressStatus: j['progressStatus'],
    publicationStatus: j['publicationStatus'],
    bookshelveId: j['bookshelveId'],
    isActived: j['isActived'] ?? 'ACTIVE',
    updatedAt: j['updatedAt'] != null ? DateTime.tryParse(j['updatedAt']) : null,
    createdAt: j['createdAt'] != null ? DateTime.tryParse(j['createdAt']) : null,
    publishedDate: j['publishedDate'] != null ? DateTime.tryParse(j['publishedDate']) : null,
  );
}
