class Category {
  final String id;
  final String name;
  final String color;
  final bool isDefault;

  Category({
    required this.id,
    required this.name,
    required this.color,
    this.isDefault = false,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'isDefault': isDefault,
    };
  }

  Category copyWith({
    String? id,
    String? name,
    String? color,
    bool? isDefault,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

