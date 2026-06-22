import "package:flutter/foundation.dart";
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:color_world/billing_manager.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:color_world/utils/localization.dart';
import 'dart:io' if (dart.library.html) 'dart:html';

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
  pencil_hb,
  pencil_2b,
  pencil_4b,
  pencil_6b,
  pencil_9b,
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
      case DrawingTool.pencil_hb:
      case DrawingTool.pencil_2b:
      case DrawingTool.pencil_4b:
      case DrawingTool.pencil_6b:
      case DrawingTool.pencil_9b:
      case DrawingTool.kursun:
        final Map<DrawingTool, Map<String, dynamic>> config = {
          DrawingTool.pencil_hb: {'a': 0.7, 'w': 0.1},
          DrawingTool.pencil_2b: {'a': 0.6, 'w': 0.15},
          DrawingTool.pencil_4b: {'a': 0.5, 'w': 0.2},
          DrawingTool.pencil_6b: {'a': 0.4, 'w': 0.3},
          DrawingTool.pencil_9b: {'a': 0.35, 'w': 0.4},
          DrawingTool.kursun: {'a': 0.8, 'w': 0.1},
        };
        final settings = config[tool] ?? {'a': 0.8, 'w': 0.1};
        paint.color = color.withOpacity(finalOpacity * (settings['a'] as double));
        paint.strokeWidth = strokeWidth * (settings['w'] as double);
        canvas.drawPath(path, paint);
        
        final noisePaint = Paint()..color = paint.color..style = PaintingStyle.fill;
        final rnd = math.Random(42);
        for (var p in points) {
          if (p != null && rnd.nextDouble() > 0.4) {
            canvas.drawRect(Rect.fromLTWH(p.dx + (rnd.nextDouble()-0.5)*3, p.dy + (rnd.nextDouble()-0.5)*3, 1, 1), noisePaint);
          }
        }
        break;

      case DrawingTool.sulu_firca:
        paint.color = color.withOpacity(finalOpacity * 0.08);
        paint.strokeWidth = strokeWidth;
        final rnd = math.Random(42);
        for (int i = 0; i < 3; i++) {
          final bristlePath = ui.Path();
          bool first = true;
          double bWidth = strokeWidth * (1 - i * 0.15);
          paint.strokeWidth = bWidth;
          for (var p in points) {
            if (p != null) {
              Offset off = Offset((rnd.nextDouble()-0.5)*4, (rnd.nextDouble()-0.5)*4);
              if (first) { bristlePath.moveTo(p.dx + off.dx, p.dy + off.dy); first = false; }
              else bristlePath.lineTo(p.dx + off.dx, p.dy + off.dy);
            } else { first = true; }
          }
          canvas.drawPath(bristlePath, paint);
        }
        break;

      case DrawingTool.firca_classic:
        paint.color = color.withOpacity(finalOpacity * 0.7);
        const bristleCount = 10;
        for (int i = 0; i < bristleCount; i++) {
          final bPath = ui.Path();
          bool first = true;
          double offset = (i - bristleCount / 2) * (strokeWidth / bristleCount);
          paint.strokeWidth = math.max(1, strokeWidth / 8);
          for (var p in points) {
            if (p != null) {
              if (first) { bPath.moveTo(p.dx + offset, p.dy + offset); first = false; }
              else bPath.lineTo(p.dx + offset, p.dy + offset);
            } else { first = true; }
          }
          canvas.drawPath(bPath, paint);
        }
        break;

      case DrawingTool.boya_kalemi:
        paint.color = color.withOpacity(finalOpacity * 0.6);
        paint.strokeWidth = strokeWidth * 0.8;
        canvas.drawPath(path, paint);
        final rnd = math.Random(42);
        final grainPaint = Paint()..style = PaintingStyle.fill;
        for (var p in points) {
          if (p != null) {
            for (int j = 0; j < 5; j++) {
              grainPaint.color = color.withOpacity(finalOpacity * rnd.nextDouble() * 0.4);
              canvas.drawRect(Rect.fromLTWH(p.dx + (rnd.nextDouble()-0.5)*strokeWidth, p.dy + (rnd.nextDouble()-0.5)*strokeWidth, 2, 2), grainPaint);
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

class ColoringPainter extends CustomPainter {
  final ui.Image? template;
  final List<PaintOp> operations;
  final Color secondaryColor;
  final ui.Image? cachedDrawing;
  final int cachedCount;

  ColoringPainter({this.template, required this.operations, required this.secondaryColor, this.cachedDrawing, this.cachedCount = 0});

  @override
  void paint(Canvas canvas, Size size) {
    if (template == null) {
      // RESİM YOKSA BEYAZ DEĞİL GRİ GÖSTER
      canvas.drawColor(Colors.grey.shade300, BlendMode.src);
      return;
    }
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
  DrawingTool activeTool = DrawingTool.pencil_hb;
  DrawingTool _lastPencilTool = DrawingTool.pencil_hb;
  DrawingTool _lastBrushTool = DrawingTool.sulu_firca;
  double brushWidth = 20.0;
  bool showSubToolMenu = false;
  String? currentMenuType;

  final GlobalKey _repaintBoundaryKey = GlobalKey();
  final TransformationController _transformationController = TransformationController();
  int _pointerCount = 0;

  final List<List<PaintOp>> _undoStack = [];
  final List<List<PaintOp>> _redoStack = [][];

  ui.Image? _cachedDrawing;
  int _lastCachedCount = 0;

  InterstitialAd? _interstitialAd;
  Timer? _adTimer;
  final String _adUnitId = 'ca-app-pub-3940256099942544/1033173712';
  bool _isAdLoading = false;
  bool _isAdFree = false;

  final List<Color> palette = [
    const Color(0xFF000000), const Color(0xFFFFFFFF), const Color(0xFFFF0000),
    const Color(0xFF00FF00), const Color(0xFF0000FF), const Color(0xFFFFFF00),
    const Color(0xFFFFA500), const Color(0xFF800080), const Color(0xFFFFC0CB),
    const Color(0xFFA52A2A), const Color(0xFF808080), const Color(0xFFADD8E6),
    const Color(0xFF90EE90), const Color(0xFFE6E6FA), const Color(0xFFFFFFE0),
    const Color(0xFFF5F5DC), const Color(0xFF800000), const Color(0xFF008000),
    const Color(0xFF000080), const Color(0xFF808000), const Color(0xFFFF4500),
    const Color(0xFF2E8B57), const Color(0xFF1E90FF), const Color(0xFFDA70D6),
    const Color(0xFFB22222), const Color(0xFF00FA9A), const Color(0xFF4169E1),
    const Color(0xFFFFD700), const Color(0xFFD2691E), const Color(0xFF32CD32),
    const Color(0xFF00CED1), const Color(0xFFFF1493), const Color(0xFF8B4513),
    const Color(0xFF7FFF00), const Color(0xFF4682B4), const Color(0xFFEE82EE),
    const Color(0xFFCD853F), const Color(0xFFADFF2F), const Color(0xFF5F9EA0),
    const Color(0xFFDB7093),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCanvas();
  }

  Future<void> _initCanvas() async {
    _isAdFree = await BillingManager.isAdFree();
    if (!_isAdFree) {
      _startAdTimer();
    }
    await _loadTemplate();
    await _loadProgress();
  }

  Future<void> _startAdTimer() async {
    _adTimer?.cancel();
    _adTimer = Timer.periodic(const Duration(seconds: 180), (timer) async {
      final adFree = await BillingManager.isAdFree();
      if (adFree) {
        _isAdFree = true;
        _adTimer?.cancel();
        return;
      }
      if (!kIsWeb) _loadInterstitialAd();
    });
  }

  void _loadInterstitialAd() {
    if (_isAdLoading) return;
    _isAdLoading = true;
    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isAdLoading = false;
          _showInterstitialAd();
        },
        onAdFailedToLoad: (error) {
          debugPrint('InterstitialAd failed to load: \$error');
          _isAdLoading = false;
        },
      ),
    );
  }

  void _showInterstitialAd() {
    if (_interstitialAd == null) return;
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
      },
    );
    _interstitialAd!.show();
  }

  @override
  void dispose() {
    _saveProgress();
    _adTimer?.cancel();
    _interstitialAd?.dispose();
    _transformationController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) _saveProgress();
  }

  Future<dynamic> _getSaveFile() async {
    if (kIsWeb) return null;
    final directory = await getApplicationDocumentsDirectory();
    return File('\${directory.path}/drawing_\${widget.templateId}.json');
  }

  Future<void> _saveProgress() async {
    if (kIsWeb) return;
    try {
      final file = await _getSaveFile();
      final List<Map<String, dynamic>> jsonData = operations.map((op) => op.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonData));
    } catch (e) { debugPrint('Error saving progress: \$e'); }
  }

  Future<void> _loadProgress() async {
    if (kIsWeb) return;
    try {
      final file = await _getSaveFile();
      if (file != null && await file.exists()) {
        final String content = await file.readAsString();
        final List decoded = jsonDecode(content);
        setState(() {
          operations = decoded.map((item) => PathOp.fromJson(item)).toList();
        });
        _updateCache();
      }
    } catch (e) { debugPrint('Error loading progress: \$e'); }
  }

  Future<void> _loadTemplate() async {
    try {
      final ByteData data = await rootBundle.load(widget.assetPath);
      final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final ui.FrameInfo fi = await codec.getNextFrame();
      setState(() { 
        templateImage = fi.image;
        print("✅ RESİM YÜKLENDI: ${widget.assetPath}");
      });
    } catch (e) {
      print("❌ RESİM YÜKLENEMEDI: ${widget.assetPath} - Hata: $e");
      setState(() {
        templateImage = null;
      });
    }
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

  Future<void> _exportToGallery() async {
    try {
      final status = await Permission.storage.request();
      if (!status.isGranted) return;

      RenderRepaintBoundary boundary = _repaintBoundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final result = await ImageGallerySaver.saveImage(pngBytes, name: "color_world_\${DateTime.now().millisecondsSinceEpoch}");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L.imageSaved)));
      }
    } catch (e) {
      debugPrint('Error exporting image: \$e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L.errorSaving)));
      }
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D2D2D)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          L.appTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF2D2D2D),
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo, color: Color(0xFF2D2D2D)),
            onPressed: _undo,
          ),
          IconButton(
            icon: const Icon(Icons.redo, color: Color(0xFF2D2D2D)),
            onPressed: _redo,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: _exportToGallery,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF06D6A0),
                side: const BorderSide(color: Color(0xFF2D2D2D), width: 2),
              ),
              child: Text(
                L.save,
                style: const TextStyle(
                  color: Color(0xFF2D2D2D),
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(4),
          child: SizedBox(
            child: Divider(color: Color(0xFF2D2D2D), height: 4, thickness: 4),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.grey.shade200, // BEYAZ DEĞİL GRİ - RESİM YOKSA GÖRÜRSÜN
              child: templateImage == null
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Resim yükleniyor...',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : Listener(
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
                            aspectRatio: templateImage!.width / templateImage!.height,
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
                                      if (op.points.isNotEmpty &&
                                          op.points.last != null &&
                                          (pixelPos - op.points.last!).distance < 0.5) return;
                                      setState(() {
                                        op.points.add(pixelPos);
                                        op.invalidate();
                                      });
                                    }
                                  },
                                  onPanEnd: (details) {
                                    if (operations.isNotEmpty && operations.last is PathOp) {
                                      (operations.last as PathOp).points.add(null);
                                    }
                                    _updateCache();
                                  },
                                  child: RepaintBoundary(
                                    key: _repaintBoundaryKey,
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
                              },
                            ),
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

  // ============ KONTROLLER ============
  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
      decoration: const BoxDecoration(
        color: Color(0xFFFDFBF7),
        border: Border(top: BorderSide(color: Color(0xFF2D2D2D), width: 4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: showSubToolMenu && currentMenuType != null
                ? _buildSubToolMenu()
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 8),
          _buildStrokeWidthSlider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildToolButton(
                tool: DrawingTool.pencil_hb,
                icon: Icons.edit,
                label: 'Kalem',
                isMenu: true,
              ),
              _buildToolButton(
                tool: DrawingTool.sulu_firca,
                icon: Icons.brush,
                label: 'Fırça',
                isMenu: true,
              ),
              _buildToolButton(
                tool: DrawingTool.eraser,
                icon: Icons.delete_outline,
                label: 'Silgi',
                isMenu: false,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPalette(),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required DrawingTool tool,
    required IconData icon,
    required String label,
    bool isMenu = false,
  }) {
    bool isActive = isMenu
        ? (currentMenuType == label && showSubToolMenu)
        : (activeTool == tool);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isMenu) {
            if (currentMenuType == label) {
              showSubToolMenu = !showSubToolMenu;
            } else {
              showSubToolMenu = true;
              currentMenuType = label;
              if (label == 'Fırça') {
                activeTool = _lastBrushTool;
              } else {
                activeTool = _lastPencilTool;
              }
            }
          } else {
            activeTool = tool;
            showSubToolMenu = false;
            currentMenuType = null;
          }
        });
      },
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFFFD166) : Colors.white,
              border: Border.all(color: const Color(0xFF2D2D2D), width: 3),
              boxShadow: isActive
                  ? null
                  : const [BoxShadow(color: Color(0xFF2D2D2D), offset: Offset(4, 4))],
            ),
            child: Icon(icon, color: const Color(0xFF2D2D2D), size: 28),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildSubToolMenu() {
    if (currentMenuType == null) return const SizedBox.shrink();

    final List<Map<String, dynamic>> subTools;
    if (currentMenuType == 'Kalem') {
      subTools = [
        {'tool': DrawingTool.pencil_hb, 'label': 'HB'},
        {'tool': DrawingTool.kursun, 'label': 'Kurşun'},
        {'tool': DrawingTool.pencil_2b, 'label': '2B'},
        {'tool': DrawingTool.pencil_4b, 'label': '4B'},
        {'tool': DrawingTool.pencil_6b, 'label': '6B'},
        {'tool': DrawingTool.pencil_9b, 'label': '9B'},
        {'tool': DrawingTool.komur, 'label': 'Kömür'},
      ];
    } else if (currentMenuType == 'Fırça') {
      subTools = [
        {'tool': DrawingTool.sulu_firca, 'label': 'Sulu Boya'},
        {'tool': DrawingTool.keceli, 'label': 'Keçeli'},
        {'tool': DrawingTool.firca_classic, 'label': 'Klasik'},
        {'tool': DrawingTool.boya_kalemi, 'label': 'Kuru Fırça'},
        {'tool': DrawingTool.sprey, 'label': 'Sprey'},
        {'tool': DrawingTool.yagli_boya, 'label': 'Yağlı Boya'},
        {'tool': DrawingTool.gradyan_fircasi, 'label': 'Gradyan'},
      ];
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      height: 60,
      margin: const EdgeInsets.only(bottom: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: subTools.length,
        itemBuilder: (context, index) {
          final st = subTools[index];
          final tool = st['tool'] as DrawingTool;
          final isSelected = activeTool == tool;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () {
                setState(() {
                  activeTool = tool;
                  if (currentMenuType == 'Kalem') {
                    _lastPencilTool = tool;
                  } else if (currentMenuType == 'Fırça') {
                    _lastBrushTool = tool;
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFFD166) : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFF2D2D2D), width: 3),
                  boxShadow: isSelected
                      ? null
                      : const [BoxShadow(color: Color(0xFF2D2D2D), offset: Offset(2, 2))],
                ),
                child: Center(
                  child: Text(
                    st['label'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStrokeWidthSlider() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF2D2D2D), width: 3),
        boxShadow: const [BoxShadow(color: Color(0xFF2D2D2D), offset: Offset(4, 4))],
      ),
      child: Row(
        children: [
          Text(
            'Kalınlık',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
          ),
          Expanded(
            child: Slider(
              value: brushWidth,
              min: 2.0,
              max: 100.0,
              activeColor: const Color(0xFF2D2D2D),
              inactiveColor: const Color(0xFF2D2D2D).withOpacity(0.1),
              onChanged: (v) => setState(() => brushWidth = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPalette() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: palette.length,
        itemBuilder: (context, index) {
          final color = palette[index];
          final isSelected = selectedColor == color;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedColor = color;
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF2D2D2D),
                  width: isSelected ? 4 : 2,
                ),
                boxShadow: isSelected
                    ? null
                    : const [BoxShadow(color: Color(0xFF2D2D2D), offset: Offset(2, 2))],
              ),
            ),
          );
        },
      ),
    );
  }
}