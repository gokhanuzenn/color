import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum DrawingTool {
  bucket,
  kursun,
  tukenmez,
  keceli,
  firca_classic,
  sulu_firca,
  boya_kalemi,
  eraser,
  gradyan_fircasi,
}

abstract class PaintOp {
  void draw(Canvas canvas, double parentOpacity, Color secondaryColor);
}

class PathOp extends PaintOp {
  final List<Offset?> points;
  final DrawingTool tool;
  final Color color;
  final double strokeWidth;
  final double opacity;

  PathOp({
    required this.points,
    required this.tool,
    required this.color,
    required this.strokeWidth,
    this.opacity = 1.0,
  });

  @override
  void draw(Canvas canvas, double parentOpacity, Color secondaryColor) {
    final finalOpacity = opacity * parentOpacity;
    final paint = Paint()
      ..color = color.withOpacity(finalOpacity)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    if (tool == DrawingTool.eraser) {
      paint.blendMode = BlendMode.clear;
    }

    switch (tool) {
      case DrawingTool.sulu_firca:
        paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        paint.color = color.withOpacity(finalOpacity * 0.2);
        paint.strokeWidth = strokeWidth * 2.5;
        _drawBasic(canvas, paint);
        break;
      case DrawingTool.boya_kalemi:
        final rnd = math.Random(42);
        for (int i = 0; i < points.length - 1; i++) {
          if (points[i] != null && points[i + 1] != null) {
            for (int j = 0; j < 5; j++) {
              Offset off = Offset(rnd.nextDouble() * 4 - 2, rnd.nextDouble() * 4 - 2);
              canvas.drawLine(points[i]! + off, points[i + 1]! + off, paint..color = color.withOpacity(finalOpacity * 0.6));
            }
          }
        }
        break;
      case DrawingTool.gradyan_fircasi:
        if (points.length > 1) {
          for (int i = 0; i < points.length - 1; i++) {
            if (points[i] != null && points[i+1] != null) {
              paint.shader = ui.Gradient.linear(
                points[i]!,
                points[i+1]!,
                [secondaryColor.withOpacity(finalOpacity * 0.4), color.withOpacity(finalOpacity * 0.6)],
              );
              canvas.drawLine(points[i]!, points[i+1]!, paint);
            }
          }
        }
        break;
      default:
        _drawBasic(canvas, paint);
    }
  }

  void _drawBasic(Canvas canvas, Paint paint) {
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }
}

class ColoringCanvasScreen extends StatefulWidget {
  final String assetPath;
  final String templateId;

  const ColoringCanvasScreen({
    super.key,
    required this.assetPath,
    required this.templateId,
  });

  @override
  State<ColoringCanvasScreen> createState() => _ColoringCanvasScreenState();
}

class _ColoringCanvasScreenState extends State<ColoringCanvasScreen> {
  ui.Image? templateImage;
  List<PaintOp> operations = [];
  Color selectedColor = const Color(0xFFE94E77);
  Color secondaryColor = const Color(0xFFF6AD55);
  DrawingTool activeTool = DrawingTool.kursun;
  double brushWidth = 12.0;
  bool showSubToolMenu = false;
  String? currentMenuType;

  final List<List<PaintOp>> _undoStack = [];
  final List<List<PaintOp>> _redoStack = [];

  final List<Color> palette = [
    const Color(0xFF2D2D2D), const Color(0xFFE94E77), const Color(0xFFFF6B6B),
    const Color(0xFFF6AD55), const Color(0xFFFFD166), const Color(0xFF06D6A0),
    const Color(0xFF118AB2), const Color(0xFF073B4C), const Color(0xFF9B59B6),
    const Color(0xFFED4C67), const Color(0xFFA3CB38), const Color(0xFFC23616),
  ];

  @override
  void initState() {
    super.initState();
    _loadTemplate();
  }

  Future<void> _loadTemplate() async {
    final ByteData data = await rootBundle.load(widget.assetPath);
    final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final ui.FrameInfo fi = await codec.getNextFrame();
    setState(() {
      templateImage = fi.image;
    });
  }

  void _saveHistory() {
    _undoStack.add(List<PaintOp>.from(operations));
    _redoStack.clear();
    if (_undoStack.length > 50) _undoStack.removeAt(0);
  }

  void _undo() {
    if (_undoStack.isNotEmpty) {
      setState(() {
        _redoStack.add(List<PaintOp>.from(operations));
        operations = _undoStack.removeLast();
      });
    }
  }

