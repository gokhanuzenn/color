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
  jel_kalem,
  komur,
  boya_kalemi,
  firca_classic,
  sulu_firca,
  sprey,
  yagli_boya,
  kuru_firca,
  gradyan_fircasi,
  eraser,
}

abstract class PaintOp {
  void draw(Canvas canvas, double parentOpacity, Color secondaryColor);
  Map<String, dynamic> toJson();
}

class PathOp extends PaintOp {
  final List<Offset?> points;
  final DrawingTool tool;
  final Color color;
  final double strokeWidth;
  final double opacity;
  ui.Path? _memoizedPath;

  PathOp({
    required this.points,
    required this.tool,
    required this.color,
    required this.strokeWidth,
    this.opacity = 1.0,
  });

  ui.Path get path {
    if (_memoizedPath != null) return _memoizedPath!;
    _memoizedPath = ui.Path();
    if (points.isEmpty) return _memoizedPath!;
    bool first = true;
    for (var p in points) {
      if (p != null) {
        if (first) {
          _memoizedPath!.moveTo(p.dx, p.dy);
          first = false;
        } else {
          _memoizedPath!.lineTo(p.dx, p.dy);
        }
      } else {
        first = true;
      }
    }
    return _memoizedPath!;
  }

  void invalidate() => _memoizedPath = null;

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
        paint.strokeWidth = strokeWidth * 0.4;
        paint.color = color.withOpacity(finalOpacity * 0.7);
        canvas.drawPath(path, paint);
        break;
      case DrawingTool.sulu_firca:
        paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
        paint.color = color.withOpacity(finalOpacity * 0.2);
        paint.strokeWidth = strokeWidth * 2.0;
        canvas.drawPath(path, paint);
        break;
      case DrawingTool.boya_kalemi:
        final rnd = math.Random(42);
        for (int i = 0; i < points.length - 1; i++) {
          if (points[i] != null && points[i + 1] != null) {
            for (int j = 0; j < 5; j++) {
              Offset off = Offset(rnd.nextDouble() * 5 - 2.5, rnd.nextDouble() * 5 - 2.5);
              canvas.drawLine(points[i]! + off, points[i + 1]! + off, paint..color = color.withOpacity(finalOpacity * 0.5)..strokeWidth = strokeWidth * 0.3);
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
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'path',
    'points': points.map((p) => p == null ? null : {'x': p.dx, 'y': p.dy}).toList(),
    'tool': tool.index,
    'color': color.value,
    'strokeWidth': strokeWidth,
    'opacity': opacity,
  };

  static PathOp fromJson(Map<String, dynamic> json) {
    return PathOp(
      points: (json['points'] as List).map((p) => p == null ? null : Offset((p['x'] as num).toDouble(), (p['y'] as num).toDouble())).toList(),
      tool: DrawingTool.values[json['tool'] as int],
      color: Color(json['color'] as int),
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
      opacity: (json['opacity'] as num).toDouble(),
    );
  }
}

class ColoringCanvasScreen extends StatefulWidget {
  final String assetPath;
  final String templateId;

  const ColoringCanvasScreen({super.key, required this.assetPath, required this.templateId});

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

  ui.Image? _cachedDrawing;
  int _lastCachedCount = 0;

  final List<Color> palette = [
    const Color(0xFF2D2D2D), const Color(0xFFE94E77), const Color(0xFFFF6B6B),
    const Color(0xFFF6AD55), const Color(0xFFFFD166), const Color(0xFF06D6A0),
    const Color(0xFF118AB2), const Color(0xFF073B4C), const Color(0xFF9B59B6),
    const Color(0xFFED4C67), const Color(0xFFA3CB38), const Color(0xFFC23616),
    const Color(0xFF000000), const Color(0xFFFFFFFF), const Color(0xFF808080),
    const Color(0xFFFF0000), const Color(0xFF00FF00), const Color(0xFF0000FF),
    const Color(0xFFFFFF00), const Color(0xFF00FFFF), const Color(0xFFFF00FF),
    const Color(0xFFFFA500), const Color(0xFF800080), const Color(0xFF008000),
    const Color(0xFF800000), const Color(0xFF000080), const Color(0xFF808000),
    const Color(0xFF008080), const Color(0xFFC0C0C0), const Color(0xFFFFC0CB),
    const Color(0xFFF0E68C), const Color(0xFFE6E6FA), const Color(0xFFFFF0F5),
    const Color(0xFFFAF0E6), const Color(0xFF7B68EE), const Color(0xFF48D1CC),
    const Color(0xFFB0C4DE), const Color(0xFF20B2AA), const Color(0xFF778899),
    const Color(0xFFBC8F8F), const Color(0xFF4682B4), const Color(0xFFD2B48C),
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
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) _saveProgress();
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
    } catch (e) { debugPrint('Error saving progress: $e'); }
  }

