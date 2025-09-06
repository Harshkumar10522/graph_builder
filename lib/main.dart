import 'dart:math';

import 'package:flutter/material.dart';

// Data model for a tree node
class Node {
  final int label;
  Node? parent;
  final List<Node> children = [];

  Node({required this.label, this.parent});

  // Add a child node
  Node addChild(int childLabel) {
    final child = Node(label: childLabel, parent: this);
    children.add(child);
    return child;
  }

  // Remove this node from its parent
  void removeFromParent() {
    parent?.children.remove(this);
  }

  // Recursively delete all children
  void deleteSubtree() {
    for (final child in List<Node>.from(children)) {
      child.deleteSubtree();
    }
    children.clear();
    removeFromParent();
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Graph Builder',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.blueGrey[900],
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      home: const MyHomePage(title: 'Graph Builder'),
      debugShowCheckedModeBanner: false,
    );
  }
}
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Node rootNode;
  late Node activeNode;
  int nextLabel = 2;
  final TransformationController _transformationController =
      TransformationController();
  bool _isInitialLayout = true;

  // =======================================================================
  // Layout and Painting Logic
  // =======================================================================

  final Map<Node, Offset> _nodeOffsets = {};
  Size _graphSize = Size.zero;
  static const double nodeDiameter = 64.0;
  static const double horizontalSpacing = 30.0;
  static const double verticalSpacing = 120.0;

  @override
  void initState() {
    super.initState();
    rootNode = Node(label: 1);
    activeNode = rootNode;
    nextLabel = 2;

    // Calculate layout after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateLayouts();
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  // Main method to trigger layout calculation
  void _calculateLayouts() {
    _nodeOffsets.clear();
    _subtreeWidths.clear();
    _calculateSubtreeWidths(rootNode);
    _positionNodeRecursive(rootNode, 0);

    // Normalize positions to be non-negative and calculate total graph size
    double minX = double.infinity, maxX = double.negativeInfinity;
    double minY = double.infinity, maxY = double.negativeInfinity;

    if (_nodeOffsets.isEmpty) {
      setState(() {
        _graphSize = Size.zero;
      });
      return;
    }

    for (var offset in _nodeOffsets.values) {
      minX = min(minX, offset.dx);
      maxX = max(maxX, offset.dx + nodeDiameter);
      minY = min(minY, offset.dy);
      maxY = max(maxY, offset.dy + nodeDiameter);
    }

    final double shiftX =
        (minX < 0) ? -minX + horizontalSpacing : horizontalSpacing;
    final double shiftY = (minY < 0) ? -minY : 0.0;

    final shiftedOffsets = <Node, Offset>{};
    for (var entry in _nodeOffsets.entries) {
      shiftedOffsets[entry.key] = entry.value.translate(shiftX, shiftY);
    }
    _nodeOffsets.clear();
    _nodeOffsets.addAll(shiftedOffsets);

    setState(() {
      _graphSize = Size(
        max(0, (maxX - minX) + horizontalSpacing * 2),
        max(0, (maxY - minY) + verticalSpacing), // Add padding for bottom
      );
    });

    // Center the view after the layout is calculated, only on the first run
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isInitialLayout && mounted) {
        _centerView();
        _isInitialLayout = false;
      }
    });
  }

  void _centerView() {
    if (!mounted || _graphSize == Size.zero) return;
    final screenSize = MediaQuery.of(context).size;
    final screenCenter = Offset(screenSize.width / 2, screenSize.height / 2);

    final firstNodeOffset = _nodeOffsets[rootNode] ?? Offset.zero;
    final nodeCenter =
        firstNodeOffset.translate(nodeDiameter / 2, nodeDiameter / 2);

    final translation = screenCenter - nodeCenter;
    final matrix = Matrix4.identity()..translate(translation.dx, translation.dy);
    _transformationController.value = matrix;
  }

  final Map<Node, double> _subtreeWidths = {};
  double _calculateSubtreeWidths(Node node) {
    if (_subtreeWidths.containsKey(node)) return _subtreeWidths[node]!;
    if (node.children.isEmpty) {
      _subtreeWidths[node] = nodeDiameter;
      return nodeDiameter;
    }
    double width = 0;
    for (var child in node.children) {
      width += _calculateSubtreeWidths(child);
    }
    width += (node.children.length - 1) * horizontalSpacing;
    _subtreeWidths[node] = max(nodeDiameter, width);
    return _subtreeWidths[node]!;
  }

  void _positionNodeRecursive(Node node, double startX) {
    final double y = _getNodeDepth(node) * verticalSpacing;
    final double subtreeWidth = _subtreeWidths[node]!;
    final double x = startX + (subtreeWidth / 2) - (nodeDiameter / 2);
    _nodeOffsets[node] = Offset(x, y);

    double childStartX = startX;
    for (var child in node.children) {
      _positionNodeRecursive(child, childStartX);
      childStartX += _subtreeWidths[child]! + horizontalSpacing;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey[900],
        title: Text(widget.title),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blueGrey[800],
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Text(
                  'Depth: ${_getNodeDepth(activeNode) + 1}/100',
                  style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          InteractiveViewer(
            transformationController: _transformationController,
            constrained: false,
            boundaryMargin: const EdgeInsets.all(double.infinity),
            minScale: 0.1,
            maxScale: 2.0,
            child: SizedBox.fromSize(
              size: _graphSize,
              child: Stack(
                children: [
                  // Painter for the lines
                  CustomPaint(
                    size: _graphSize,
                    painter: _TreeLayoutPainter(
                      offsets: _nodeOffsets,
                      nodeDiameter: nodeDiameter,
                      verticalSpacing: verticalSpacing,
                    ),
                  ),
                  // Positioned widgets for the nodes
                  ..._nodeOffsets.entries.map((entry) {
                    final node = entry.key;
                    final offset = entry.value;
                    return Positioned(
                      left: offset.dx,
                      top: offset.dy,
                      width: nodeDiameter,
                      height: nodeDiameter,
                      child: _buildNodeWidget(node),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          // UI Controls
          Positioned(
            bottom: 32,
            right: 32,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700]?.withOpacity(0.8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
              onPressed: () {
                if (_getNodeDepth(activeNode) < 100) {
                  setState(() {
                    activeNode.addChild(nextLabel++);
                    _calculateLayouts();
                  });
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Node'),
            ),
          ),
        ],
      ),
    );
  }

  // Builds the circular widget for a single node.
  Widget _buildNodeWidget(Node node) {
    return GestureDetector(
      onTap: () {
        setState(() {
          activeNode = node;
        });
      },
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: nodeDiameter,
            height: nodeDiameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: node == activeNode ? Colors.blue[400] : Colors.blueGrey[200],
              border: Border.all(
                color: node == activeNode ? Colors.blueAccent : Colors.blueGrey[400]!,
                width: node == activeNode ? 4 : 2,
              ),
              boxShadow: [
                if (node == activeNode)
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: Center(
              child: Text(
                node.label.toString(),
                style: TextStyle(
                  color: node == activeNode ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ),
          ),
          if (node != rootNode)
            Positioned(
              top: -4,
              right: -4,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    Node? parent = node.parent;
                    node.deleteSubtree();
                    if (parent != null) {
                      activeNode = parent;
                    } else {
                      activeNode = rootNode;
                    }
                    _calculateLayouts();
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red[400],
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(Icons.close, size: 18, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Helper to get node depth
  int _getNodeDepth(Node node) {
    int depth = 0;
    Node? current = node;
    while (current?.parent != null) {
      depth++;
      current = current?.parent;
    }
    return depth;
  }
}

// New painter that draws the entire tree based on calculated offsets.
class _TreeLayoutPainter extends CustomPainter {
  final Map<Node, Offset> offsets;
  final double nodeDiameter;
  final double verticalSpacing;
  final Paint linePaint;

  _TreeLayoutPainter({
    required this.offsets,
    required this.nodeDiameter,
    required this.verticalSpacing,
  }) : linePaint = Paint()
          ..color = Colors.white70
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    final nodeRadius = nodeDiameter / 2;

    for (var entry in offsets.entries) {
      final node = entry.key;
      if (node.children.isEmpty) continue;

      final parentOffset = entry.value;
      if (parentOffset == null) continue;

      final parentBottomCenter = parentOffset.translate(nodeRadius, nodeDiameter);

      final childrenOffsets = node.children.map((c) => offsets[c]).where((o) => o != null).cast<Offset>().toList();
      if (childrenOffsets.isEmpty) continue;

      // Y position for the horizontal connector line, halfway between parent and child rows.
      final horizontalLineY = parentBottomCenter.dy + (verticalSpacing - nodeDiameter) / 2;

      // 1. Draw vertical line from parent down to the horizontal line
      canvas.drawLine(
        parentBottomCenter,
        Offset(parentBottomCenter.dx, horizontalLineY),
        linePaint,
      );

      if (childrenOffsets.length == 1) {
        // 2a. For a single child, just connect the parent's vertical line to the child's vertical line.
        final childOffset = childrenOffsets.first;
        final childTopCenter = childOffset.translate(nodeRadius, 0);
        canvas.drawLine(
          Offset(parentBottomCenter.dx, horizontalLineY),
          Offset(childTopCenter.dx, horizontalLineY),
          linePaint,
        );
        canvas.drawLine(
          Offset(childTopCenter.dx, horizontalLineY),
          childTopCenter,
          linePaint,
        );
      } else {
        // 2b. For multiple children, find the horizontal extent and draw the line.
        final firstChildCenter = childrenOffsets.first.translate(nodeRadius, 0);
        final lastChildCenter = childrenOffsets.last.translate(nodeRadius, 0);

        canvas.drawLine(
          Offset(firstChildCenter.dx, horizontalLineY),
          Offset(lastChildCenter.dx, horizontalLineY),
          linePaint,
        );

        // 3. Draw vertical lines from horizontal line to each child.
        for (var childOffset in childrenOffsets) {
          final childTopCenter = childOffset.translate(nodeRadius, 0);
          canvas.drawLine(
            Offset(childTopCenter.dx, horizontalLineY),
            childTopCenter,
            linePaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TreeLayoutPainter oldDelegate) {
    return oldDelegate.offsets != offsets ||
        oldDelegate.nodeDiameter != nodeDiameter ||
        oldDelegate.verticalSpacing != verticalSpacing;
  }
}
