import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// A reusable dialog that captures a digital signature via drawing or image upload.
/// Returns [Uint8List] PNG bytes on confirm, or null on cancel.
class SignaturePadDialog extends StatefulWidget {
  final String title;

  const SignaturePadDialog({
    super.key,
    this.title = 'Capture Signature',
  });

  /// Show the dialog and return the captured PNG bytes, or null if cancelled.
  static Future<Uint8List?> show(
    BuildContext context, {
    String title = 'Capture Signature',
  }) {
    return showDialog<Uint8List?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SignaturePadDialog(title: title),
    );
  }

  @override
  State<SignaturePadDialog> createState() => _SignaturePadDialogState();
}

class _SignaturePadDialogState extends State<SignaturePadDialog> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  bool _hasSignature = false;
  Uint8List? _uploadedImageBytes;
  final ImagePicker _picker = ImagePicker();
  final GlobalKey _padKey = GlobalKey();

  // ── Drawing handlers ──

  void _onPanStart(DragStartDetails details) {
    if (_uploadedImageBytes != null) return;

    final RenderBox? box =
        _padKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final local = details.localPosition;
    final normalized = Offset(
      local.dx / box.size.width,
      local.dy / box.size.height,
    );

    setState(() {
      _currentStroke = [normalized];
      _hasSignature = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_uploadedImageBytes != null) return;

    final RenderBox? box =
        _padKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final local = details.localPosition;
    final normalized = Offset(
      local.dx / box.size.width,
      local.dy / box.size.height,
    );

    setState(() {
      _currentStroke = [..._currentStroke, normalized];
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_uploadedImageBytes != null) return;
    setState(() {
      _strokes.add(_currentStroke);
      _currentStroke = [];
    });
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _currentStroke = [];
      _hasSignature = false;
      _uploadedImageBytes = null;
    });
  }

  // ── Image upload ──

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 400,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _uploadedImageBytes = bytes;
          _hasSignature = true;
          _strokes.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  // ── Export drawn strokes to PNG ──

  Future<Uint8List?> _exportSignature(Size size) async {
    if (_strokes.isEmpty) return null;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Transparent background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.transparent,
    );

    final strokeScale = size.width / 400.0;
    final strokeWidth = 2.2 * strokeScale;

    final paint = Paint()
      ..color = AppColors.textPrimary
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in _strokes) {
      if (stroke.isEmpty) continue;
      final path = Path();
      var p0 = Offset(
        stroke.first.dx * size.width,
        stroke.first.dy * size.height,
      );
      path.moveTo(p0.dx, p0.dy);

      for (int i = 0; i < stroke.length - 1; i++) {
        p0 = Offset(
          stroke[i].dx * size.width,
          stroke[i].dy * size.height,
        );
        final p1 = Offset(
          stroke[i + 1].dx * size.width,
          stroke[i + 1].dy * size.height,
        );
        path.quadraticBezierTo(
          p0.dx,
          p0.dy,
          (p0.dx + p1.dx) / 2,
          (p0.dy + p1.dy) / 2,
        );
      }

      final last = Offset(
        stroke.last.dx * size.width,
        stroke.last.dy * size.height,
      );
      path.lineTo(last.dx, last.dy);
      canvas.drawPath(path, paint);
    }

    final picture = recorder.endRecording();
    final image =
        await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  // ── Confirm ──

  Future<void> _confirm() async {
    Uint8List? bytes;

    if (_uploadedImageBytes != null) {
      bytes = _uploadedImageBytes;
    } else {
      final renderBox =
          _padKey.currentContext?.findRenderObject() as RenderBox?;
      final size = renderBox?.size ?? const Size(400, 200);
      bytes = await _exportSignature(size);
    }

    if (bytes != null && mounted) {
      Navigator.of(context).pop(bytes);
    }
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Text(
                widget.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Draw a signature below or upload an image.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),

              // Signature pad
              AspectRatio(
                aspectRatio: 2.5,
                child: Container(
                  key: _padKey,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(
                      color: _hasSignature
                          ? AppColors.primary
                          : Theme.of(context).dividerColor,
                      width: _hasSignature ? 2 : 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm - 1),
                    child: Stack(
                      children: [
                        // Drawing area or uploaded image
                        Positioned.fill(
                          child: _uploadedImageBytes != null
                              ? Center(
                                  child: Image.memory(
                                    _uploadedImageBytes!,
                                    fit: BoxFit.contain,
                                  ),
                                )
                              : GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onPanStart: _onPanStart,
                                  onPanUpdate: _onPanUpdate,
                                  onPanEnd: _onPanEnd,
                                  child: RepaintBoundary(
                                    child: CustomPaint(
                                      painter: _SignaturePainter(
                                        strokes: _strokes,
                                        currentStroke: _currentStroke,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                        ),

                        // Placeholder
                        if (!_hasSignature)
                          Center(
                            child: IgnorePointer(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.gesture,
                                      size: 36,
                                      color: Theme.of(context).hintColor),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Draw signature here',
                                    style: TextStyle(
                                      color: Theme.of(context).hintColor,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Clear button
                        if (_hasSignature)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Material(
                              color: AppColors.surface,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusXs),
                              child: InkWell(
                                onTap: _clear,
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusXs),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.radiusXs),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.refresh,
                                          size: 14,
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.color),
                                      const SizedBox(width: 4),
                                      Text('Clear',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Upload option
              Center(
                child: TextButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: const Text('Upload Signature Image'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _hasSignature ? _confirm : null,
                    child: const Text('Confirm'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Painter (same logic as SetupSignatureScreen) ──

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;
  final Color color;

  _SignaturePainter({
    required this.strokes,
    required this.currentStroke,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final strokeScale = size.width / 400.0;
    final strokeWidth = 2.2 * strokeScale;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    void drawStroke(List<Offset> stroke) {
      if (stroke.isEmpty) return;
      if (stroke.first.dx > 1.2 || stroke.first.dy > 1.2) return;

      final path = Path();
      var p0 =
          Offset(stroke.first.dx * size.width, stroke.first.dy * size.height);
      path.moveTo(p0.dx, p0.dy);

      for (int i = 0; i < stroke.length - 1; i++) {
        p0 = Offset(stroke[i].dx * size.width, stroke[i].dy * size.height);
        final p1 = Offset(
            stroke[i + 1].dx * size.width, stroke[i + 1].dy * size.height);
        path.quadraticBezierTo(
          p0.dx,
          p0.dy,
          (p0.dx + p1.dx) / 2,
          (p0.dy + p1.dy) / 2,
        );
      }

      final last =
          Offset(stroke.last.dx * size.width, stroke.last.dy * size.height);
      path.lineTo(last.dx, last.dy);
      canvas.drawPath(path, paint);
    }

    for (final stroke in strokes) {
      drawStroke(stroke);
    }
    drawStroke(currentStroke);
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) {
    return oldDelegate.strokes.length != strokes.length ||
        oldDelegate.currentStroke.length != currentStroke.length ||
        oldDelegate.color != color;
  }
}
