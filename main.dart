import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(
    const MaterialApp(home: Game2048(), debugShowCheckedModeBanner: false));

// 1. Модель плитки
class Tile {
  final int id; // Уникальный номер, чтобы Flutter не путал плитки
  int x, y, value;
  bool isNew;
  bool isMerged;

  Tile(
      {required this.id,
      required this.x,
      required this.y,
      required this.value,
      this.isNew = true,
      this.isMerged = false});
}

class Game2048 extends StatefulWidget {
  const Game2048({super.key});
  @override
  _Game2048State createState() => _Game2048State();
}

class _Game2048State extends State<Game2048> {
  List<Tile> tiles = [];
  int score = 0;
  int nextId = 0;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    setupGame();
  }

  void setupGame() {
    setState(() {
      tiles.clear();
      score = 0;
      nextId = 0;
      addNewTile();
      addNewTile();
    });
  }

  void addNewTile() {
    List<Point<int>> emptyCells = [];
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        if (!tiles.any((t) => t.x == c && t.y == r))
          emptyCells.add(Point(c, r));
      }
    }
    if (emptyCells.isNotEmpty) {
      var cell = emptyCells[Random().nextInt(emptyCells.length)];
      tiles.add(Tile(
          id: nextId++,
          x: cell.x,
          y: cell.y,
          value: Random().nextInt(10) == 0 ? 4 : 2));
    }
  }

  void move(String direction) {
    setState(() {
      // Сбрасываем флаги анимаций перед ходом
      for (var t in tiles) {
        t.isNew = false;
        t.isMerged = false;
      }

      bool moved = false;
      // Логика перемещения (упрощенно для примера)
      // В реальном 2048 она чуть сложнее, но для анимации важно менять x и y
      if (direction == 'left') moved = moveTiles(false, false);
      if (direction == 'right') moved = moveTiles(false, true);
      if (direction == 'up') moved = moveTiles(true, false);
      if (direction == 'down') moved = moveTiles(true, true);

      if (moved) {
        // Задержка перед появлением новой плитки, чтобы старые успели доехать
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) setState(() => addNewTile());
        });
      }
    });
  }

  bool moveTiles(bool vertical, bool reverse) {
    bool moved = false;
    for (int i = 0; i < 4; i++) {
      var line = tiles.where((t) => (vertical ? t.x : t.y) == i).toList();
      line.sort(
          (a, b) => (vertical ? a.y : a.x).compareTo(vertical ? b.y : b.x));
      if (reverse) line = line.reversed.toList();

      int targetPos = reverse ? 3 : 0;
      for (int j = 0; j < line.length; j++) {
        var tile = line[j];
        int currentPos = vertical ? tile.y : tile.x;

        // Поиск плитки для слияния
        Tile? mergeTarget;
        if (j > 0 && line[j - 1].value == tile.value && !line[j - 1].isMerged) {
          mergeTarget = line[j - 1];
        }

        if (mergeTarget != null) {
          // Слияние
          tile.x = mergeTarget.x;
          tile.y = mergeTarget.y;
          var oldTile = tile;
          Future.delayed(const Duration(milliseconds: 100), () {
            setState(() {
              mergeTarget!.value *= 2;
              score += mergeTarget.value;
              mergeTarget.isMerged = true;
              tiles.remove(oldTile);
            });
          });
          moved = true;
        } else {
          // Просто движение
          if (currentPos != targetPos) {
            if (vertical)
              tile.y = targetPos;
            else
              tile.x = targetPos;
            moved = true;
          }
          targetPos = reverse ? targetPos - 1 : targetPos + 1;
        }
      }
    }
    return moved;
  }

  @override
  Widget build(BuildContext context) {
    double gridSize = min(MediaQuery.of(context).size.width, 400);
    double tileSize = (gridSize - 50) / 4;

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) move('left');
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) move('right');
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) move('up');
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) move('down');
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF8EF),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Score: $score",
                  style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF776E65))),
              const SizedBox(height: 20),
              GestureDetector(
                onVerticalDragEnd: (d) =>
                    move(d.primaryVelocity! < 0 ? 'up' : 'down'),
                onHorizontalDragEnd: (d) =>
                    move(d.primaryVelocity! < 0 ? 'left' : 'right'),
                child: Container(
                  width: gridSize,
                  height: gridSize,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: const Color(0xFFBBADA0),
                      borderRadius: BorderRadius.circular(10)),
                  child: Stack(
                    children: [
                      // Фоновая сетка
                      for (int i = 0; i < 16; i++)
                        Positioned(
                          left: (i % 4) * (tileSize + 10),
                          top: (i ~/ 4) * (tileSize + 10),
                          child: Container(
                            width: tileSize,
                            height: tileSize,
                            decoration: BoxDecoration(
                                color: const Color(0xFFCDC1B4),
                                borderRadius: BorderRadius.circular(5)),
                          ),
                        ),
                      // Живые плитки
                      ...tiles.map((tile) => TileWidget(
                          key: ValueKey(tile.id), tile: tile, size: tileSize)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: setupGame,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8F7A66)),
                child: const Text("New Game",
                    style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// 2. Виджет отдельной плитки с анимациями
class TileWidget extends StatelessWidget {
  final Tile tile;
  final double size;
  const TileWidget({required Key key, required this.tile, required this.size})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Анимирует перемещение (x, y)
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
      left: tile.x * (size + 10),
      top: tile.y * (size + 10),
      child: AnimatedScale(
        // Эффект появления и слияния
        duration: const Duration(milliseconds: 200),
        scale: tile.isMerged ? 1.15 : 1.0,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: getTileColor(tile.value),
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              if (tile.isMerged)
                BoxShadow(color: Colors.orange.withOpacity(0.5), blurRadius: 10)
            ],
          ),
          child: Center(
            child: Text(
              "${tile.value}",
              style: TextStyle(
                fontSize: tile.value < 100 ? 30 : 24,
                fontWeight: FontWeight.bold,
                color: tile.value <= 4 ? const Color(0xFF776E65) : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color getTileColor(int value) {
    switch (value) {
      case 2:
        return const Color(0xFFEEE4DA);
      case 4:
        return const Color(0xFFEDE0C8);
      case 8:
        return const Color(0xFFF2B179);
      case 16:
        return const Color(0xFFF59563);
      case 32:
        return const Color(0xFFF67C5F);
      case 64:
        return const Color(0xFFF65E3B);
      case 128:
        return const Color(0xFFEDCF72);
      case 256:
        return const Color(0xFFEDCC61);
      case 512:
        return const Color(0xFFEDC850);
      case 1024:
        return const Color(0xFFEDC53F);
      case 2048:
        return const Color(0xFFEDC22E);
      default:
        return Colors.black;
    }
  }
}
