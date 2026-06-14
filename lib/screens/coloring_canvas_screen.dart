import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

// --- Advanced Painting Engine Models from main.dart ---

enum DrawingTool {
  bucket,
  kursun,
  tukenmez,
  kaligrafi_kalem,
  keceli,
  firca_classic,
  kaligrafi_firca,
  hava_fircasi,
  yagli_firca,
  boya_kalemi,
  dogal_kalem,
  sulu_firca,
  eraser,
  eyedropper,
  selection,
  text,
  gradyan_fircasi,
}

abstract class PaintOp {
  double opacity;
  Path? maskPath;
  PaintOp({this.opacity = 1.0, this.maskPath});
  void draw(Canvas canvas, List<PathData> paths, double parentOpacity, Color secondaryColor);
}

class PathOp extends PaintOp {
  final List<Offset?> points;
  final DrawingTool tool;
  final Color color;
  final double strokeWidth;
  PathOp({
    required this.points,
    required this.tool,
    required this.color,
    required this.strokeWidth,
    double opacity = 1.0,
    Path? maskPath,
  }) : super(opacity: opacity, maskPath: maskPath);

  @override
  void draw(Canvas canvas, List<PathData> paths, double parentOpacity, Color secondaryColor) {
    final finalOpacity = opacity * parentOpacity;
    final paint = Paint()
      ..color = color.withValues(alpha: finalOpacity)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    if (tool == DrawingTool.eraser) {
      paint.blendMode = BlendMode.dstOut; // True eraser effect for layers
      paint.color = Colors.black; 
    }

    if (maskPath != null) {
      canvas.save();
      canvas.clipPath(maskPath!);
    }

    switch (tool) {
      case DrawingTool.gradyan_fircasi:
        paint.blendMode = BlendMode.plus;
        paint.strokeWidth = strokeWidth * 1.5;
        if (points.length > 1) {
          for (int i = 0; i < points.length - 1; i++) {
            if (points[i] != null && points[i+1] != null) {
              paint.shader = ui.Gradient.linear(
                points[i]!,
                points[i+1]!,
                [
                  secondaryColor.withValues(alpha: finalOpacity * 0.4), 
                  color.withValues(alpha: finalOpacity * 0.6)
                ],
              );
              canvas.drawLine(points[i]!, points[i+1]!, paint);
              canvas.drawLine(points[i]!, points[i+1]!, paint..blendMode = BlendMode.screen..strokeWidth = strokeWidth * 0.8..shader = null..color = color.withValues(alpha: finalOpacity * 0.2));
            }
          }
        }
        break;
      case DrawingTool.kaligrafi_firca:
        for (int i = 0; i < points.length - 1; i++) {
          if (points[i] != null && points[i + 1] != null) {
            double dist = (points[i]! - points[i + 1]!).distance;
            double steps = dist / 2;
            for (double t = 0; t <= 1.0; t += 1.0 / steps.clamp(1, 100)) {
              Offset pos = Offset.lerp(points[i]!, points[i + 1]!, t)!;
              double varWidth = strokeWidth * (0.5 + 0.5 * math.sin(t * math.pi));
              canvas.drawLine(pos + Offset(-varWidth, varWidth), pos + Offset(varWidth, -varWidth), paint..strokeWidth = 2);
            }
          }
        }
        break;
      case DrawingTool.kaligrafi_kalem:
        paint.strokeCap = StrokeCap.square;
        for (int i = 0; i < points.length - 1; i++) {
          if (points[i] != null && points[i + 1] != null) {
            canvas.drawLine(points[i]! + Offset(-strokeWidth/2, strokeWidth/2), points[i+1]! + Offset(strokeWidth/2, -strokeWidth/2), paint);
          }
        }
        break;
      case DrawingTool.hava_fircasi:
        paint.maskFilter = MaskFilter.blur(BlurStyle.normal, strokeWidth * 0.5);
        for (int i = 0; i < points.length - 1; i++) {
          if (points[i] != null && points[i + 1] != null) {
            canvas.drawLine(points[i]!, points[i + 1]!, paint..strokeWidth = strokeWidth * 1.2..color = color.withValues(alpha: finalOpacity * 0.4));
          }
        }
        break;
      case DrawingTool.yagli_firca:
        for (int i = 0; i < points.length - 1; i++) {
          if (points[i] != null && points[i + 1] != null) {
            for (int j = -2; j <= 2; j++) {
              Offset off = Offset(j * 1.5, j * 1.5);
              canvas.drawLine(points[i]! + off, points[i+1]! + off, paint..color = color.withValues(alpha: finalOpacity * 0.7));
            }
          }
        }
        break;
      case DrawingTool.boya_kalemi:
        final rnd = math.Random(42);
        for (int i = 0; i < points.length - 1; i++) {
          if (points[i] != null && points[i + 1] != null) {
            for (int j = 0; j < 5; j++) {
              Offset off = Offset(rnd.nextDouble() * 4 - 2, rnd.nextDouble() * 4 - 2);
              canvas.drawLine(points[i]! + off, points[i+1]! + off, paint..color = color.withValues(alpha: finalOpacity * 0.6));
            }
          }
        }
        break;
      case DrawingTool.dogal_kalem:
        paint.strokeWidth = strokeWidth * 0.5;
        for (int i = 0; i < points.length - 1; i++) {
          if (points[i] != null && points[i + 1] != null) {
            canvas.drawLine(points[i]!, points[i + 1]!, paint..color = color.withValues(alpha: finalOpacity * 0.8));
          }
        }
        break;
      case DrawingTool.sulu_firca:
        paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        paint.color = color.withValues(alpha: finalOpacity * 0.2);
        paint.strokeWidth = strokeWidth * 2.5;
        for (int i = 0; i < points.length - 1; i++) {
          if (points[i] != null && points[i + 1] != null) canvas.drawLine(points[i]!, points[i + 1]!, paint);
        }
        break;
      default:
        for (int i = 0; i < points.length - 1; i++) {
          if (points[i] != null && points[i + 1] != null) canvas.drawLine(points[i]!, points[i + 1]!, paint);
        }
    }

    if (maskPath != null) {
      canvas.restore();
    }
  }
}

