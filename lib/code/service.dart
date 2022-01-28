import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:slide_puzzle/code/models.dart';

class Service {
  List<TilesModel> changePosition(
      List<TilesModel> tileList, TilesModel thisTile, TilesModel whiteTile,
      {int gridSize = 1}) {
    int distance =
        ((thisTile.currentIndex - whiteTile.currentIndex) ~/ gridSize);
    int whiteIndex = whiteTile.currentIndex;
    for (var i = 1; i <= distance.abs(); i++) {
      TilesModel replaceableTile = tileList.firstWhere((element) =>
          element.currentIndex ==
          (distance < 0
              ? whiteIndex - gridSize * i
              : whiteIndex + gridSize * i));
      // if (tileProvider != null) {
      // tileProvider.swapTiles(
      //     replaceableTile.currentIndex, whiteTile.currentIndex);
      // }
      int temp = replaceableTile.currentIndex;
      var tempCoords = replaceableTile.coordinates;
      replaceableTile.currentIndex = whiteTile.currentIndex;
      replaceableTile.coordinates = whiteTile.coordinates;
      whiteTile.currentIndex = temp;
      whiteTile.coordinates = tempCoords;
    }
    return tileList;
  }

  List<TilesModel>? moveWhite(List<TilesModel> tileList, Direction direction) {
    int gridSize = sqrt(tileList.length).toInt();
    TilesModel whiteTile = tileList.singleWhere((element) => element.isWhite);
    int row = whiteTile.coordinates.row;
    int column = whiteTile.coordinates.column;
    bool left = column == 0;
    bool right = column == gridSize - 1;
    bool top = row == 0;
    bool bottom = row == gridSize - 1;
    switch (direction) {
      case Direction.left:
        if (right) break;
        var replaceableTile = tileList.singleWhere((element) =>
            element.coordinates.row == row &&
            element.coordinates.column == column + 1);
        return changePosition(tileList, replaceableTile, whiteTile);
        break;
      case Direction.down:
        if (top) break;
        var replaceableTile = tileList.singleWhere((element) =>
            element.coordinates.row == row - 1 &&
            element.coordinates.column == column);
        return changePosition(tileList, replaceableTile, whiteTile,
            gridSize: gridSize);
        break;
      case Direction.right:
        if (left) break;
        var replaceableTile = tileList.singleWhere((element) =>
            element.coordinates.row == row &&
            element.coordinates.column == column - 1);
        return changePosition(tileList, replaceableTile, whiteTile);
        break;
      case Direction.up:
        if (bottom) break;
        var replaceableTile = tileList.singleWhere((element) =>
            element.coordinates.row == row + 1 &&
            element.coordinates.column == column);
        return changePosition(tileList, replaceableTile, whiteTile,
            gridSize: gridSize);
        break;
    }
  }

  bool isSolvable(List<TilesModel> list) {
    int len = list.length;
    int gridSize = sqrt(len).toInt();
    int inversions = 0;
    for (var i = 0; i < len; i++) {
      if (!list[i].isWhite) {
        for (var j = i + 1; j < len; j++) {
          if (list[i].currentIndex > list[j].currentIndex && !list[j].isWhite) {
            inversions++;
          }
        }
      }
    }
    if (gridSize.isOdd) {
      return inversions.isEven;
    }
    TilesModel whiteTile = list.firstWhere((element) => element.isWhite);
    int row = (whiteTile.currentIndex / gridSize).floor();
    if ((gridSize - row).isOdd) {
      return inversions.isEven;
    } else {
      return inversions.isOdd;
    }
  }

  bool isSolved(List<TilesModel> list) {
    return list
        .every((element) => element.currentIndex == element.defaultIndex);
  }

  Future<List<String>> getSolution(List<TilesModel> tileList) async {
    List<TilesModel> list = List.from(tileList)
      ..sort((a, b) => a.currentIndex.compareTo(b.currentIndex));
    String tiles = "";
    for (var e in list) {
      tiles = tiles + (e.defaultIndex + 1).toString() + " ";
    }
    // why the code below does not work I have no idea
    // list.map((e) => tiles = tiles + (e.defaultIndex + 1).toString());
    print(tiles);
    String val = tiles
        .substring(0, tiles.length - 1)
        .replaceAll(",", "")
        .replaceAll(tileList.length.toString(), "0");
    // .replaceAll(" ", "%20");
    print(val);
    var url =
        Uri.parse("https://npuzzlesolver-ajp37iulda-ez.a.run.app/?tiles=$val");
    try {
      var response = await http.get(url);
      var body = (response.body);
      // print(body);
      return body.split(", ");
    } catch (e) {
      print(e);
    }
    return [];
  }

  bool checkIfParent(Direction thisMove, Direction? previousMove) {
    bool allowed = true;
    if (previousMove == null) {
      return false;
    }
    switch (thisMove) {
      case Direction.left:
        if (previousMove == Direction.right) allowed = false;
        break;
      case Direction.right:
        if (previousMove == Direction.left) allowed = false;
        break;
      case Direction.up:
        if (previousMove == Direction.down) allowed = false;
        break;
      case Direction.down:
        if (previousMove == Direction.up) allowed = false;
        break;
    }
    return !allowed;
  }
}