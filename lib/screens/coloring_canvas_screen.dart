import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

enum DrawingTool {
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
  void draw(Canvas canvas, double parentOpacity, Color secondaryColor, double scale, double offsetX, double offsetY);
  Map<String, dynamic> toJson();
}

class PathOp extends PaintOp {
  final List<Offset?> points;
  final DrawingTool tool;
  final Color color;
  final double strokeWidth;
  final double opacity;
  final ui.Path? clipPath;
  ui.Path? _memoizedPath;

  PathOp({
    required this.points,
    required this.tool,
    required this.color,
    required this.strokeWidth,
    this.opacity = 1.0,
    this.clipPath,
  });

  ui.Path get path {
    if (_memoizedPath != null) return _memoizedPath!;
    _memoizedPath = ui.Path();
    if (points.isEmpty) return _memoizedPath!;

    bool first = true;
    for (int i = 0; i < points.length; i++) {
      if (points[i] != null) {
        if (first) {
          _memoizedPath!.moveTo(points[i]!.dx, points[i]!.dy);
          first = false;
        } else {
          _memoizedPath!.lineTo(points[i]!.dx, points[i]!.dy);
        }
      } else {
        first = true;
      }
    }
    return _memoizedPath!;
  }

  void invalidatePath() {
    _memoizedPath = null;
  }

