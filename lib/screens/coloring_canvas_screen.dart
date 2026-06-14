import 'package:flutter/material.dart';

class ColoringCanvasScreen extends StatefulWidget {
  final String imagePath;
  final String title;

  const ColoringCanvasScreen({
    Key? key,
    required this.imagePath,
    required this.title,
  }) : super(key: key);

  @override
  State<ColoringCanvasScreen> createState() => _ColoringCanvasScreenState();
}

class _ColoringCanvasScreenState extends State<ColoringCanvasScreen> {
  Color _selectedColor = Colors.red;
  final List<Color> _palette = [
    Colors.red,
    Colors.pink,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.brown,
    Colors.black,
    Colors.white,
  ];

  // Placeholder drawing action history
  final List<String> _history = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: const Color(0xFFFDFBF7),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo, color: Colors.black),
            onPressed: _history.isEmpty
                ? null
                : () {
                    setState(() {
                      _history.removeLast();
                    });
                  },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: Container(color: Colors.black, height: 4.0),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              maxScale: 5.0,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: AspectRatio(
                    aspectRatio: 9 / 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black, width: 3.0),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Image.asset(
                              widget.imagePath,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(Icons.image_not_supported, size: 80, color: Colors.black38),
                                );
                              },
                            ),
                          ),
                          // Future tap-to-fill or drawing canvas layer will sit here
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            color: Colors.black,
            height: 4.0,
          ),
          Container(
            color: const Color(0xFFF0EDE5),
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
            child: Column(
              children: [
                const Text(
                  'PALETTE',
                  style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 12.0),
                ),
                const SizedBox(height: 10.0),
                SizedBox(
                  height: 50.0,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _palette.length,
                    itemBuilder: (context, index) {
                      final color = _palette[index];
                      final isSelected = _selectedColor == color;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedColor = color;
                          });
                        },
                        child: Container(
                          width: 40.0,
                          margin: const EdgeInsets.symmetric(horizontal: 6.0),
                          decoration: BoxDecoration(
                            color: color,
                            border: Border.all(
                              color: isSelected ? Colors.black : Colors.black38,
                              width: isSelected ? 3.0 : 1.5,
                            ),
                            boxShadow: isSelected
                                ? const [BoxShadow(color: Colors.black26, offset: Offset(2, 2))]
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
