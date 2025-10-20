
enum IsActived { ACTIVE, INACTIVE }

IsActived parseIsActived(dynamic v) {
  if (v == null) return IsActived.ACTIVE;
  final s = v.toString().trim().toUpperCase();
  switch (s) {
    case 'INACTIVE':
    case '0':
    case 'FALSE':
      return IsActived.INACTIVE;
    case 'ACTIVE':
    case '1':
    case 'TRUE':
    default:
      return IsActived.ACTIVE;
  }
}

String isActivedToJson(IsActived e) => e.name;

DateTime? parseLocalDate(dynamic v) {
  if (v == null) return null;
  try { return DateTime.parse(v.toString()); } catch (_) { return null; }
}

DateTime? parseInstant(dynamic v) {
  if (v == null) return null;
  try { return DateTime.parse(v.toString()); } catch (_) { return null; }
}
