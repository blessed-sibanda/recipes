import 'dart:core';
import 'dart:async';

import 'repository.dart';
import 'models/models.dart';

class MemoryRepository extends Repository {
  @override
  Future init() {
    return Future.value();
  }

  @override
  Future<void> close() async {
    _recipeStreamController.close();
    _ingredientStreamController.close();
  }

  final List<Recipe> _currentRecipes = <Recipe>[];
  final List<Ingredient> _currentIngredients = <Ingredient>[];

  @override
  Future<List<Recipe>> findAllRecipes() {
    return Future.value(_currentRecipes);
  }

  @override
  Future<Recipe> findRecipeById(int id) {
    return Future.value(
        _currentRecipes.firstWhere((recipe) => recipe.id == id));
  }

  @override
  Future<List<Ingredient>> findAllIngredients() {
    return Future.value(_currentIngredients);
  }

  @override
  Future<void> deleteIngredient(Ingredient ingredient) async {
    Future.value(_currentIngredients.remove(ingredient));
  }

  @override
  Future<void> deleteIngredients(List<Ingredient> ingredients) async {
    _currentIngredients
        .removeWhere((ingredient) => ingredients.contains(ingredient));
    _ingredientStreamController.sink.add(_currentIngredients);
  }

  @override
  Future<void> deleteRecipe(Recipe recipe) async {
    _currentRecipes.remove(recipe);
    deleteRecipeIngredients(recipe.id!);
    _recipeStreamController.sink.add(_currentRecipes);
  }

  @override
  Future<void> deleteRecipeIngredients(int recipeId) async {
    _currentIngredients
        .removeWhere((ingredient) => ingredient.recipeId == recipeId);
    _ingredientStreamController.sink.add(_currentIngredients);
  }

  @override
  Future<List<Ingredient>> findRecipeIngredients(int recipeId) {
    final recipe =
        _currentRecipes.firstWhere((recipe) => recipe.id == recipeId);
    final recipeIngredients = _currentIngredients
        .where((ingredient) => ingredient.recipeId == recipe.id)
        .toList();
    return Future.value(recipeIngredients);
  }

  @override
  Future<List<int>> insertIngredients(List<Ingredient> ingredients) {
    if (ingredients.length != 0) {
      _currentIngredients.addAll(ingredients);
      _ingredientStreamController.sink.add(_currentIngredients);
    }
    return Future.value(<int>[]);
  }

  @override
  Future<int> insertRecipe(Recipe recipe) {
    _currentRecipes.add(recipe);

    _recipeStreamController.sink.add(_currentRecipes);
    insertIngredients(recipe.ingredients);

    return Future.value(0);
  }

  Stream<List<Recipe>>? _recipeStream;
  Stream<List<Ingredient>>? _ingredientStream;

  final StreamController _recipeStreamController =
      StreamController<List<Recipe>>();
  final StreamController _ingredientStreamController =
      StreamController<List<Ingredient>>();

  @override
  Stream<List<Ingredient>> watchAllIngredients() {
    if (_ingredientStream == null) {
      _ingredientStream =
          _ingredientStreamController.stream as Stream<List<Ingredient>>;
    }
    return _ingredientStream!;
  }

  @override
  Stream<List<Recipe>> watchAllRecipes() {
    if (_recipeStream == null) {
      _recipeStream = _recipeStreamController.stream as Stream<List<Recipe>>;
    }
    return _recipeStream!;
  }
}
