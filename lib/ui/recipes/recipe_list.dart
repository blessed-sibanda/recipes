import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:chopper/chopper.dart';
import 'package:recipes/ui/recipe_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/custom_dropdown.dart';
import '../colors.dart';
import '../../network/recipe_model.dart';
import './recipe_details.dart';
import '../../network/recipe_service.dart';
import '../../network/model_response.dart';
import '../../network/service_interface.dart';
import '../../data/models/models.dart';
import '../../mock_service/mock_service.dart';

class RecipeList extends StatefulWidget {
  const RecipeList({Key? key}) : super(key: key);

  @override
  _RecipeListState createState() => _RecipeListState();
}

class _RecipeListState extends State<RecipeList> {
  static const String prefSearchKey = 'previousSearches';

  late TextEditingController searchTextController;
  final ScrollController _scrollController = ScrollController();
  List<APIHits> currentSearchList = [];
  int currentCount = 0;
  int currentStartPosition = 0;
  int currentEndPosition = 20;
  int pageCount = 20;
  bool hasMore = false;
  bool loading = false;
  bool inErrorState = false;
  List<String> previousSearches = <String>[];

  @override
  void initState() {
    super.initState();
    getPreviousSearches();
    searchTextController = TextEditingController(text: '');
    _scrollController.addListener(() {
      final triggerFetchMoreSize =
          0.7 * _scrollController.position.maxScrollExtent;

      if (_scrollController.position.pixels > triggerFetchMoreSize) {
        if (hasMore &&
            currentEndPosition < currentCount &&
            !loading &&
            !inErrorState) {
          setState(() {
            loading = true;
            currentStartPosition = currentEndPosition;
            currentEndPosition =
                min(currentStartPosition + pageCount, currentCount);
          });
        }
      }
    });
  }

  @override
  void dispose() {
    searchTextController.dispose();
    super.dispose();
  }

  void savePreviousSearches() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList(prefSearchKey, previousSearches);
  }

  void getPreviousSearches() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(prefSearchKey)) {
      previousSearches = prefs.getStringList(prefSearchKey)!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [_buildSearchCard(), _buildRecipeLoader(context)],
        ),
      ),
    );
  }

  Widget _buildSearchCard() {
    return Card(
      elevation: 4,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8.0))),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          children: [
            IconButton(
                onPressed: () {
                  startSearch(searchTextController.text);
                  final currentFocus = FocusScope.of(context);
                  if (!currentFocus.hasPrimaryFocus) {
                    currentFocus.unfocus();
                  }
                },
                icon: const Icon(Icons.search)),
            const SizedBox(
              width: 6.0,
            ),
            Expanded(
                child: Row(
              children: [
                Expanded(
                    child: TextField(
                  decoration: const InputDecoration(
                      border: InputBorder.none, hintText: 'Search'),
                  autofocus: false,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (value) {
                    if (!previousSearches.contains(value)) {
                      previousSearches.add(value);
                      savePreviousSearches();
                    }
                  },
                  controller: searchTextController,
                  onChanged: (query) => {
                    if (query.length >= 3)
                      {
                        // Rebuild list
                        setState(() {
                          currentSearchList.clear();
                          currentCount = 0;
                          currentEndPosition = pageCount;
                          currentStartPosition = 0;
                        })
                      }
                  },
                )),
                PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: lightGrey,
                    ),
                    onSelected: (String value) {
                      searchTextController.text = value;
                      startSearch(searchTextController.text);
                    },
                    itemBuilder: (BuildContext context) {
                      return previousSearches
                          .map<CustomDropdownMenuItem<String>>((String value) {
                        return CustomDropdownMenuItem(
                            value: value,
                            text: value,
                            callback: () {
                              setState(() {
                                previousSearches.remove(value);
                                Navigator.pop(context);
                              });
                            });
                      }).toList();
                    }),
              ],
            ))
          ],
        ),
      ),
    );
  }

  void startSearch(String value) {
    setState(() {
      currentSearchList.clear();
      currentCount = 0;
      currentEndPosition = pageCount;
      currentStartPosition = 0;
      hasMore = true;

      if (!previousSearches.contains(value)) {
        previousSearches.add(value);
        savePreviousSearches();
      }
    });
  }

  Widget _buildRecipeLoader(BuildContext context) {
    if (searchTextController.text.length < 3) {
      return Container();
    }
    return FutureBuilder<Response<Result<APIRecipeQuery>>>(
      future: Provider.of<ServiceInterface>(context).queryRecipes(
          searchTextController.text.trim(),
          currentStartPosition,
          currentEndPosition),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
                textAlign: TextAlign.center,
                textScaleFactor: 1.3,
              ),
            );
          }
          loading = false;
          final result = snapshot.data?.body;
          if (result is Error) {
            inErrorState = true;
            return _buildRecipeList(context, currentSearchList);
          }
          inErrorState = false;
          final query = (result as Success).value;
          currentCount = query!.count;
          hasMore = query.more;
          currentSearchList.addAll(query.hits);
          if (query.to < currentEndPosition) {
            currentEndPosition = query.to;
          }
          return _buildRecipeList(context, currentSearchList);
        } else {
          if (currentCount == 0) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else {
            return _buildRecipeList(context, currentSearchList);
          }
        }
      },
    );
  }

  Widget _buildRecipeList(BuildContext recipeListContext, List<APIHits> hits) {
    final size = MediaQuery.of(context).size;
    const itemHeight = 310;
    final itemWidth = size.width / 2;

    return Flexible(
        child: GridView.builder(
            controller: _scrollController,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, childAspectRatio: (itemWidth / itemHeight)),
            itemCount: hits.length,
            itemBuilder: (BuildContext context, int index) {
              return _buildRecipeCard(recipeListContext, hits, index);
            }));
  }

  Widget _buildRecipeCard(BuildContext context, List<APIHits> hits, int index) {
    final recipe = hits[index].recipe;
    return GestureDetector(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            int id;
            Random random = new Random();
            id = random.nextInt(100000);
            final detailRecipe = Recipe(
                id: id,
                label: recipe.label,
                image: recipe.image,
                url: recipe.url,
                calories: recipe.calories,
                totalTime: recipe.totalTime,
                totalWeight: recipe.totalWeight);
            detailRecipe.ingredients = convertIngredients(recipe.ingredients);
            return RecipeDetails(recipe: detailRecipe);
          }));
        },
        child: recipeCard(recipe));
  }
}