class FillOp extends PaintOp {
  final int pathIndex;
  final Color color;
  FillOp({required this.pathIndex, required this.color, double opacity = 1.0}) : super(opacity: opacity);

  @override
  void draw(Canvas canvas, List<PathData> paths, double parentOpacity, Color secondaryColor) {
    if (pathIndex >= 0 && pathIndex < paths.length) {
      canvas.drawPath(paths[pathIndex].path, Paint()..color = color.withValues(alpha: opacity * parentOpacity)..style = PaintingStyle.fill);
    }
  }
}

class AppLayer {
  final String id;
  String name;
  bool isVisible;
  bool isLocked;
  double opacity;
  List<PaintOp> operations;
  ui.Image? image;
  Offset offset;
  double scale;

  AppLayer({
    required this.id,
    required this.name,
    this.isVisible = true,
    this.isLocked = false,
    this.opacity = 1.0,
    List<PaintOp>? operations,
    this.image,
    this.offset = Offset.zero,
    this.scale = 1.0,
  }) : operations = operations ?? [];
}

class PathData {
  final Path path;
  final String label;
  PathData({required this.path, required this.label});
}

// --- Main Screen Widget ---

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
  // Theme Constants (Neubrutalism)
  static const Color bgColor = Color(0xFFFDFBF7);
  static const Color borderColor = Color(0xFF2D2D2D);
  static const double borderSize = 4.0;
  static const Offset shadowOffset = Offset(4, 4);

  // State
  List<AppLayer> layers = [];
  int activeLayerIndex = 0;
  Color selectedColor = const Color(0xFFF94144);
  Color secondaryColor = const Color(0xFFF3722C);
  DrawingTool activeTool = DrawingTool.kursun;
  double brushWidth = 12.0;
  List<PathData>? templatePaths;
  Size? canvasSize;

  // History
  final List<List<PaintOp>> _undoStack = [];
  final List<List<PaintOp>> _redoStack = [];

  // Expanded Retro-Premium Palette
  final List<Color> palette = [
    // Retro Corporate / Win95
    const Color(0xFF008080), const Color(0xFFC0C0C0), const Color(0xFF808080), const Color(0xFF000080),
    // Neubrutalism Primaries
    const Color(0xFFF94144), const Color(0xFFF3722C), const Color(0xFFF8961E), const Color(0xFFF9C74F),
    const Color(0xFF90BE6D), const Color(0xFF43AA8B), const Color(0xFF577590), const Color(0xFF2D2D2D),
    // Pastels
    const Color(0xFFFFB3BA), const Color(0xFFFFDFBA), const Color(0xFFFFFFBA), const Color(0xFFBAFFC9),
    const Color(0xFFBAE1FF), const Color(0xFFD4A5A5), const Color(0xFFE2E2E2), const Color(0xFFFDFBF7),
    // Earthy
    const Color(0xFF6B705C), const Color(0xFFA5A58D), const Color(0xFFB7B7A4), const Color(0xFFFFE8D6),
    const Color(0xFFDDBEA9), const Color(0xFFCB997E), const Color(0xFF6D6875), const Color(0xFFB5838D),
    // Neon
    const Color(0xFF39FF14), const Color(0xFFCCFF00), const Color(0xFFFF007F), const Color(0xFF00FFFF),
    const Color(0xFFBF00FF), const Color(0xFFFFEF00), const Color(0xFFFF5F1F), const Color(0xFF00FFEF),
  ];

  @override
  void initState() {
    super.initState();
    _initCanvas();
  }

  void _initCanvas() {
    layers = [
      AppLayer(id: 'bg', name: 'Zemin'),
      AppLayer(id: 'paint', name: 'Boyama'),
    ];
    activeLayerIndex = 1;
    _undoStack.clear();
    _redoStack.clear();
  }

  void _saveHistory() {
    final currentOps = List<PaintOp>.from(layers[activeLayerIndex].operations);
    _undoStack.add(currentOps);
    _redoStack.clear();
    if (_undoStack.length > 30) _undoStack.removeAt(0);
  }

  void _undo() {
    if (_undoStack.isNotEmpty) {
      setState(() {
        _redoStack.add(List<PaintOp>.from(layers[activeLayerIndex].operations));
        layers[activeLayerIndex].operations = _undoStack.removeLast();
      });
    }
  }

  void _redo() {
    if (_redoStack.isNotEmpty) {
      setState(() {
        _undoStack.add(List<PaintOp>.from(layers[activeLayerIndex].operations));
        layers[activeLayerIndex].operations = _redoStack.removeLast();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        leading: _retroNavButton(context),
        title: Text(
          'BOYAMA TUVAL0',
          style: TextStyle(
            color: borderColor,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            fontFamily: 'MS Sans Serif',
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          _appBarButton(Icons.undo, _undo, \"Geri\"),
          _appBarButton(Icons.redo, _redo, \"0leri\"),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(color: borderColor, height: 4),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(builder: (context, constraints) {
              canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
              return Center(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: borderColor, width: borderSize),
                    boxShadow: const [
                      BoxShadow(color: borderColor, offset: shadowOffset, blurRadius: 0),
                    ],
                  ),
                  child: Listener(
                    onPointerDown: (e) {
                      final layer = layers[activeLayerIndex];
                      if (layer.isLocked) return;
                      _saveHistory();
                      setState(() {
                        layer.operations.add(PathOp(
                          points: [e.localPosition],
                          tool: activeTool,
                          color: selectedColor,
                          strokeWidth: brushWidth,
                        ));
                      });
                    },
                    onPointerMove: (e) {
                      final layer = layers[activeLayerIndex];
                      if (layer.isLocked || layer.operations.isEmpty) return;
                      if (layer.operations.last is PathOp) {
                        setState(() {
                          (layer.operations.last as PathOp).points.add(e.localPosition);
                        });
                      }
                    },
                    onPointerUp: (e) {
                      final layer = layers[activeLayerIndex];
                      if (layer.operations.isNotEmpty && layer.operations.last is PathOp) {
                        setState(() { (layer.operations.last as PathOp).points.add(null); });
                      }
                    },
                    child: CustomPaint(
                      painter: MasterCanvasPainter(layers: layers, secondaryColor: secondaryColor),
                      size: Size.infinite,
                    ),
                  ),
                ),
              );
            }),
          ),
          _buildToolBar(),
        ],
      ),
    );
  }

  Widget _buildToolBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: borderColor, width: borderSize)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        children: [
          // Tool Selectors
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _toolBtn(DrawingTool.kursun, Icons.edit, \"Kalem\"),
              _toolBtn(DrawingTool.firca_classic, Icons.brush, \"F1ra\"),
              _toolBtn(DrawingTool.yagli_firca, Icons.format_paint, \"Ya l1\"),
              _toolBtn(DrawingTool.sulu_firca, Icons.water_drop, \"Sulu\"),
              _toolBtn(DrawingTool.eraser, Icons.auto_fix_normal, \"Silgi\"),
            ],
          ),
          const SizedBox(height: 16),
          // Color Palette
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: palette.length,
              itemBuilder: (context, index) {
                final color = palette[index];
                bool isSel = selectedColor == color;
                return GestureDetector(
                  onTap: () => setState(() { secondaryColor = selectedColor; selectedColor = color; }),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    width: 44,
                    decoration: BoxDecoration(
                      color: color,
                      border: Border.all(color: borderColor, width: isSel ? 4 : 2),
                      boxShadow: isSel ? [const BoxShadow(color: borderColor, offset: Offset(2, 2))] : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolBtn(DrawingTool tool, IconData icon, String label) {
    bool isSel = activeTool == tool;
    return GestureDetector(
      onTap: () => setState(() => activeTool = tool),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFFF9C74F) : Colors.white,
          border: Border.all(color: borderColor, width: 2),
          boxShadow: isSel ? null : [const BoxShadow(color: borderColor, offset: Offset(2, 2))],
        ),
        child: Column(
          children: [
            Icon(icon, color: borderColor, size: 24),
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'MS Sans Serif')),
          ],
        ),
      ),
    );
  }

  Widget _retroNavButton(BuildContext context) {
    return IconButton(
      icon: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: borderColor, width: 2),
          boxShadow: const [BoxShadow(color: borderColor, offset: Offset(2, 2))],
        ),
        child: const Icon(Icons.arrow_back, color: borderColor, size: 20),
      ),
      onPressed: () => Navigator.pop(context),
    );
  }

  Widget _appBarButton(IconData icon, VoidCallback onTap, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: borderColor, width: 2),
            boxShadow: const [BoxShadow(color: borderColor, offset: Offset(2, 2))],
          ),
          child: Icon(icon, color: borderColor, size: 20),
        ),
      ),
    );
  }
}

class MasterCanvasPainter extends CustomPainter {
  final List<AppLayer> layers;
  final Color secondaryColor;
  MasterCanvasPainter({required this.layers, required this.secondaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    for (var layer in layers) {
      if (!layer.isVisible) continue;
      canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = Colors.white.withValues(alpha: layer.opacity));
      for (var op in layer.operations) {
        op.draw(canvas, [], 1.0, secondaryColor);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant MasterCanvasPainter oldDelegate) => true;
}
