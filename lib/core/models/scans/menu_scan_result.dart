import 'package:equatable/equatable.dart';

class MenuItemResult extends Equatable {
  const MenuItemResult({required this.name, this.description = '', this.price, this.category, this.ingredients = const [], this.dietaryTags = const [], this.gutImpact});

  factory MenuItemResult.fromMap(Map<String, dynamic> map) => MenuItemResult(
    name: map['name']?.toString() ?? '',
    description: map['description']?.toString() ?? '',
    price: map['price']?.toString(),
    category: map['category']?.toString(),
    ingredients: (map['ingredients'] as List? ?? const []).cast<String>(),
    dietaryTags: (map['dietaryTags'] as List? ?? const []).cast<String>(),
    gutImpact: map['gutImpact']?.toString(),
  );

  final String name;
  final String description;
  final String? price;
  final String? category;
  final List<String> ingredients;
  final List<String> dietaryTags;
  final String? gutImpact;

  Map<String, dynamic> toMap() => {
    'name': name,
    'description': description,
    if (price != null) 'price': price,
    if (category != null) 'category': category,
    'ingredients': ingredients,
    'dietaryTags': dietaryTags,
    if (gutImpact != null) 'gutImpact': gutImpact,
  };

  @override
  List<Object?> get props => [name, description, price, category, ingredients, dietaryTags, gutImpact];
}

class MenuScanResult extends Equatable {
  const MenuScanResult({this.restaurantName, this.categories = const [], this.menuItems = const [], this.detectedText, this.location});

  factory MenuScanResult.fromMap(Map<String, dynamic> map) => MenuScanResult(
    restaurantName: map['restaurantName']?.toString(),
    categories: (map['categories'] as List? ?? const []).cast<String>(),
    menuItems: (map['menuItems'] as List? ?? const []).map((e) => MenuItemResult.fromMap(Map<String, dynamic>.from(e as Map))).toList(),
    detectedText: map['detectedText']?.toString(),
    location: map['location']?.toString(),
  );

  final String? restaurantName;
  final List<String> categories;
  final List<MenuItemResult> menuItems;
  final String? detectedText;
  final String? location;

  Map<String, dynamic> toMap() => {
    if (restaurantName != null) 'restaurantName': restaurantName,
    'categories': categories,
    'menuItems': menuItems.map((e) => e.toMap()).toList(),
    if (detectedText != null) 'detectedText': detectedText,
    if (location != null) 'location': location,
  };

  @override
  List<Object?> get props => [restaurantName, categories, menuItems, detectedText, location];
}