  Future<void> _loadProgress() async {
    try {
      final file = await _getSaveFile();
      if (await file.exists()) {
        final String content = await file.readAsString();
        final List decoded = jsonDecode(content);
        setState(() {
          operations = decoded.map((item) => PathOp.fromJson(item)).toList();
        });
        _updateCache();
      }
    } catch (e) { debugPrint('Error loading progress: $e'); }
  }

  Future<void> _loadTemplate() async {
    final ByteData data = await rootBundle.load(widget.assetPath);
    final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final ui.FrameInfo fi = await codec.getNextFrame();
    setState(() { templateImage = fi.image; });
  }

  Future<void> _updateCache() async {
    if (templateImage == null) return;
    final width = templateImage!.width.toDouble();
    final height = templateImage!.height.toDouble();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    if (_cachedDrawing != null) canvas.drawImage(_cachedDrawing!, Offset.zero, Paint());
    for (int i = _lastCachedCount; i < operations.length - 1; i++) {
      operations[i].draw(canvas, 1.0, secondaryColor);
    }
    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    setState(() {
      _cachedDrawing = img;
      _lastCachedCount = operations.length > 0 ? operations.length - 1 : 0;
    });
  }

  void _invalidateCache() {
    setState(() {
      _cachedDrawing = null;
      _lastCachedCount = 0;
    });
    _updateCache();
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
      _invalidateCache();
    }
  }

  void _redo() {
    if (_redoStack.isNotEmpty) {
      setState(() {
        _undoStack.add(List<PaintOp>.from(operations));
        operations = _redoStack.removeLast();
      });
      _invalidateCache();
    }
  }

  Offset _screenToPixel(Offset screenPos, Size size) {
    if (templateImage == null) return screenPos;
    double scaleX = size.width / templateImage!.width;
    double scaleY = size.height / templateImage!.height;
    return Offset(screenPos.dx / scaleX, screenPos.dy / scaleY);
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
                    aspectRatio: templateImage != null ? templateImage!.width / templateImage!.height : 1.0,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final size = constraints.biggest;
                        return GestureDetector(
                          onPanStart: _pointerCount > 1 ? null : (details) {
                            _saveHistory();
                            final pixelPos = _screenToPixel(details.localPosition, size);
                            setState(() {
                              operations.add(PathOp(points: [pixelPos], tool: activeTool, color: selectedColor, strokeWidth: brushWidth));
                            });
                          },
                          onPanUpdate: _pointerCount > 1 ? null : (details) {
                            if (operations.isNotEmpty && operations.last is PathOp) {
                              final pixelPos = _screenToPixel(details.localPosition, size);
                              final op = operations.last as PathOp;
                              if (op.points.isNotEmpty && op.points.last != null && (pixelPos - op.points.last!).distance < 1.0) return;
                              setState(() {
                                op.points.add(pixelPos);
                                op.invalidate();
                              });
                            }
                          },
                          onPanEnd: _pointerCount > 1 ? null : (_) {
                            if (operations.isNotEmpty && operations.last is PathOp) (operations.last as PathOp).points.add(null);
                            _updateCache();
                          },
                          child: RepaintBoundary(
                            child: CustomPaint(
                              painter: ColoringPainter(
                                template: templateImage,
                                operations: operations,
                                secondaryColor: secondaryColor,
                                cachedDrawing: _cachedDrawing,
                                cachedCount: _lastCachedCount,
                              ),
                              size: Size.infinite,
                            ),
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
          _buildSubToolMenu(),
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
              value: brushWidth, min: 2.0, max: 100.0,
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
    if (!showSubToolMenu || currentMenuType == null) return const SizedBox.shrink();
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
    return Container(
      height: 60, margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: subTools.length,
        itemBuilder: (context, index) {
          final st = subTools[index];
          final tool = st['tool'] as DrawingTool;
          bool isSelected = activeTool == tool;
          return GestureDetector(
            onTap: () => setState(() {
              activeTool = tool;
              if (currentMenuType == 'Kalem') _lastPencilTool = tool;
              else if (currentMenuType == 'Firca') _lastBrushTool = tool;
            }),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFFD166) : Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0xFF2D2D2D), width: 3),
                boxShadow: isSelected ? null : const [BoxShadow(color: Color(0xFF2D2D2D), offset: Offset(4, 4))],
              ),
              child: Center(child: Text(st['label'] as String, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14))),
            ),
          );
        }
      ),
    );
  }

  Widget _toolButton(DrawingTool tool, IconData icon, String label, {bool isMenu = false}) {
    bool isSelected = (isMenu && currentMenuType == label && showSubToolMenu) || (!isMenu && activeTool == tool);
    return GestureDetector(
      onTap: () {
        if (isMenu) {
          if (currentMenuType == label) setState(() => showSubToolMenu = !showSubToolMenu);
          else setState(() { showSubToolMenu = true; currentMenuType = label; activeTool = (label == "Firca") ? _lastBrushTool : _lastPencilTool; });
        } else { setState(() { activeTool = tool; showSubToolMenu = false; currentMenuType = null; }); }
      },
      child: Column(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFFD166) : Colors.white,
              border: Border.all(color: const Color(0xFF2D2D2D), width: 3),
              boxShadow: isSelected ? null : const [BoxShadow(color: Color(0xFF2D2D2D), offset: Offset(4, 4))],
            ),
            child: Icon(icon, color: const Color(0xFF2D2D2D), size: 30),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildPalette() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: palette.length,
        itemBuilder: (context, index) => GestureDetector(
          onTap: () => setState(() { secondaryColor = selectedColor; selectedColor = palette[index]; }),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: palette[index], shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF2D2D2D), width: selectedColor == palette[index] ? 5 : 3),
              boxShadow: selectedColor == palette[index] ? null : const [BoxShadow(color: Color(0xFF2D2D2D), offset: Offset(3, 3))],
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
  final ui.Image? cachedDrawing;
  final int cachedCount;

  ColoringPainter({this.template, required this.operations, required this.secondaryColor, this.cachedDrawing, this.cachedCount = 0});

  @override
  void paint(Canvas canvas, Size size) {
    if (template == null) return;
    final width = template!.width.toDouble();
    final height = template!.height.toDouble();
    double scale = math.min(size.width / width, size.height / height);
    double offsetX = (size.width - width * scale) / 2;
    double offsetY = (size.height - height * scale) / 2;

    canvas.save();
    canvas.translate(offsetX, offsetY);
    canvas.scale(scale);

    canvas.saveLayer(Rect.fromLTWH(0, 0, width, height), Paint());
    if (cachedDrawing != null) canvas.drawImage(cachedDrawing!, Offset.zero, Paint());
    for (int i = cachedCount; i < operations.length; i++) {
      operations[i].draw(canvas, 1.0, secondaryColor);
    }
    canvas.drawImage(template!, Offset.zero, Paint()..blendMode = BlendMode.multiply);
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ColoringPainter oldDelegate) => true;
}
