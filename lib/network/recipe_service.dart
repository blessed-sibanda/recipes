import 'package:flutter/cupertino.dart';
import 'package:http/http.dart';

const String apiKey = '099da388b47c054c56b12d2a02fff1ee';
const String apiId = '75678367';
var apiUrl = 'https://api.edamam.com/search';

Future getData(String url) async {
  print('Calling url: $url');
  final response = await get(Uri.parse(url));
  if (response.statusCode == 200) {
    return response.body;
  } else {
    print(response.statusCode);
  }
}

class RecipeService {
  Future<dynamic> getRecipes(String query, int from, int to) async {
    final recipeData = await getData(
        '$apiUrl?app_id=$apiId&app_key=$apiKey&q=$query&from=$from&to=$to');
    return recipeData;
  }
}
