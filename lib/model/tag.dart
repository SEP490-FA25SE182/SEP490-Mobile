import 'package:meta/meta.dart';

@immutable
class Tag {
  final String tagId;
  final String name;
  final String isActived;

  const Tag({required this.tagId, required this.name, this.isActived = 'ACTIVE'});

  factory Tag.fromJson(Map<String, dynamic> j) => Tag(
    tagId: (j['tagId'] ?? '').toString(),
    name: (j['name'] ?? '').toString(),
    isActived: (j['isActived'] ?? '').toString(),
  );
}
