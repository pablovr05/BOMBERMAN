class GameData {
  final String name;
  final List<Level> levels;

  GameData({required this.name, required this.levels});

  factory GameData.fromJson(Map<String, dynamic> json) {
    var levelsList =
        (json['levels'] as List)
            .map((levelJson) => Level.fromJson(levelJson))
            .toList();

    return GameData(name: json['name'], levels: levelsList);
  }
}

class Level {
  final String name;
  final String description;
  final List<Layer> layers;

  Level({required this.name, required this.description, required this.layers});

  factory Level.fromJson(Map<String, dynamic> json) {
    var layersList =
        (json['layers'] as List)
            .map((layerJson) => Layer.fromJson(layerJson))
            .toList();

    return Level(
      name: json['name'],
      description: json['description'],
      layers: layersList,
    );
  }
}

class Layer {
  final String name;
  final int x;
  final int y;
  final int depth;
  final String tilesSheetFile;
  final int tilesWidth;
  final int tilesHeight;
  final List<List<int>> tileMap;
  final bool visible;

  Layer({
    required this.name,
    required this.x,
    required this.y,
    required this.depth,
    required this.tilesSheetFile,
    required this.tilesWidth,
    required this.tilesHeight,
    required this.tileMap,
    required this.visible,
  });

  factory Layer.fromJson(Map<String, dynamic> json) {
    var tileMapList =
        (json['tileMap'] as List).map((row) => List<int>.from(row)).toList();

    return Layer(
      name: json['name'],
      x: json['x'],
      y: json['y'],
      depth: json['depth'],
      tilesSheetFile: json['tilesSheetFile'],
      tilesWidth: json['tilesWidth'],
      tilesHeight: json['tilesHeight'],
      tileMap: tileMapList,
      visible: json['visible'],
    );
  }
}
