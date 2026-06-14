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
  jel_kalem,
  komur,
  sprey,
  kuru_firca,
  yagli_boya,
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
      case DrawingTool.kursun:
        // Thin, graphite texture: low opacity, slightly sharper cap
        paint.strokeWidth = strokeWidth * 0.4;
        paint.color = color.withOpacity(finalOpacity * 0.7);
        _drawBasic(canvas, paint);
        // Add a bit of "grain"
        final rnd = math.Random(42);
        for (int i = 0; i < points.length - 1; i++) {
          if (points[i] != null && points[i + 1] != null && rnd.nextDouble() > 0.5) {
            canvas.drawCircle(points[i]!, strokeWidth * 0.2, paint..color = color.withOpacity(finalOpacity * 0.1));
          }
        }
        break;

      case DrawingTool.tukenmez:
        // Thin, consistent, high opacity
        paint.strokeWidth = strokeWidth * 0.3;
        paint.color = color.withOpacity(finalOpacity * 0.95);
        _drawBasic(canvas, paint);
        break;

      case DrawingTool.keceli:
        // Thick, marker-like: square cap, medium opacity that builds up
        paint.strokeWidth = strokeWidth * 1.2;
        paint.strokeCap = StrokeCap.square;
        paint.color = color.withOpacity(finalOpacity * 0.5);
        _drawBasic(canvas, paint);
        break;

      case DrawingTool.sulu_firca:
        // Translucent watercolor: soft blur, very low opacity, wide
        paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
        paint.color = color.withOpacity(finalOpacity * 0.15);
        paint.strokeWidth = strokeWidth * 2.5;
        _drawBasic(canvas, paint);
        // Inner core for more "wet" look
        _drawBasic(canvas, paint..strokeWidth = strokeWidth * 1.5..color = color.withOpacity(finalOpacity * 0.05));
        break;

      case DrawingTool.boya_kalemi:
        // Waxy texture: noisy lines
        final rnd = math.Random(42);
        for (int i = 0; i < points.length - 1; i++) {
          if (points[i] != null && points[i + 1] != null) {
            for (int j = 0; j < 6; j++) {
              Offset off = Offset(rnd.nextDouble() * 5 - 2.5, rnd.nextDouble() * 5 - 2.5);
              canvas.drawLine(points[i]! + off, points[i + 1]! + off, paint..color = color.withOpacity(finalOpacity * 0.5)..strokeWidth = strokeWidth * 0.3);
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
                [secondaryColor.withOpacity(finalOpacity * 0.5), color.withOpacity(finalOpacity * 0.7)],
              );
              canvas.drawLine(points[i]!, points[i+1]!, paint);
            }
          }
        }
        break;

      case DrawingTool.jel_kalem:
        // Smooth liquid: consistent line + white highlight core
        paint.strokeWidth = strokeWidth * 0.6;
        _drawBasic(canvas, paint..color = color.withOpacity(finalOpacity * 1.0));
        final highlightPaint = Paint()
          ..color = Colors.white.withOpacity(finalOpacity * 0.4)
          ..strokeWidth = strokeWidth * 0.15
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        _drawBasic(canvas, highlightPaint);
        break;

      case DrawingTool.komur:
        // Grainy, soft-edged: charcoal
        final rnd = math.Random(13);
        for (int i = 0; i < points.length - 1; i++) {
          if (points[i] != null && points[i + 1] != null) {
            for (int j = 0; j < 12; j++) {
              Offset off = Offset(rnd.nextDouble() * 8 - 4, rnd.nextDouble() * 8 - 4);
              canvas.drawCircle(points[i]! + off, rnd.nextDouble() * 3, paint..color = color.withOpacity(finalOpacity * 0.2)..style = PaintingStyle.fill);
            }
          }
        }
        break;

      case DrawingTool.sprey:
        // Particle distribution
        final rnd = math.Random();
        for (int i = 0; i < points.length; i++) {
          if (points[i] != null) {
            for (int j = 0; j < 20; j++) {
              double r = rnd.nextDouble() * strokeWidth * 2.5;
              double angle = rnd.nextDouble() * 2 * math.pi;
              Offset off = Offset(r * math.cos(angle), r * math.sin(angle));
              canvas.drawCircle(points[i]! + off, rnd.nextDouble() * 2, paint..color = color.withOpacity(finalOpacity * 0.15)..style = PaintingStyle.fill);
            }
          }
        }
        break;

      case DrawingTool.kuru_firca:
        // Scratchy and broken
        paint.strokeWidth = strokeWidth * 0.2;
        final rnd = math.Random(7);
        for (int i = 0; i < points.length - 1; i++) {
          if (points[i] != null && points[i + 1] != null) {
            for (int j = 0; j < 4; j++) {
               Offset off = Offset(rnd.nextDouble() * 4 - 2, rnd.nextDouble() * 4 - 2);
               if (rnd.nextDouble() > 0.2) {
                 canvas.drawLine(points[i]! + off, points[i+1]! + off, paint..color = color.withOpacity(finalOpacity * 0.3));
               }
            }
          }
        }
        break;

      case DrawingTool.yagli_boya:
        // Thick and opaque
        paint.strokeWidth = strokeWidth * 1.8;
        paint.strokeCap = StrokeCap.butt;
        _drawBasic(canvas, paint..color = color.withOpacity(finalOpacity * 0.9));
        // Add "impasto" texture lines
        _drawBasic(canvas, paint..strokeWidth = strokeWidth * 0.4..color = Colors.white.withOpacity(finalOpacity * 0.1));
        break;

      case DrawingTool.firca_classic:
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
  DrawingTool lastKalemTool = DrawingTool.kursun;
  DrawingTool lastFircaTool = DrawingTool.firca_classic;
  
  double brushWidth = 12.0;
  bool showSubToolMenu = false;
  String? currentMenuType;

  final TransformationController _transformationController = TransformationController();
  final List<List<PaintOp>> _undoStack = [];
  final List<List<PaintOp>> _redoStack = [];

  // Track pointers to distinguish between drawing and zoom/pan
  int _pointerCount = 0;

  final List<Color> palette = [
    const Color(0xFF2D2D2D), const Color(0xFFE94E77), const Color(0xFFFF6B6B),
    const Color(0xFFF6AD55), const Color(0xFFFFD166), const Color(0xFF06D6A0),
    const Color(0xFF118AB2), const Color(0xFF073B4C), const Color(0xFF9B59B6),
    const Color(0xFFED4C67), const Color(0xFFA3CB38), const Color(0xFFC23616),
    const Color(0xFFF8EFBA), const Color(0xFF58B19F), const Color(0xFF2C3A47),
    const Color(0xFFB33771), const Color(0xFF3B3B98), const Color(0xFFFD7272),
    const Color(0xFF9AECDB), const Color(0xFFD6A2E8), const Color(0xFF6D214F),
    const Color(0xFF182C61), const Color(0xFFFC427B), const Color(0xFFBDC581),
    const Color(0xFF82589F), const Color(0xFFEAB543), const Color(0xFF55E6C1),
    const Color(0xFFCAD3C8), const Color(0xFFF97F51), const Color(0xFF1B9CFC),
    const Color(0xFF535C68), const Color(0xFFFEA47F), const Color(0xFF25CCF7),
    const Color(0xFFE84393), const Color(0xFFE17055), const Color(0xFFD63031),
    const Color(0xFF00B894), const Color(0xFF00CEC9), const Color(0xFF0984E3),
    const Color(0xFF6C5CE7), const Color(0xFFB2BEC3), const Color(0xFF2D3436),
  ];

  @override
  void initState() {
    super.initState();
    _loadTemplate();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
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

  Offset _convertOffset(Offset localOffset) {
    return _transformationController.toScene(localOffset);
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
            child: Listener(
              onPointerDown: (_) => setState(() => _pointerCount++),
              onPointerUp: (_) => setState(() => _pointerCount--),
              onPointerCancel: (_) => setState(() => _pointerCount--),
              child: Container(
                color: Colors.white,
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 0.5,
                  maxScale: 10.0,
                  panEnabled: _pointerCount > 1,
                  scaleEnabled: _pointerCount > 1,
                  child: GestureDetector(
                    onPanStart: _pointerCount > 1 ? null : (details) {
                      _saveHistory();
                      setState(() {
                        operations.add(PathOp(
                          points: [_convertOffset(details.localPosition)],
                          tool: activeTool,
                          color: selectedColor,
                          strokeWidth: brushWidth,
                        ));
                      });
                    },
                    onPanUpdate: _pointerCount > 1 ? null : (details) {
                      setState(() {
                        if (operations.isNotEmpty && operations.last is PathOp) {
                          (operations.last as PathOp).points.add(_convertOffset(details.localPosition));
                        }
                      });
                    },
                    onPanEnd: _pointerCount > 1 ? null : (_) {
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
    final subTools = currentMenuType == 'Kalem'
        ? [
            {'tool': DrawingTool.kursun, 'label': 'Kursun'},
            {'tool': DrawingTool.tukenmez, 'label': 'Tukenmez'},
            {'tool': DrawingTool.keceli, 'label': 'Keceli'},
            {'tool': DrawingTool.jel_kalem, 'label': 'Jel'},
            {'tool': DrawingTool.komur, 'label': 'Komur'},
            {'tool': DrawingTool.boya_kalemi, 'label': 'Boya'},
          ]
        : [
            {'tool': DrawingTool.firca_classic, 'label': 'Klasik'},
            {'tool': DrawingTool.sulu_firca, 'label': 'Sulu'},
            {'tool': DrawingTool.sprey, 'label': 'Sprey'},
            {'tool': DrawingTool.yagli_boya, 'label': 'Yagli'},
            {'tool': DrawingTool.kuru_firca, 'label': 'Kuru'},
            {'tool': DrawingTool.gradyan_fircasi, 'label': 'Gradyan'},
          ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: subTools.map((st) {
          final tool = st['tool'] as DrawingTool;
          return GestureDetector(
            onTap: () => setState(() { 
              activeTool = tool; 
              if (currentMenuType == 'Kalem') {
                lastKalemTool = tool;
              } else if (currentMenuType == 'Firca') {
                lastFircaTool = tool;
              }
              showSubToolMenu = false; 
            }),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: activeTool == tool ? const Color(0xFFFFD166) : Colors.white,
                border: Border.all(color: const Color(0xFF2D2D2D), width: 2),
              ),
              child: Text(st['label'] as String, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _toolButton(DrawingTool tool, IconData icon, String label, {bool isMenu = false}) {
    bool isSelected = false;
    if (isMenu) {
      if (label == 'Kalem') {
        isSelected = activeTool == DrawingTool.kursun || 
                     activeTool == DrawingTool.tukenmez || 
                     activeTool == DrawingTool.keceli || 
                     activeTool == DrawingTool.jel_kalem || 
                     activeTool == DrawingTool.komur || 
                     activeTool == DrawingTool.boya_kalemi;
      } else if (label == 'Firca') {
        isSelected = activeTool == DrawingTool.firca_classic || 
                     activeTool == DrawingTool.sulu_firca || 
                     activeTool == DrawingTool.sprey || 
                     activeTool == DrawingTool.yagli_boya || 
                     activeTool == DrawingTool.kuru_firca || 
                     activeTool == DrawingTool.gradyan_fircasi;
      }
    } else {
      isSelected = activeTool == tool;
    }

    return GestureDetector(
      onTap: () {
        if (isMenu) {
          if (currentMenuType == label) {
            setState(() => showSubToolMenu = !showSubToolMenu);
          } else {
            setState(() {
              showSubToolMenu = true;
              currentMenuType = label;
              if (label == "Firca") {
                activeTool = lastFircaTool;
              } else if (label == "Kalem") {
                activeTool = lastKalemTool;
              }
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
    for (var op in operations) {
      op.draw(canvas, 1.0, secondaryColor);
    }

    if (template != null) {
      final paint = Paint()..blendMode = BlendMode.multiply;
      final Rect destRect = Rect.fromLTWH(0, 0, size.width, size.height);
      
      canvas.drawImageRect(
        template!,
        Rect.fromLTWH(0, 0, template!.width.toDouble(), template!.height.toDouble()),
        destRect,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
