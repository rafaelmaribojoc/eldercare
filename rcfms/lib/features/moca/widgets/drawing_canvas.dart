import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../constants/moca_colors.dart';

/// Point class for drawing
class DrawPoint {
  final double x;
  final double y;

  const DrawPoint(this.x, this.y);
}

/// Drawing canvas widget for visuospatial tasks
/// Uses RawGestureDetector to prevent gesture conflicts with parent scrolls/swipes
class DrawingCanvas extends StatefulWidget {
  final Function(List<List<DrawPoint>>)? onDrawingChanged;
  final Color strokeColor;
  final double strokeWidth;
  final bool showGuide;
  final Widget? guideWidget;

  const DrawingCanvas({
    super.key,
    this.onDrawingChanged,
    this.strokeColor = MocaColors.primary,
    this.strokeWidth = 3.0,
    this.showGuide = false,
    this.guideWidget,
  });

  @override
  State<DrawingCanvas> createState() => DrawingCanvasState();
}

class DrawingCanvasState extends State<DrawingCanvas> {
  List<List<DrawPoint>> _strokes = [];
  List<DrawPoint> _currentStroke = [];

  /// Clear the canvas
  void clear() {
    setState(() {
      _strokes = [];
      _currentStroke = [];
    });
    widget.onDrawingChanged?.call(_strokes);
  }

  /// Undo last stroke
  void undo() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _strokes = List.from(_strokes)..removeLast();
      });
      widget.onDrawingChanged?.call(_strokes);
    }
  }

  /// Get all strokes
  List<List<DrawPoint>> get strokes => _strokes;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MocaColors.border, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // Guide layer
            if (widget.showGuide && widget.guideWidget != null)
              Positioned.fill(
                child: Opacity(opacity: 0.3, child: widget.guideWidget!),
              ),

            // Drawing layer with RawGestureDetector to prevent gesture conflicts
            Positioned.fill(
              child: RawGestureDetector(
                gestures: <Type, GestureRecognizerFactory>{
                  // Use PanGestureRecognizer with immediate win
                  PanGestureRecognizer: GestureRecognizerFactoryWithHandlers<
                      PanGestureRecognizer>(
                    () => PanGestureRecognizer()
                      ..gestureSettings = const DeviceGestureSettings(
                        touchSlop: 0, // Immediate response
                      ),
                    (PanGestureRecognizer instance) {
                      instance
                        ..onStart = _onPanStart
                        ..onUpdate = _onPanUpdate
                        ..onEnd = _onPanEnd;
                    },
                  ),
                },
                behavior: HitTestBehavior.opaque,
                child: CustomPaint(
                  painter: _DrawingPainter(
                    strokes: _strokes,
                    currentStroke: _currentStroke,
                    strokeColor: widget.strokeColor,
                    strokeWidth: widget.strokeWidth,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _currentStroke = [
        DrawPoint(details.localPosition.dx, details.localPosition.dy),
      ];
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _currentStroke = List.from(_currentStroke)
        ..add(DrawPoint(details.localPosition.dx, details.localPosition.dy));
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentStroke.isNotEmpty) {
      setState(() {
        _strokes = List.from(_strokes)..add(_currentStroke);
        _currentStroke = [];
      });
      widget.onDrawingChanged?.call(_strokes);
    }
  }
}

class _DrawingPainter extends CustomPainter {
  final List<List<DrawPoint>> strokes;
  final List<DrawPoint> currentStroke;
  final Color strokeColor;
  final double strokeWidth;

  _DrawingPainter({
    required this.strokes,
    required this.currentStroke,
    required this.strokeColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // Draw completed strokes
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke, paint);
    }

    // Draw current stroke
    if (currentStroke.isNotEmpty) {
      _drawStroke(canvas, currentStroke, paint);
    }
  }

  void _drawStroke(Canvas canvas, List<DrawPoint> points, Paint paint) {
    if (points.isEmpty) return;

    if (points.length == 1) {
      canvas.drawCircle(
        Offset(points.first.x, points.first.y),
        strokeWidth / 2,
        paint..style = PaintingStyle.fill,
      );
      return;
    }

    final path = Path();
    path.moveTo(points.first.x, points.first.y);

    for (var i = 1; i < points.length; i++) {
      // Use quadratic bezier for smoother lines
      if (i < points.length - 1) {
        final midX = (points[i].x + points[i + 1].x) / 2;
        final midY = (points[i].y + points[i + 1].y) / 2;
        path.quadraticBezierTo(points[i].x, points[i].y, midX, midY);
      } else {
        path.lineTo(points[i].x, points[i].y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.currentStroke != currentStroke;
  }
}
