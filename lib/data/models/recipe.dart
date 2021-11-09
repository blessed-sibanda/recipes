import 'package:equatable/equatable.dart';
import 'package:recipes/data/models/ingredient.dart';

class Recipe extends Equatable {
  int? id;
  final String label;
  final String image;
  final String url;

  List<Ingredient> ingredients = [];
  final double calories;
  final double totalWeight;
  final double totalTime;

  Recipe({
    this.id,
    required this.label,
    required this.image,
    required this.url,
    required this.calories,
    required this.totalWeight,
    required this.totalTime,
  });

  @override
  List<Object> get props =>
      [label, image, url, calories, totalWeight, totalTime];

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
      id: json['recipeId'],
      label: json['label'],
      image: json['image'],
      url: json['url'],
      calories: json['calories'],
      totalWeight: json['totalWeight'],
      totalTime: json['totalWeight']);

  Map<String, dynamic> toJson() => {
        'recipeId': id,
        'label': label,
        'image': image,
        'url': url,
        'calories': calories,
        'totalWeight': totalWeight,
        'totalTime': totalTime,
      };
}
