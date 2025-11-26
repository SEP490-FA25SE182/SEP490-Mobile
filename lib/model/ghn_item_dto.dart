class GhnItemDTO {
  final String name;
  final int quantity;
  final int weight;
  final int length;
  final int width;
  final int height;
  final Map<String, dynamic> category;

  const GhnItemDTO({
    required this.name,
    required this.quantity,
    required this.weight,
    required this.length,
    required this.width,
    required this.height,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
    "name": name,
    "quantity": quantity,
    "weight": weight,
    "length": length,
    "width": width,
    "height": height,
    "category": category,
  };
}