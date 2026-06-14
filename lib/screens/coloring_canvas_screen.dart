import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

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
      ..color = color.withOpacity(finalOpacity)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    if (tool == DrawingTool.eraser) {
      paint.blendMode = BlendMode.clear;
    }

    if (maskPath != null) {
      canvas.save();
      canvas.clipPath(maskPath!);
    }

    switch (tool) {
      case DrawingTool.gradyan_fircasi:
        paint.blendMode = tool == DrawingTool.eraser ? BlendMode.clear : BlendMode.plus;
        paint.strokeWidth = strokeWidth * 1.5;
        if (points.length > 1) {
          for (int i = 0; i < points.length - 1; i++) {
            if (points[i] != null && points[i+1] != null) {
              paint.shader = ui.Gradient.linear(
                points[i]!,
                points[i+1]!,
                [
                  secondaryColor.withOpacity(finalOpacity * 0.4), 
                  color.withOpacity(finalOpacity * 0.6)
                ],
              );
              canvas.drawLine(points[i]!, points[i+1]!, paint);
              if (tool != DrawingTool.eraser) {
                canvas.drawLine(points[i]!, points[i+1]!, paint..blendMode = BlendMode.screen..strokeWidth = strokeWidth * 0.8..shader = null..color = color.withOpacity(finalOpacity * 0.2));
              }
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
            canvas.drawLine(points[i]!, points[i + 1]!, paint..strokeWidth = strokeWidth * 1.2..color = color.withOpacity(finalOpacity * 0.4));
          }
        }
        break;
      case DrawingTool.yagli_firca:
        for (int i = 0; i < points.length - 1; i++) {
          if (points[i] != null && points[i + 1] != null) {
            for (int j = -2; j <= 2; j++) {
              Offset off = Offset(j * 1.5, j * 1.5);
              canvas.drawLine(points[i]! + off, points[i+1]! + off, paint..color = color.withOpacity(finalOpacity * 0.7));
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
              canvas.drawLine(points[i]! + off, points[i+1]! + off, paint..color = color.withOpacity(finalOpacity * 0.6));
            }
          }
        }
        break;
      case DrawingTool.dogal_kalem:
        paint.strokeWidth = strokeWidth * 0.5;
        for (int i = 0; i < points.length - 1; i++) {
          if (points[i] != null && points[i + 1] != null) {
            canvas.drawLine(points[i]!, points[i + 1]!, paint..color = color.withOpacity(finalOpacity * 0.8));
          }
        }
        break;
      case DrawingTool.sulu_firca:
        paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        paint.color = color.withOpacity(finalOpacity * 0.2);
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
      canvas.drawPath(paths[pathIndex].path, Paint()..color = color.withOpacity(opacity * parentOpacity)..style = PaintingStyle.fill);
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
          color: (textColor ?? Colors.white).withOpacity(opacity),
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
  List<AppLayer> layers = [];
  int activeLayerIndex = 0;
  Color selectedColor = const Color(0xFFE94E77);
  Color secondaryColor = const Color(0xFFF6AD55);
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

  final List<List<PaintOp>> _undoStack = [];
  final List<List<PaintOp>> _redoStack = [];

  final List<Color> palette = [
    const Color(0xFFFDFBF7), const Color(0xFF2D2D2D), const Color(0xFF8B8B8B), const Color(0xFFE0E0E0),
    const Color(0xFFE94E77), const Color(0xFFFF6B6B), const Color(0xFFEE5253), const Color(0xFFD63031),
    const Color(0xFFF6AD55), const Color(0xFFFEA47F), const Color(0xFFFAD390), const Color(0xFFF8C291),
    const Color(0xFFFFD166), const Color(0xFFFFBC42), const Color(0xFFECCC68), const Color(0xFFC49102),
    const Color(0xFF06D6A0), const Color(0xFF1DD1A1), const Color(0xFF10AC84), const Color(0xFF006266),
    const Color(0xFF118AB2), const Color(0xFF48DBFB), const Color(0xFF00D1FF), const Color(0xFF0984E3),
    const Color(0xFF073B4C), const Color(0xFF2E86DE), const Color(0xFF54A0FF), const Color(0xFF1B9CFC),
    const Color(0xFF9B59B6), const Color(0xFFA29BFE), const Color(0xFF6C5CE7), const Color(0xFF5F27CD),
    const Color(0xFFED4C67), const Color(0xFFFDA7DF), const Color(0xFFD1D1D1), const Color(0xFFB2BEC3),
    const Color(0xFF833471), const Color(0xFF6F1E51), const Color(0xFF222F3E), const Color(0xFF576574),
    const Color(0xFFA3CB38), const Color(0xFF009432), const Color(0xFFC23616), const Color(0xFF192A56),
  ];

  @override
  void initState() {
    super.initState();
    _initTemplate();
  }

  void _initTemplate() {
    layers = [
      AppLayer(id: 'tpl', name: 'Sablon Katman', isTemplate: true),
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
        backgroundColor: const Color(0xFFFDFBF7),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: Color(0xFF2D2D2D), width: 3)),
        title: const Text("Metin Ekle", style: TextStyle(color: Color(0xFF2D2D2D), fontWeight: FontWeight.black)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Color(0xFF2D2D2D)),
          decoration: const InputDecoration(hintText: "Buraya yazin...", border: OutlineInputBorder()),
          onSubmitted: (val) {
            if (val.isNotEmpty) {
              _submitText(val, position);
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          _neuButton("Iptal", () => Navigator.pop(context), color: Colors.white),
          _neuButton("Ekle", () {
            if (controller.text.isNotEmpty) {
              _submitText(controller.text, position);
            }
            Navigator.pop(context);
          }, color: const Color(0xFFFFD166)),
        ],
      ),
    );
  }

  void _submitText(String text, Offset position) {
    setState(() {
      layers.insert(0, AppLayer(
        id: DateTime.now().toString(),
        name: "Metin: $text",
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
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDFBF7), 
        title: const Text('BOYAMA DUNYASI', style: TextStyle(fontWeight: FontWeight.black, color: Color(0xFF2D2D2D), fontSize: 18, letterSpacing: 1.5)), 
        elevation: 0, 
        iconTheme: const IconThemeData(color: Color(0xFF2D2D2D)), 
        actions: [
          _appBarButton(Icons.undo, _undo),
          _appBarButton(Icons.redo, _redo),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(4), child: Container(color: const Color(0xFF2D2D2D), height: 4)),
      ),
      body: Column(children: [
        Expanded(child: LayoutBuilder(builder: (context, constraints) {
          canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
          templatePaths ??= getApplePaths(canvasSize!);
          return Container(
            color: const Color(0xFFE0E0E0),
            child: Center(
              child: SizedBox(
                width: canvasSize!.width,
                height: canvasSize!.height,
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
        _buildBottomToolbar(),
      ]),
    );
  }

  Widget _appBarButton(IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFFDFBF7),
            border: Border.all(color: const Color(0xFF2D2D2D), width: 2),
            boxShadow: const [BoxShadow(color: Color(0xFF2D2D2D), offset: Offset(2, 2))],
          ),
          child: Icon(icon, color: const Color(0xFF2D2D2D), size: 20),
        ),
      ),
    );
  }

  Widget _buildBottomToolbar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), 
      decoration: const BoxDecoration(
        color: Color(0xFFFDFBF7), 
        border: Border(top: BorderSide(color: Color(0xFF2D2D2D), width: 4))
      ), 
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _toolNeuButton(DrawingTool.kursun, Icons.edit, "Kalem"),
          _toolNeuButton(DrawingTool.firca_classic, Icons.brush, "Firca"),
          _toolNeuButton(DrawingTool.bucket, Icons.format_paint, "Kova"),
          _toolNeuButton(DrawingTool.eraser, Icons.delete_outline, "Silgi"),
          _toolNeuButton(DrawingTool.text, Icons.text_fields, "Yazi"),
        ]),
        const SizedBox(height: 20),
        SizedBox(
          height: 60, 
          child: ListView.builder(
            scrollDirection: Axis.horizontal, 
            itemCount: palette.length, 
            itemBuilder: (c, i) => GestureDetector(
              onTap: () => setState(() { secondaryColor = selectedColor; selectedColor = palette[i]; }), 
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6), 
                width: 44, 
                height: 44, 
                decoration: BoxDecoration(
                  color: palette[i], 
                  border: Border.all(color: const Color(0xFF2D2D2D), width: selectedColor == palette[i] ? 4 : 2),
                  boxShadow: selectedColor == palette[i] ? null : const [BoxShadow(color: Color(0xFF2D2D2D), offset: Offset(3, 3))],
                )
              )
            )
          )
        ),
      ]));
  }

  Widget _toolNeuButton(DrawingTool tool, IconData icon, String label) {
    bool sel = activeTool == tool;
    return GestureDetector(
      onTap: () => setState(() { activeTool = tool; }),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: sel ? const Color(0xFFFFD166) : Colors.white,
              border: Border.all(color: const Color(0xFF2D2D2D), width: 3),
              boxShadow: sel ? null : const [BoxShadow(color: Color(0xFF2D2D2D), offset: Offset(4, 4))],
            ),
            child: Icon(icon, color: const Color(0xFF2D2D2D)),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.black, color: Color(0xFF2D2D2D))),
        ],
      ),
    );
  }

  Widget _neuButton(String label, VoidCallback onTap, {required Color color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: const Color(0xFF2D2D2D), width: 2),
          boxShadow: const [BoxShadow(color: Color(0xFF2D2D2D), offset: Offset(3, 3))],
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.black, fontSize: 12)),
      ),
    );
  }

  Widget _buildCustomCursor() => Container(width: brushWidth, height: brushWidth, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF2D2D2D), width: 2)));
}

