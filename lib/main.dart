import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:color_world/screens/category_screen.dart';

void main() {
  runApp(const ColorWorldApp());
}

class ColorWorldApp extends StatelessWidget {
  const ColorWorldApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Color World',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00D1FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'MS Sans Serif',
      ),
      home: CategoryScreen(),
    );
  }
}

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
      paint.blendMode = BlendMode.srcOver;
      paint.color = Colors.white; 
    }

    if (maskPath != null) {
      canvas.save();
      canvas.clipPath(maskPath!);
    }

    switch (tool) {
      case DrawingTool.gradyan_fircasi:
        // WET-PAINT MIXING EFFECT: Blend current color with secondary (previous) color
        // Using BlendMode.plus for additive color mixing feel or Overlay for high-contrast blending.
        // We use a low opacity linear gradient per segment to create a \"trailing\" mix effect.
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
              // Adding a second pass with different blend for \"wetness\"
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
  bool hasSolidBackground;
  bool isTemplate;
  List<PaintOp> operations;
  ui.Image? image;
  Offset offset;
  double scale;

  bool isTextLayer;
  String? text;
  Color? textColor;
  double fontSize;
  String fontFamily;
  TextAlign textAlign;
  bool isBold;
  bool isItalic;

  AppLayer({
    required this.id,
    required this.name,
    this.isVisible = true,
    this.isLocked = false,
    this.opacity = 1.0,
    this.hasSolidBackground = false,
    this.isTemplate = false,
    List<PaintOp>? operations,
    this.image,
    this.offset = Offset.zero,
    this.scale = 1.0,
    this.isTextLayer = false,
    this.text,
    this.textColor,
    this.fontSize = 24.0,
    this.fontFamily = 'Arial',
    this.textAlign = TextAlign.left,
    this.isBold = false,
    this.isItalic = false,
  }) : operations = operations ?? [];

  Rect getBounds(Size canvasSize) {
    if (image != null) {
      return Rect.fromLTWH(offset.dx, offset.dy, image!.width * scale, image!.height * scale);
    }
    if (isTextLayer && text != null) {
      final tp = _getTextPainter();
      return Rect.fromLTWH(offset.dx, offset.dy, tp.width, tp.height);
    }
    return Rect.fromLTWH(offset.dx, offset.dy, canvasSize.width, canvasSize.height);
  }

  TextPainter _getTextPainter() {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: (textColor ?? Colors.white).withValues(alpha: opacity),
          fontSize: fontSize,
          fontFamily: fontFamily,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
        ),
      ),
      textAlign: textAlign,
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    return tp;
  }
}

class PathData {
  final Path path;
  final String label;
  PathData({required this.path, required this.label});
}

class ColoringCanvasPage extends StatefulWidget {
  const ColoringCanvasPage({super.key});
  @override
  State<ColoringCanvasPage> createState() => _ColoringCanvasPageState();
}

class _ColoringCanvasPageState extends State<ColoringCanvasPage> {
  List<AppLayer> layers = [];
  int activeLayerIndex = 0;
  Color selectedColor = Colors.red;
  Color secondaryColor = Colors.orange; // Acts as previousColor for mixing
  Color canvasBackgroundColor = const Color(0xFFFDFBF7);
  bool isTransparentBackground = false;
  DrawingTool activeTool = DrawingTool.kursun;
  DrawingTool? lastDrawingTool;
  List<PathData>? templatePaths;
  Offset? currentCursorPos;
  double brushWidth = 12.0;
  double brushOpacity = 1.0;
  bool isPenMenuOpen = false;
  bool isBrushMenuOpen = false;
  bool isTextMenuOpen = false;
  bool keepInsideLines = false;
  Size? canvasSize;
  Path? activeMaskPath;
  int? draggingHandle;

  // History system
  final List<List<PaintOp>> _undoStack = [];
  final List<List<PaintOp>> _redoStack = [];

  final List<Color> palette = [
    Colors.white, Colors.black, Colors.grey, Colors.brown,
    Colors.red, Colors.deepOrange, Colors.orange, Colors.amber,
    Colors.yellow, Colors.lime, Colors.lightGreen, Colors.green,
    Colors.teal, Colors.cyan, Colors.lightBlue, Colors.blue,
    Colors.indigo, Colors.purple, Colors.deepPurple, Colors.pink,
    const Color(0xFFFF9EB5), const Color(0xFF6DA9E4), const Color(0xFFFDFBF7), const Color(0xFFD4D0C8),
  ];

  final List<String> fonts = ['Arial', 'Arial Narrow', 'Arial Black', 'Courier New', 'Times New Roman', 'Georgia'];

  @override
  void initState() {
    super.initState();
    _initTemplate();
  }

  void _initTemplate() {
    layers = [
      AppLayer(id: 'tpl', name: 'Şablon Katman', isTemplate: true),
      AppLayer(id: 'bg', name: 'Arka Plan', hasSolidBackground: true),
    ];
    activeLayerIndex = 1;
    activeMaskPath = null;
    lastDrawingTool = DrawingTool.kursun;
    _undoStack.clear();
    _redoStack.clear();
  }

  void _saveHistory() {
    final currentOps = List<PaintOp>.from(layers[activeLayerIndex].operations);
    _undoStack.add(currentOps);
    _redoStack.clear();
    if (_undoStack.length > 50) _undoStack.removeAt(0);
  }

