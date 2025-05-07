import 'dart:ui' as ui;

class SpriteSheet {
  final ui.Image image;
  final int rows;
  final int columns;

  SpriteSheet({
    required this.image,
    required this.rows,
    required this.columns,
  });

  ui.Rect getFrame(int row, int column) {
    final frameWidth = image.width / columns;
    final frameHeight = image.height / rows;
    return ui.Rect.fromLTWH(
      column * frameWidth,
      row * frameHeight,
      frameWidth,
      frameHeight,
    );
  }
}