class ColoringPainter extends CustomPainter {
  final List<PathData> paths; final List<AppLayer> layers; final Color bgColor; final bool isTransparent; final int activeLayerIndex; final bool isSelectionActive; final Color secondaryColor;
  ColoringPainter({required this.paths, required this.layers, required this.bgColor, required this.isTransparent, required this.activeLayerIndex, required this.isSelectionActive, required this.secondaryColor});
  
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = bgColor);
    
    for (int i = layers.length - 1; i >= 0; i--) {
      final layer = layers[i];
      if (!layer.isVisible) continue;
      canvas.save();
      canvas.translate(layer.offset.dx, layer.offset.dy);
      canvas.scale(layer.scale);
      
      final layerBounds = layer.getBounds(size);
      final drawBounds = Rect.fromLTWH(0, 0, layerBounds.width / layer.scale, layerBounds.height / layer.scale);

      canvas.saveLayer(drawBounds, Paint()..color = Colors.white.withOpacity(layer.opacity));
      
      if (layer.isTemplate) { 
        for (var p in paths) canvas.drawPath(p.path, Paint()..color = const Color(0xFF2D2D2D)..style = PaintingStyle.stroke..strokeWidth = 2.5 / layer.scale); 
      } else if (layer.image != null) {
        canvas.drawImage(layer.image!, Offset.zero, Paint());
      } else if (layer.isTextLayer && layer.text != null) {
        layer._getTextPainter().paint(canvas, Offset.zero);
      }

      for (var op in layer.operations) op.draw(canvas, paths, 1.0, secondaryColor);
      
      canvas.restore(); 
      canvas.restore(); 
    }
  }
  @override bool shouldRepaint(covariant ColoringPainter old) => true;
}