  void _undo() {
    if (_undoStack.isNotEmpty) {
      setState(() {
        final currentOps = List<PaintOp>.from(layers[activeLayerIndex].operations);
        _redoStack.add(currentOps);
        layers[activeLayerIndex].operations = _undoStack.removeLast();
      });
    }
  }

  void _redo() {
    if (_redoStack.isNotEmpty) {
      setState(() {
        final currentOps = List<PaintOp>.from(layers[activeLayerIndex].operations);
        _undoStack.add(currentOps);
        layers[activeLayerIndex].operations = _redoStack.removeLast();
      });
    }
  }

  void _openTextDialog(Offset position) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text(\"Yazı Ekle\", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: \"Buraya yazın...\", hintStyle: TextStyle(color: Colors.white24)),
          onSubmitted: (val) {
            if (val.isNotEmpty) {
              _submitText(val, position);
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text(\"İptal\")),
          TextButton(onPressed: () {
            if (controller.text.isNotEmpty) {
              _submitText(controller.text, position);
            }
            Navigator.pop(context);
          }, child: const Text(\"Ekle\")),
        ],
      ),
    );
  }

  void _submitText(String text, Offset position) {
    setState(() {
      layers.insert(0, AppLayer(
        id: DateTime.now().toString(),
        name: \"Metin: \$text\",
        isTextLayer: true,
        text: text,
        textColor: selectedColor,
        fontSize: brushWidth * 2,
        offset: position,
      ));
      activeLayerIndex = 0;
      activeTool = DrawingTool.kursun; 
      activeMaskPath = null;
    });
  }

  void _addLayer() { setState(() { layers.insert(0, AppLayer(id: DateTime.now().toString(), name: 'Katman \${layers.length}')); activeLayerIndex = 0; activeMaskPath = null; }); }
  void _removeLayer(int index) { 
    if (layers.length > 1) { 
      setState(() { 
        layers.removeAt(index); 
        activeLayerIndex = 0; 
        activeMaskPath = null; 
      }); 
    } 
  }
  
  void _reorderLayer(int oldI, int newI) { 
    if (newI >= 0 && newI < layers.length) {
      setState(() { 
        final item = layers.removeAt(oldI); 
        layers.insert(newI, item); 
        activeLayerIndex = newI; 
      }); 
    }
  }

  void _updateCursor(Offset pos) { setState(() { currentCursorPos = pos; }); }

  List<PathData> getApplePaths(Size size) {
    double side = size.shortestSide * 0.8;
    double centerX = size.width / 2;
    double centerY = size.height / 2;
    return [
      PathData(label: 'Apple Left', path: Path()..moveTo(centerX, centerY - side * 0.25)..cubicTo(centerX - side * 0.45, centerY - side * 0.25, centerX - side * 0.65, centerY - side * 0.1, centerX - side * 0.65, centerY + side * 0.1)..cubicTo(centerX - side * 0.65, centerY + side * 0.3, centerX - side * 0.3, centerY + side * 0.5, centerX, centerY + side * 0.5)..lineTo(centerX, centerY - side * 0.25)..close()),
      PathData(label: 'Apple Right', path: Path()..moveTo(centerX, centerY - side * 0.25)..lineTo(centerX, centerY + side * 0.5)..cubicTo(centerX + side * 0.3, centerY + side * 0.5, centerX + side * 0.65, centerY + side * 0.3, centerX + side * 0.65, centerY + side * 0.1)..cubicTo(centerX + side * 0.65, centerY - side * 0.1, centerX + side * 0.45, centerY - side * 0.25, centerX, centerY - side * 0.25)..close()),
      PathData(label: 'Leaf', path: Path()..moveTo(centerX, centerY - side * 0.25)..quadraticBezierTo(centerX + side * 0.15, centerY - side * 0.45, centerX + side * 0.35, centerY - side * 0.45)..quadraticBezierTo(centerX + side * 0.15, centerY - side * 0.3, centerX, centerY - side * 0.25)..close()),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final activeLayer = layers[activeLayerIndex];
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF252525), 
        title: const Text('Boyama Dünyası v4.18', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)), 
        elevation: 0, 
        iconTheme: const IconThemeData(color: Colors.white), 
        actions: [
          IconButton(icon: const Icon(Icons.undo, color: Colors.white), onPressed: _undo, tooltip: \"Geri Al\"),
          IconButton(icon: const Icon(Icons.redo, color: Colors.white), onPressed: _redo, tooltip: \"İleri Al\"),
          const VerticalDivider(color: Colors.white24, indent: 12, endIndent: 12),
          if (activeMaskPath != null) IconButton(icon: const Icon(Icons.deselect, color: Colors.orangeAccent), onPressed: () => setState(() => activeMaskPath = null), tooltip: \"Selectımı Kald1r\"),
          IconButton(icon: Icon(isTransparentBackground ? Icons.grid_4x4 : Icons.square, color: Colors.white), onPressed: () => setState(() => isTransparentBackground = !isTransparentBackground), tooltip: \"Şeffaf Arka Plan\"),
          IconButton(icon: Icon(keepInsideLines ? Icons.verified_user : Icons.verified_user_outlined, color: keepInsideLines ? Colors.lightBlueAccent : Colors.white), onPressed: () => setState(() => keepInsideLines = !keepInsideLines), tooltip: \"Sınırları Koru\"),
          IconButton(icon: Icon(layers[activeLayerIndex].isLocked ? Icons.lock : Icons.lock_open, size: 20, color: Colors.white70), onPressed: () { setState(() { layers[activeLayerIndex].isLocked = !layers[activeLayerIndex].isLocked; }); }, tooltip: \"Katmanı Kilitle\"),
          IconButton(icon: const Icon(Icons.layers, color: Colors.white), onPressed: _showLayerManager),
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: () => setState(() { _initTemplate(); canvasBackgroundColor = const Color(0xFFFDFBF7); }))
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: Colors.black, height: 1)),
      ),
      body: Row(children: [
        Container(
          width: 80, 
          decoration: const BoxDecoration(
            color: Color(0xFF252525),
            border: Border(right: BorderSide(color: Colors.black, width: 1))
          ), 
          child: Column(children: [
            const SizedBox(height: 20), 
            _vSliderBadge(\"Boyut\"),
            Expanded(child: RotatedBox(quarterTurns: 3, child: Slider(value: (activeLayer.isTextLayer ? activeLayer.fontSize : brushWidth).clamp(1.0, 500.0), min: 1, max: 500, activeColor: Colors.lightBlueAccent, inactiveColor: Colors.black, onChanged: (v) => setState(() { if (activeLayer.isTextLayer) activeLayer.fontSize = v; else brushWidth = v; })))),
            const SizedBox(height: 10), 
            _vSliderBadge(\"Opak\"),
            Expanded(child: RotatedBox(quarterTurns: 3, child: Slider(value: activeLayer.opacity.clamp(0.0, 1.0), min: 0, max: 1, activeColor: Colors.lightBlueAccent, inactiveColor: Colors.black, onChanged: activeLayer.isLocked ? null : (v) => setState(() => activeLayer.opacity = v)))),
            const SizedBox(height: 10), 
            _vSliderBadge(\"lçek\"),
            Expanded(child: RotatedBox(quarterTurns: 3, child: Slider(value: math.log(activeLayer.scale.clamp(0.05, 5.0)), min: math.log(0.05), max: math.log(5.0), activeColor: activeLayer.isLocked ? Colors.grey : Colors.orangeAccent, inactiveColor: Colors.black, onChanged: activeLayer.isLocked ? null : (v) => setState(() => activeLayer.scale = math.exp(v))))),
            const SizedBox(height: 20)
          ])),
        Expanded(child: LayoutBuilder(builder: (context, constraints) {
          canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
          templatePaths ??= getApplePaths(canvasSize!);
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFF121212),
              image: DecorationImage(
                image: NetworkImage(\"https://www.transparenttextures.com/patterns/carbon-fibre.png\"),
                repeat: ImageRepeat.repeat,
                opacity: 0.05,
              ),
            ),
            child: Center(
              child: Container(
                width: canvasSize!.width,
                height: canvasSize!.height,
                decoration: const BoxDecoration(
                  boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 40, spreadRadius: 2)],
                ),
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerHover: (e) => _updateCursor(e.localPosition),
                  onPointerDown: (e) {
                    _updateCursor(e.localPosition);
                    final layer = layers[activeLayerIndex];
                    if (layer.isLocked) return;

                    Offset localPoint = (e.localPosition - layer.offset) / layer.scale;

                    if (activeTool == DrawingTool.selection) {
                      final bounds = layer.getBounds(canvasSize!);
                      const hSize = 10.0;
                      if (Rect.fromCenter(center: bounds.topLeft, width: hSize * 2, height: hSize * 2).contains(e.localPosition)) draggingHandle = 0;
                      else if (Rect.fromCenter(center: bounds.topRight, width: hSize * 2, height: hSize * 2).contains(e.localPosition)) draggingHandle = 1;
                      else if (Rect.fromCenter(center: bounds.bottomLeft, width: hSize * 2, height: hSize * 2).contains(e.localPosition)) draggingHandle = 2;
                      else if (Rect.fromCenter(center: bounds.bottomRight, width: hSize * 2, height: hSize * 2).contains(e.localPosition)) draggingHandle = 3;
                      else if (bounds.contains(e.localPosition)) draggingHandle = 4;
                      else draggingHandle = null;
                      return;
                    }
                    if (activeTool == DrawingTool.text) {
                      _openTextDialog(e.localPosition);
                      return;
                    }
                    if (activeTool == DrawingTool.bucket) {
                      _saveHistory();
                      bool filled = false;
                      for (int i = 0; i < templatePaths!.length; i++) { 
                        if (templatePaths![i].path.contains(localPoint)) { 
                          setState(() { layer.operations.add(FillOp(pathIndex: i, color: selectedColor, opacity: layer.opacity)); }); 
                          filled = true; break; 
                        } 
                      }
                      if (!filled) setState(() { canvasBackgroundColor = selectedColor; });
                    } else if (activeTool != DrawingTool.eyedropper) {
                      _saveHistory();
                      activeMaskPath = null;
                      if (keepInsideLines && templatePaths != null) {
                        for (var pData in templatePaths!) { if (pData.path.contains(localPoint)) { activeMaskPath = pData.path; break; } }
                      }
                      setState(() { layer.operations.add(PathOp(points: [localPoint], tool: activeTool, color: selectedColor, strokeWidth: brushWidth / layer.scale, opacity: brushOpacity, maskPath: activeMaskPath)); });
                    }
                  },
                  onPointerMove: (e) {
                    _updateCursor(e.localPosition);
                    final layer = layers[activeLayerIndex];
                    if (layer.isLocked) return;
                    
                    if (activeTool == DrawingTool.selection && draggingHandle != null) {
                      setState(() {
                        if (draggingHandle == 4) {
                          layer.offset += e.delta;
                        } else if (layer.isTextLayer) {
                          final bounds = layer.getBounds(canvasSize!);
                          double oldW = bounds.width;
                          double newW = oldW;
                          if (draggingHandle == 1 || draggingHandle == 3) newW = (e.localPosition.dx - bounds.left).clamp(10.0, 1000.0);
                          else if (draggingHandle == 0 || draggingHandle == 2) {
                            newW = (bounds.right - e.localPosition.dx).clamp(10.0, 1000.0);
                            layer.offset = Offset(bounds.right - newW, layer.offset.dy);
                          }
                          layer.fontSize = (layer.fontSize * (newW / oldW)).clamp(4.0, 500.0);
                        } else {
                          layer.scale = (layer.scale + e.delta.dx / 100).clamp(0.05, 5.0);
                        }
                      });
                    } else if (activeTool != DrawingTool.eyedropper && activeTool != DrawingTool.bucket && activeTool != DrawingTool.text) {
                      if (layer.operations.isNotEmpty && layer.operations.last is PathOp) {
                        Offset localPoint = (e.localPosition - layer.offset) / layer.scale;
                        setState(() { (layer.operations.last as PathOp).points.add(localPoint); });
                      }
                    }
                  },
                  onPointerUp: (e) {
                    final layer = layers[activeLayerIndex];
                    if (layer.operations.isNotEmpty && layer.operations.last is PathOp) {
                      setState(() { (layer.operations.last as PathOp).points.add(null); activeMaskPath = null; });
                    }
                    if (activeTool == DrawingTool.selection) {
                      setState(() => activeTool = DrawingTool.kursun);
                    }
                    draggingHandle = null;
                  },
                  child: Stack(children: [
                    CustomPaint(painter: ColoringPainter(paths: templatePaths!, layers: layers, bgColor: canvasBackgroundColor, isTransparent: isTransparentBackground, activeLayerIndex: activeLayerIndex, isSelectionActive: activeTool == DrawingTool.selection, secondaryColor: secondaryColor), size: Size.infinite),
                    if (currentCursorPos != null) Positioned(left: currentCursorPos!.dx - brushWidth / 2, top: currentCursorPos!.dy - brushWidth / 2, child: IgnorePointer(child: _buildCustomCursor())),
                  ]),
                ),
              ),
            ),
          );
        })),
      ]),
      bottomNavigationBar: _buildBottomToolbar(),
    );
  }

  Widget _vSliderBadge(String text) => Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), margin: const EdgeInsets.only(top: 2, bottom: 4), decoration: BoxDecoration(color: const Color(0xFF121212), border: Border.all(color: Colors.white12), borderRadius: BorderRadius.circular(4)), child: Text(text, style: const TextStyle(fontSize: 9, color: Colors.white)));

  Widget _buildBottomToolbar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 24), 
      decoration: const BoxDecoration(color: Color(0xFF252525), border: Border(top: BorderSide(color: Colors.black, width: 1))), 
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _mainTool(DrawingTool.selection, Icons.ads_click, \"Selectım\"),
          _mainTool(DrawingTool.bucket, Icons.format_paint, \"Doldur\"),
          _toolCategoryButton(\"Kalemler\", Icons.edit, () => setState(() { isPenMenuOpen = !isPenMenuOpen; isBrushMenuOpen = false; isTextMenuOpen = false; })),
          _toolCategoryButton(\"Fırçalar\", Icons.brush, () => setState(() { isBrushMenuOpen = !isBrushMenuOpen; isPenMenuOpen = false; isTextMenuOpen = false; })),
          _toolCategoryButton(\"Metin\", Icons.text_fields, () => setState(() { isTextMenuOpen = !isTextMenuOpen; isBrushMenuOpen = false; isPenMenuOpen = false; })),
          _mainTool(DrawingTool.eraser, Icons.delete_outline, \"Silgi\"),
        ]),
        const SizedBox(height: 16),
        if (isPenMenuOpen) _buildSelectlectionOverlay(\"Kalemler\", [
          _toolOption(DrawingTool.kursun, \"Kurşun Kalem\"),
          _toolOption(DrawingTool.tukenmez, \"Tükenmez Kalem\"),
          _toolOption(DrawingTool.kaligrafi_kalem, \"Kaligrafi Kalemi\"),
          _toolOption(DrawingTool.keceli, \"Keçeli Kalem\"),
          _toolOption(DrawingTool.boya_kalemi, \"Boya Kalemi\"),
          _toolOption(DrawingTool.dogal_kalem, \"Doğal Kalem\"),
          _toolOption(DrawingTool.eyedropper, \"Renk Selectici\"),
        ]),
        if (isBrushMenuOpen) _buildSelectlectionOverlay(\"Fırçalar\", [
          _toolOption(DrawingTool.firca_classic, \"Fırça (Classic)\"),
          _toolOption(DrawingTool.gradyan_fircasi, \"Gradyan Fırçası\"),
          _toolOption(DrawingTool.kaligrafi_firca, \"Kaligrafi Fırçası\"),
          _toolOption(DrawingTool.hava_fircasi, \"Hava Fırçası\"),
          _toolOption(DrawingTool.yagli_firca, \"Yağlı Boya Fırçası\"),
          _toolOption(DrawingTool.sulu_firca, \"Sulu Boya Fırçası\"),
        ]),
        if (isTextMenuOpen) _buildTextSelectttingsOverlay(),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: SizedBox(height: 52, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: palette.length, itemBuilder: (c, i) => GestureDetector(onTap: () => setState(() { secondaryColor = selectedColor; selectedColor = palette[i]; if (layers[activeLayerIndex].isTextLayer) layers[activeLayerIndex].textColor = palette[i]; }), child: Container(margin: const EdgeInsets.symmetric(horizontal: 4), width: 44, height: 44, decoration: BoxDecoration(color: palette[i], shape: BoxShape.circle, border: Border.all(color: selectedColor == palette[i] ? Colors.white : Colors.black12, width: selectedColor == palette[i] ? 3 : 1))))))),
          _retroButton(Icons.colorize, \"Renk\", () => _openRetroColorDialog(false)),
        ]),
      ]));
  }

  void _openRetroColorDialog(bool forSelectcondary) {
    showDialog(context: context, builder: (context) => RetroColorDialog(initialColor: forSelectcondary ? secondaryColor : selectedColor)).then((color) { if (color != null) setState(() { if (forSelectcondary) secondaryColor = color; else { secondaryColor = selectedColor; selectedColor = color; } }); });
  }

  Widget _buildTextSelectttingsOverlay() {
    final layer = layers[activeLayerIndex];
    return Container(margin: const EdgeInsets.symmetric(horizontal: 10), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF121212), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.text_fields, color: Colors.lightBlue, size: 18), const SizedBox(width: 8),
        const Text(\"Metin Ayarları\", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const Spacer(),
        _toolCategoryButton(\"Metin Ekle\", Icons.add, () => _openTextDialog(Offset(canvasSize!.width / 2, canvasSize!.height / 2))),
        IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 18), onPressed: () => setState(() { isTextMenuOpen = false; })),
      ]),
      const Divider(color: Colors.white10),
      if (layer.isTextLayer) ...[
        Row(children: [
          Expanded(child: DropdownButton<String>(
            value: layer.fontFamily, dropdownColor: const Color(0xFF252525), isExpanded: true, style: const TextStyle(color: Colors.white, fontSize: 12),
            items: fonts.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
            onChanged: (v) => setState(() => layer.fontFamily = v!),
          )),
          const SizedBox(width: 12),
          _toggleBtn(Icons.format_bold, layer.isBold, () => setState(() => layer.isBold = !layer.isBold)),
          _toggleBtn(Icons.format_italic, layer.isItalic, () => setState(() => layer.isItalic = !layer.isItalic)),
        ]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _alignBtn(Icons.format_align_left, layer.textAlign == TextAlign.left, () => setState(() => layer.textAlign = TextAlign.left)),
          _alignBtn(Icons.format_align_center, layer.textAlign == TextAlign.center, () => setState(() => layer.textAlign = TextAlign.center)),
          _alignBtn(Icons.format_align_right, layer.textAlign == TextAlign.right, () => setState(() => layer.textAlign = TextAlign.right)),
        ]),
      ] else const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text(\"Düzenlemek için bir metin katmanı seçin.\", style: TextStyle(color: Colors.white38, fontSize: 10))),
    ]));
  }

  Widget _toggleBtn(IconData icon, bool active, VoidCallback onTap) => IconButton(icon: Icon(icon, color: active ? Colors.lightBlue : Colors.white70, size: 20), onPressed: onTap);
  Widget _alignBtn(IconData icon, bool active, VoidCallback onTap) => GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: active ? Colors.lightBlue.withValues(alpha: 0.2) : Colors.transparent, borderRadius: BorderRadius.circular(4)), child: Icon(icon, color: active ? Colors.lightBlue : Colors.white70, size: 20)));

  Widget _buildSelectlectionOverlay(String title, List<Widget> options) => Container(margin: const EdgeInsets.symmetric(horizontal: 10), decoration: BoxDecoration(color: const Color(0xFF121212), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white12)), child: Column(children: [Padding(padding: const EdgeInsets.all(12), child: Row(children: [Container(width: 4, height: 20, color: Colors.lightBlue), const SizedBox(width: 8), Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), const Spacer(), IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 18), onPressed: () => setState(() { isPenMenuOpen = false; isBrushMenuOpen = false; }))])), ...options, const SizedBox(height: 8)]));
  Widget _toolOption(DrawingTool tool, String name) {
    bool sel = activeTool == tool;
    return InkWell(onTap: () => setState(() { activeTool = tool; lastDrawingTool = tool; isPenMenuOpen = false; isBrushMenuOpen = false; }), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: sel ? Colors.white.withValues(alpha: 0.05) : Colors.transparent), child: Row(children: [Text(name, style: TextStyle(color: sel ? Colors.white : Colors.grey[400], fontSize: 14)), const Spacer(), SizedBox(width: 80, height: 20, child: CustomPaint(painter: StrokePreviewPainter(tool: tool, color: Colors.white)))])));
  }

  Widget _toolCategoryButton(String label, IconData icon, VoidCallback onTap) => GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF333333), border: Border.all(color: Colors.white12), borderRadius: BorderRadius.circular(4)), child: Column(children: [Icon(icon, size: 28, color: Colors.white), Text(label, style: const TextStyle(fontSize: 10, color: Colors.white))])));

  void _showLayerManager() {
    showModalBottomSheet(context: context, backgroundColor: const Color(0xFF252525), isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (context) => StatefulBuilder(builder: (context, setModalState) => Container(height: MediaQuery.of(context).size.height * 0.7, padding: const EdgeInsets.all(16), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text(\"KATMAN YÖNETİCİSİ\", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)), _retroButton(Icons.add, \"Yeni Katman\", () { _addLayer(); setModalState(() {}); })]), const Divider(color: Colors.white12), Expanded(child: ListView.builder(itemCount: layers.length, itemBuilder: (context, i) => Container(margin: const EdgeInsets.symmetric(vertical: 4), padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: activeLayerIndex == i ? const Color(0xFF333333) : Colors.transparent, border: Border.all(color: activeLayerIndex == i ? Colors.lightBlueAccent : Colors.white12), borderRadius: BorderRadius.circular(8)), child: Column(children: [Row(children: [ClipRRect(borderRadius: BorderRadius.circular(4), child: Container(width: 40, height: 40, color: Colors.white12, child: CustomPaint(painter: MiniLayerPainter(layer: layers[i], paths: templatePaths ?? [], secondaryColor: secondaryColor)))), const SizedBox(width: 12), Expanded(child: Text(layers[i].name, style: const TextStyle(color: Colors.white))), 
    if (i > 0) IconButton(icon: const Icon(Icons.keyboard_arrow_up, color: Colors.orangeAccent, size: 20), onPressed: () { _reorderLayer(i, i - 1); setModalState(() {}); }),
    if (i < layers.length - 1) IconButton(icon: const Icon(Icons.keyboard_arrow_down, color: Colors.orangeAccent, size: 20), onPressed: () { _reorderLayer(i, i + 1); setModalState(() {}); }),
    IconButton(icon: Icon(layers[i].isVisible ? Icons.visibility : Icons.visibility_off, size: 20, color: Colors.white70), onPressed: () { setState(() { layers[i].isVisible = !layers[i].isVisible; }); setModalState(() {}); }), IconButton(icon: Icon(layers[i].isLocked ? Icons.lock : Icons.lock_open, size: 20, color: Colors.white70), onPressed: () { setState(() { layers[i].isLocked = !layers[i].isLocked; }); setModalState(() {}); }), IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent), onPressed: () { _removeLayer(i); setModalState(() {}); })]), Row(children: [const Text(\"Saydamlık:\", style: TextStyle(fontSize: 10, color: Colors.white70)), Expanded(child: Slider(value: layers[i].opacity.clamp(0.0, 1.0), min: 0, max: 1, activeColor: Colors.lightBlueAccent, inactiveColor: Colors.black, onChanged: layers[i].isLocked ? null : (v) { setState(() { layers[i].opacity = v; }); setModalState(() {}); })), _retroButton(null, \"Select\", () { setState(() { activeLayerIndex = i; activeMaskPath = null; }); setModalState(() {}); Navigator.pop(context); })])]))))]))));
  }

  Widget _retroButton(IconData? icon, String label, VoidCallback onTap) => GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFF333333), border: Border.all(color: Colors.white12), borderRadius: BorderRadius.circular(4)), child: Row(mainAxisSize: MainAxisSize.min, children: [if (icon != null) Icon(icon, size: 16, color: Colors.white), if (icon != null) const SizedBox(width: 4), Text(label, style: const TextStyle(fontSize: 10, color: Colors.white))])));
  Widget _mainTool(DrawingTool tool, IconData icon, String label) {
    bool sel = activeTool == tool;
    return GestureDetector(onTap: () => setState(() { activeTool = tool; if (tool != DrawingTool.selection && tool != DrawingTool.eyedropper) lastDrawingTool = tool; if (tool != DrawingTool.selection) activeMaskPath = null; isPenMenuOpen = false; isBrushMenuOpen = false; isTextMenuOpen = false; }), child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: sel ? const Color(0xFF121212) : const Color(0xFF333333), border: Border.all(color: sel ? Colors.lightBlueAccent : Colors.white12), borderRadius: BorderRadius.circular(4)), child: Column(children: [Icon(icon, size: 28, color: sel ? Colors.lightBlueAccent : Colors.white), Text(label, style: TextStyle(fontSize: 10, color: sel ? Colors.lightBlueAccent : Colors.white))])));
  }

  Widget _buildCustomCursor() => Container(width: brushWidth, height: brushWidth, decoration: BoxDecoration(shape: BoxShape.circle, color: activeTool == DrawingTool.eraser ? Colors.white.withValues(alpha: 0.2) : selectedColor.withValues(alpha: 0.3 * brushOpacity), border: Border.all(color: Colors.white38, width: 1)));
}

