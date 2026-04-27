class FavoriteStyleItem {
  final int styleId;
  final String styleName;

  FavoriteStyleItem({
    required this.styleId,
    required this.styleName,
  });

  factory FavoriteStyleItem.fromJson(Map<String, dynamic> json) {
    return FavoriteStyleItem(
      styleId: json['style_id'],
      styleName: json['style_name'],
    );
  }
}

class FavoriteMoveItem {
  final int moveId;
  final String moveName;
  final int? styleId;
  final String? styleName;

  FavoriteMoveItem({
    required this.moveId,
    required this.moveName,
    this.styleId,
    this.styleName,
  });

  factory FavoriteMoveItem.fromJson(Map<String, dynamic> json) {
    return FavoriteMoveItem(
      moveId: json['move_id'],
      moveName: json['move_name'],
      styleId: json['style_id'],
      styleName: json['style_name'],
    );
  }
}

class FavoritesResponseModel {
  final List<FavoriteStyleItem> styles;
  final List<FavoriteMoveItem> moves;

  FavoritesResponseModel({
    required this.styles,
    required this.moves,
  });

  factory FavoritesResponseModel.fromJson(Map<String, dynamic> json) {
    return FavoritesResponseModel(
      styles: (json['styles'] as List<dynamic>)
          .map((e) => FavoriteStyleItem.fromJson(e))
          .toList(),
      moves: (json['moves'] as List<dynamic>)
          .map((e) => FavoriteMoveItem.fromJson(e))
          .toList(),
    );
  }
}