  void _redo() {
    if (_redoStack.isNotEmpty) {
      setState(() {
        _undoStack.add(List<PaintOp>.from(operations));
        operations = _redoStack.removeLast();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDFBF7),
        elevation: 0,
        title: const Text('BOYAMA DUNYASI', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF2D2D2D))),
        actions: [
          IconButton(icon: const Icon(Icons.undo, color: Color(0xFF2D2D2D)), onPressed: _undo),
          IconButton(icon: const Icon(Icons.redo, color: Color(0xFF2D2D2D)), onPressed: _redo),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(4), child: Container(color: const Color(0xFF2D2D2D), height: 4)),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.white,
              child: GestureDetector(
                onPanStart: (details) {
                  _saveHistory();
                  setState(() {
                    operations.add(PathOp(
                      points: [details.localPosition],
                      tool: activeTool,
                      color: selectedColor,
                      strokeWidth: brushWidth,
                    ));
                  });
                },
                onPanUpdate: (details) {
                  setState(() {
                    if (operations.isNotEmpty && operations.last is PathOp) {
                      (operations.last as PathOp).points.add(details.localPosition);
                    }
                  });
                },
                onPanEnd: (_) {
                  setState(() {
                    if (operations.isNotEmpty && operations.last is PathOp) {
                      (operations.last as PathOp).points.add(null);
                    }
                  });
                },
                child: CustomPaint(
                  painter: ColoringPainter(
                    template: templateImage,
                    operations: operations,
                    secondaryColor: secondaryColor,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      decoration: const BoxDecoration(
        color: Color(0xFFFDFBF7),
        border: Border(top: BorderSide(color: Color(0xFF2D2D2D), width: 4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showSubToolMenu) _buildSubToolMenu(),
          const SizedBox(height: 12),
          _buildStrokeWidthSlider(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _toolButton(DrawingTool.kursun, Icons.edit, "Kalem", isMenu: true),
              _toolButton(DrawingTool.firca_classic, Icons.brush, "Firca", isMenu: true),
              _toolButton(DrawingTool.eraser, Icons.delete_outline, "Silgi"),
            ],
          ),
          const SizedBox(height: 16),
          _buildPalette(),
        ],
      ),
    );
  }

  Widget _buildStrokeWidthSlider() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF2D2D2D), width: 3),
        boxShadow: const [BoxShadow(color: Color(0xFF2D2D2D), offset: Offset(4, 4))],
      ),
      child: Row(
        children: [
          const Text("BOYUT", style: TextStyle(fontWeight: FontWeight.w900)),
          Expanded(
            child: Slider(
              value: brushWidth,
              min: 2.0,
              max: 50.0,
              activeColor: const Color(0xFF2D2D2D),
              inactiveColor: const Color(0xFF2D2D2D).withOpacity(0.1),
              onChanged: (v) => setState(() => brushWidth = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubToolMenu() {
    final List<Map<String, dynamic>> subTools = currentMenuType == 'Kalem'
        ? [
            {'tool': DrawingTool.kursun, 'label': 'Kursun'},
            {'tool': DrawingTool.keceli, 'label': 'Keceli'},
            {'tool': DrawingTool.boya_kalemi, 'label': 'Boya'},
          ]
        : [
            {'tool': DrawingTool.firca_classic, 'label': 'Klasik'},
            {'tool': DrawingTool.sulu_firca, 'label': 'Sulu'},
            {'tool': DrawingTool.gradyan_fircasi, 'label': 'Gradyan'},
          ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: subTools.map((st) {
        final tool = st['tool'] as DrawingTool;
        final label = st['label'] as String;
        return GestureDetector(
          onTap: () => setState(() { 
            activeTool = tool; 
            showSubToolMenu = false; 
          }),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: activeTool == tool ? const Color(0xFFFFD166) : Colors.white,
              border: Border.all(color: const Color(0xFF2D2D2D), width: 2),
            ),
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
          ),
        );
      }).toList(),
    );
  }

  Widget _toolButton(DrawingTool tool, IconData icon, String label, {bool isMenu = false}) {
    bool isSelected = (isMenu && currentMenuType == label) || (!isMenu && activeTool == tool);
    
    return GestureDetector(
      onTap: () {
        if (isMenu) {
          if (currentMenuType == label) {
            setState(() => showSubToolMenu = !showSubToolMenu);
          } else {
            setState(() {
              showSubToolMenu = true;
              currentMenuType = label;
              activeTool = tool;
            });
          }
        } else {
          setState(() {
            activeTool = tool;
            showSubToolMenu = false;
            currentMenuType = null;
          });
        }
      },
      child: Column(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFFD166) : Colors.white,
              border: Border.all(color: const Color(0xFF2D2D2D), width: 3),
              boxShadow: isSelected ? null : const [BoxShadow(color: Color(0xFF2D2D2D), offset: Offset(4, 4))],
            ),
            child: Icon(icon, color: const Color(0xFF2D2D2D)),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildPalette() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: palette.length,
        itemBuilder: (context, index) => GestureDetector(
          onTap: () => setState(() { secondaryColor = selectedColor; selectedColor = palette[index]; }),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 40,
            decoration: BoxDecoration(
              color: palette[index],
              border: Border.all(color: const Color(0xFF2D2D2D), width: selectedColor == palette[index] ? 4 : 2),
              boxShadow: selectedColor == palette[index] ? null : const [BoxShadow(color: Color(0xFF2D2D2D), offset: Offset(2, 2))],
            ),
          ),
        ),
      ),
    );
  }
}

class ColoringPainter extends CustomPainter {
  final ui.Image? template;
  final List<PaintOp> operations;
  final Color secondaryColor;

  ColoringPainter({this.template, required this.operations, required this.secondaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    
    // Draw drawing operations
    for (var op in operations) {
      op.draw(canvas, 1.0, secondaryColor);
    }

    // Draw template on top with multiply blend mode
    if (template != null) {
      final paint = Paint()..blendMode = BlendMode.multiply;
      paintImage(
        canvas: canvas,
        rect: Rect.fromLTWH(0, 0, size.width, size.height),
        image: template!,
        fit: BoxFit.contain,
        // paint: paint,
      );
    }
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