class RetroColorDialog extends StatefulWidget {
  final Color initialColor;
  const RetroColorDialog({super.key, required this.initialColor});
  @override
  State<RetroColorDialog> createState() => _RetroColorDialogState();
}

class _RetroColorDialogState extends State<RetroColorDialog> {
  late Color currentColor;
  late TextEditingController hexController;

  @override
  void initState() {
    super.initState();
    currentColor = widget.initialColor;
    hexController = TextEditingController(text: '#\${currentColor.toRgbValue().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}');
  }

  void _updateColor(Color color) {
    setState(() {
      currentColor = color;
      hexController.text = '#\${color.toRgbValue().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
    });
  }

  @override
  Widget build(BuildContext context) {
    HSVColor hsv = HSVColor.fromColor(currentColor);
    return Dialog(
      backgroundColor: const Color(0xFF252525),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.white12)),
      child: Container(
        padding: const EdgeInsets.all(4),
        width: 450,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(height: 40, decoration: const BoxDecoration(color: Color(0xFF121212), borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12))), padding: const EdgeInsets.symmetric(horizontal: 16), child: const Row(children: [Text(\"Renkleri Düzenle\", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)), Spacer(), Icon(Icons.palette, color: Colors.white, size: 18)])),
          Padding(padding: const EdgeInsets.all(16), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Column(children: [
              GestureDetector(
                onPanUpdate: (d) {
                  double hue = (d.localPosition.dx / 200 * 360).clamp(0.0, 360.0);
                  double sat = (1 - d.localPosition.dy / 200).clamp(0.0, 1.0);
                  _updateColor(HSVColor.fromAHSV(1.0, hue, sat, hsv.value).toColor());
                },
                child: Container(width: 200, height: 200, decoration: BoxDecoration(border: Border.all(color: Colors.white12), borderRadius: BorderRadius.circular(4), gradient: const LinearGradient(colors: [Colors.red, Colors.yellow, Colors.green, Colors.cyan, Colors.blue, Color(0xFFFF00FF), Colors.red]))),
              ),
              const SizedBox(height: 16),
              Container(width: 60, height: 60, decoration: BoxDecoration(color: currentColor, border: Border.all(color: Colors.white12), borderRadius: BorderRadius.circular(8)))
            ]),
            const SizedBox(width: 24),
            Expanded(child: Column(children: [
              _colorInput(\"Renk:\", hsv.hue.toInt().clamp(0, 360), (v) => _updateColor(hsv.withHue(v.toDouble().clamp(0.0, 360.0)).toColor()), 360),
              _colorInput(\"Doygunluk:\", (hsv.saturation * 240).toInt().clamp(0, 240), (v) => _updateColor(hsv.withSaturation((v / 240).clamp(0.0, 1.0)).toColor()), 240),
              _colorInput(\"Parlaklık:\", (hsv.value * 240).toInt().clamp(0, 240), (v) => _updateColor(hsv.withValue((v / 240).clamp(0.0, 1.0)).toColor()), 240),
              const Divider(color: Colors.white12, height: 24),
              Row(children: [const Text(\"Hex:\", style: TextStyle(fontSize: 10, color: Colors.white70)), const SizedBox(width: 12), Expanded(child: Container(height: 32, decoration: BoxDecoration(color: const Color(0xFF121212), borderRadius: BorderRadius.circular(4)), child: TextField(controller: hexController, style: const TextStyle(fontSize: 11, color: Colors.white), decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 14)), onSubmitted: (s) { try { _updateColor(Color(int.parse(s.replaceFirst('#', '0xFF'), radix: 16))); } catch (e) {} })))])
            ]))
          ])),
          Padding(padding: const EdgeInsets.all(16), child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            _dialogButton(\"Tamam\", () => Navigator.pop(context, currentColor), isPrimary: true),
            const SizedBox(width: 12),
            _dialogButton(\"İptal\", () => Navigator.pop(context)),
          ]))
        ]),
      ),
    );
  }

  Widget _colorInput(String label, int val, Function(int) onChange, int max) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(children: [SizedBox(width: 40, child: Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70))), Expanded(child: SizedBox(height: 20, child: Slider(value: val.toDouble(), min: 0, max: max.toDouble(), activeColor: Colors.lightBlueAccent, inactiveColor: Colors.black, onChanged: (v) => onChange(v.toInt())))), Container(width: 32, height: 22, decoration: BoxDecoration(color: const Color(0xFF121212), borderRadius: BorderRadius.circular(4)), child: Center(child: Text(\"\$val\", style: const TextStyle(fontSize: 10, color: Colors.white))))]));

  Widget _dialogButton(String label, VoidCallback onTap, {bool isPrimary = false}) => GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), decoration: BoxDecoration(color: isPrimary ? Colors.lightBlueAccent.withValues(alpha: 0.1) : const Color(0xFF333333), border: Border.all(color: isPrimary ? Colors.lightBlueAccent : Colors.white12), borderRadius: BorderRadius.circular(4)), child: Center(child: Text(label, style: TextStyle(fontSize: 11, color: isPrimary ? Colors.lightBlueAccent : Colors.white)))));
}

extension ColorExt on Color {
  int toRgbValue() => (a * 255).toInt() << 24 | (r * 255).toInt() << 16 | (g * 255).toInt() << 8 | (b * 255).toInt();
}

class StrokePreviewPainter extends CustomPainter {
  final DrawingTool tool; final Color color;
  StrokePreviewPainter({required this.tool, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..moveTo(0, size.height / 2)..quadraticBezierTo(size.width * 0.25, 0, size.width * 0.5, size.height / 2)..quadraticBezierTo(size.width * 0.75, size.height, size.width, size.height / 2);
    final metric = path.computeMetrics().first;
    final List<Offset?> pts = [];
    for (double t = 0; t <= 1.0; t += 0.05) pts.add(metric.getTangentForOffset(metric.length * t)!.position);
    pts.add(null);
    PathOp(points: pts, tool: tool, color: color, strokeWidth: 8, opacity: 1.0).draw(canvas, [], 1.0, Colors.orange);
  }
  @override bool shouldRepaint(covariant CustomPainter old) => false;
}

class ColoringPainter extends CustomPainter {
  final List<PathData> paths; final List<AppLayer> layers; final Color bgColor; final bool isTransparent; final int activeLayerIndex; final bool isSelectionActive; final Color secondaryColor;
  ColoringPainter({required this.paths, required this.layers, required this.bgColor, required this.isTransparent, required this.activeLayerIndex, required this.isSelectionActive, required this.secondaryColor});
  
  void drawTransparencyGrid(Canvas canvas, Size size) {
    final paint1 = Paint()..color = Colors.white;
    final paint2 = Paint()..color = Colors.grey[300]!;
    const double step = 20;
    for (double y = 0; y < size.height; y += step) {
      for (double x = 0; x < size.width; x += step) {
        canvas.drawRect(Rect.fromLTWH(x, y, step, step), ((x / step).toInt() + (y / step).toInt()) % 2 == 0 ? paint1 : paint2);
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (isTransparent) drawTransparencyGrid(canvas, size);
    else canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = bgColor);
    
    for (int i = layers.length - 1; i >= 0; i--) {
      final layer = layers[i];
      if (!layer.isVisible) continue;
      canvas.save();
      canvas.translate(layer.offset.dx, layer.offset.dy);
      canvas.scale(layer.scale);
      
      final layerBounds = layer.getBounds(size);
      final drawBounds = Rect.fromLTWH(0, 0, layerBounds.width / layer.scale, layerBounds.height / layer.scale);

      canvas.saveLayer(drawBounds, Paint()..color = Colors.white.withValues(alpha: layer.opacity));
      
      if (layer.hasSolidBackground && !isTransparent) canvas.drawRect(drawBounds, Paint()..color = Colors.white);
      
      if (layer.isTemplate) { 
        for (var p in paths) canvas.drawPath(p.path, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 2.0 / layer.scale); 
      } else if (layer.image != null) {
        canvas.drawImage(layer.image!, Offset.zero, Paint());
      } else if (layer.isTextLayer && layer.text != null) {
        final tp = layer._getTextPainter();
        tp.paint(canvas, Offset.zero);
      }

      for (var op in layer.operations) op.draw(canvas, paths, 1.0, secondaryColor);
      
      canvas.restore(); // restore layer (saveLayer)
      
      if (isSelectionActive && i == activeLayerIndex) {
        final dashPaint = Paint()..color = Colors.lightBlueAccent..style = PaintingStyle.stroke..strokeWidth = 1.0 / layer.scale;
        canvas.drawRect(drawBounds, dashPaint);
        final handlePaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
        final handleStroke = Paint()..color = Colors.lightBlueAccent..style = PaintingStyle.stroke..strokeWidth = 1.0;
        const hSize = 5.0;
        final List<Offset> hPos = [drawBounds.topLeft, drawBounds.topRight, drawBounds.bottomLeft, drawBounds.bottomRight];
        for (var p in hPos) {
          canvas.drawRect(Rect.fromCenter(center: p, width: hSize * 2, height: hSize * 2), handlePaint);
          canvas.drawRect(Rect.fromCenter(center: p, width: hSize * 2, height: hSize * 2), handleStroke);
        }
      }
      canvas.restore(); // restore transform (translate/scale)
    }
  }
  @override bool shouldRepaint(covariant ColoringPainter old) => true;
}

class MiniLayerPainter extends CustomPainter {
  final AppLayer layer; final List<PathData> paths; final Color secondaryColor;
  MiniLayerPainter({required this.layer, required this.paths, required this.secondaryColor});
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    double s = (layer.image != null) ? math.min(size.width / layer.image!.width, size.height / layer.image!.height) : size.width / 400.0;
    canvas.scale(s);
    if (layer.hasSolidBackground) canvas.drawRect(Rect.fromLTWH(0, 0, 400/s, 400/s), Paint()..color = Colors.white);
    if (layer.isTemplate) { for (var p in paths) canvas.drawPath(p.path, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 4.0 / s); }
    else if (layer.image != null) canvas.drawImage(layer.image!, Offset.zero, Paint());
    else if (layer.isTextLayer && layer.text != null) layer._getTextPainter().paint(canvas, Offset.zero);

    for (var op in layer.operations) op.draw(canvas, paths, 1.0, secondaryColor);
    canvas.restore();
  }
  @override bool shouldRepaint(covariant MiniLayerPainter old) => true;
}