  @override
  void draw(Canvas canvas, double parentOpacity, Color secondaryColor, double scale, double offsetX, double offsetY) {
    if (clipPath != null) {
      canvas.save();
      canvas.clipPath(clipPath!);
    }

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
        canvas.drawPath(path, paint);
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
            if (points[i] != null && points[i + 1] != null) {
              paint.shader = ui.Gradient.linear(
                points[i]!,
                points[i + 1]!,
                [secondaryColor.withOpacity(finalOpacity * 0.4), color.withOpacity(finalOpacity * 0.6)],
              );
              canvas.drawLine(points[i]!, points[i + 1]!, paint);
            }
          }
        }
        break;
      default:
        canvas.drawPath(path, paint);
    }

    if (clipPath != null) {
      canvas.restore();
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'path',
      'tool': tool.index,
      'color': color.value,
      'strokeWidth': strokeWidth,
      'opacity': opacity,
      'points': points.map((p) => p == null ? null : {'x': p.dx, 'y': p.dy}).toList(),
    };
  }

  static PathOp fromJson(Map<String, dynamic> json) {
    return PathOp(
      tool: DrawingTool.values[json['tool'] as int],
      color: Color(json['color'] as int),
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
      opacity: (json['opacity'] as num).toDouble(),
      points: (json['points'] as List).map((p) {
        if (p == null) return null;
        final map = p as Map<String, dynamic>;
        return Offset((map['x'] as num).toDouble(), (map['y'] as num).toDouble());
      }).toList(),
    );
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

class _ColoringCanvasScreenState extends State<ColoringCanvasScreen> with WidgetsBindingObserver {
  ui.Image? templateImage;
  List<PaintOp> operations = [];
  Color selectedColor = const Color(0xFFE94E77);
  Color secondaryColor = const Color(0xFFF6AD55);
  DrawingTool activeTool = DrawingTool.kursun;
  DrawingTool _lastPencilTool = DrawingTool.kursun;
  DrawingTool _lastBrushTool = DrawingTool.firca_classic;
  double brushWidth = 12.0;
  bool showSubToolMenu = false;
  String? currentMenuType;

  final TransformationController _transformationController = TransformationController();
  int _pointerCount = 0;

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
    WidgetsBinding.instance.addObserver(this);
    _initCanvas();
  }

  Future<void> _initCanvas() async {
    await _loadTemplate();
    await _loadProgress();
  }

  @override
  void dispose() {
    _saveProgress();
    _transformationController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _saveProgress();
    }
  }

  Future<File> _getSaveFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/drawing_${widget.templateId}.json');
  }

  Future<void> _saveProgress() async {
    try {
      final file = await _getSaveFile();
      final List<Map<String, dynamic>> jsonData = operations.map((op) => op.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonData));
    } catch (e) {
      debugPrint('Error saving progress: $e');
    }
  }

  Future<void> _loadProgress() async {
    try {
      final file = await _getSaveFile();
      if (await file.exists()) {
        final String content = await file.readAsString();
        final List<dynamic> jsonData = jsonDecode(content);
        final List<PaintOp> loadedOps = [];
        
        for (var item in jsonData) {
          final map = item as Map<String, dynamic>;
          if (map['type'] == 'path') {
            loadedOps.add(PathOp.fromJson(map));
          }
        }

        setState(() {
          operations = loadedOps;
        });
      }
    } catch (e) {
      debugPrint('Error loading progress: $e');
    }
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
    if (_undoStack.length > 30) _undoStack.removeAt(0);
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

  Offset _screenToPixel(Offset screenPos, Size size) {
    if (templateImage == null) return screenPos;
    final width = templateImage!.width;
    final height = templateImage!.height;

    double scale = math.min(size.width / width, size.height / height);
    double offsetX = (size.width - width * scale) / 2;
    double offsetY = (size.height - height * scale) / 2;

    final Matrix4 transform = _transformationController.value;
    final Matrix4 inverse = Matrix4.inverted(transform);
    final Offset scenePos = MatrixUtils.transformPoint(inverse, screenPos);

    return Offset(
      (scenePos.dx - offsetX) / scale,
      (scenePos.dy - offsetY) / scale,
    );
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
              onPointerDown: (event) => setState(() => _pointerCount++),
              onPointerUp: (event) => setState(() => _pointerCount--),
              onPointerCancel: (event) => setState(() => _pointerCount--),
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 1.0,
                maxScale: 10.0,
                panEnabled: _pointerCount > 1,
                scaleEnabled: _pointerCount > 1,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: templateImage != null 
                        ? templateImage!.width / templateImage!.height 
                        : 1.0,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final size = constraints.biggest;
                        return GestureDetector(
                          onPanStart: (details) {
                            if (_pointerCount > 1) return;
                            _saveHistory();
                            final pixelPos = _screenToPixel(details.localPosition, size);
                            setState(() {
                              operations.add(PathOp(
                                points: [pixelPos],
                                tool: activeTool,
                                color: selectedColor,
                                strokeWidth: brushWidth,
                              ));
                            });
                          },
                          onPanUpdate: (details) {
                            if (_pointerCount > 1) return;
                            if (operations.isNotEmpty && operations.last is PathOp) {
                              final pixelPos = _screenToPixel(details.localPosition, size);
                              final op = operations.last as PathOp;
                              if (op.points.isNotEmpty) {
                                final lastPoint = op.points.last;
                                if (lastPoint != null) {
                                  if ((pixelPos - lastPoint).distance < 1.0) return;
                                }
                              }
                              setState(() {
                                op.points.add(pixelPos);
                                op.invalidatePath();
                              });
                            }
                          },
                          onPanEnd: (_) {
                            if (operations.isNotEmpty && operations.last is PathOp) {
                              (operations.last as PathOp).points.add(null);
                            }
                          },
                          child: CustomPaint(
                            painter: ColoringPainter(
                              template: templateImage,
                              operations: operations,
                              secondaryColor: secondaryColor,
                            ),
                            size: Size.infinite,
                          ),
                        );
                      }
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
        return GestureDetector(
          onTap: () => setState(() {
              activeTool = tool;
              showSubToolMenu = false;
              if (currentMenuType == 'Kalem') {
                _lastPencilTool = tool;
              } else if (currentMenuType == 'Firca') {
                _lastBrushTool = tool;
              }
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
    );
  }

  Widget _toolButton(DrawingTool tool, IconData icon, String label, {bool isMenu = false}) {
    bool isSelected = activeTool == tool || (isMenu && currentMenuType == label && showSubToolMenu);
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
                activeTool = _lastBrushTool;
              } else if (label == "Kalem") {
                activeTool = _lastPencilTool;
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
    if (template == null) return;

    final width = template!.width;
    final height = template!.height;
    double scale = math.min(size.width / width, size.height / height);
    double offsetX = (size.width - width * scale) / 2;
    double offsetY = (size.height - height * scale) / 2;

    canvas.save();
    canvas.translate(offsetX, offsetY);
    canvas.scale(scale);

    canvas.saveLayer(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), Paint());
    
    for (var op in operations) {
      op.draw(canvas, 1.0, secondaryColor, scale, 0, 0);
    }

    final paint = Paint()..blendMode = BlendMode.multiply;
    canvas.drawImage(template!, Offset.zero, paint);
    
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ColoringPainter oldDelegate) => true;
}
