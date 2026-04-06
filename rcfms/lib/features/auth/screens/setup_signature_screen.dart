import 'dart:convert';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';

import 'package:image_picker/image_picker.dart';

class SetupSignatureScreen extends StatefulWidget {
  const SetupSignatureScreen({super.key});

  @override
  State<SetupSignatureScreen> createState() => _SetupSignatureScreenState();
}

class _SetupSignatureScreenState extends State<SetupSignatureScreen> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  bool _isSaving = false;
  bool _hasSignature = false;
  Uint8List? _uploadedSignatureBytes; // Added for uploaded image
  final ImagePicker _picker = ImagePicker(); // Added ImagePicker
  final GlobalKey _padKey = GlobalKey(); // Added GlobalKey

  void _onPanStart(DragStartDetails details) {
    if (_uploadedSignatureBytes != null) return;

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
    if (_uploadedSignatureBytes != null) return;

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
    if (_uploadedSignatureBytes != null) return;
    setState(() {
      _strokes.add(_currentStroke);
      _currentStroke = [];
    });
  }

  void _clearSignature() {
    setState(() {
      _strokes.clear();
      _currentStroke = [];
      _hasSignature = false;
      _uploadedSignatureBytes = null; // Clear uploaded image
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800, // Limit size
        maxHeight: 400,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _uploadedSignatureBytes = bytes;
          _hasSignature = true;
          _strokes.clear(); // Clear any drawing
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

  Future<Uint8List?> _exportSignature(Size size) async {
    if (_strokes.isEmpty) return null;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Transparent background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.transparent,
    );

    // Draw strokes
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
      // Denormalize the first point
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

  Future<void> _saveSignature() async {
    if (!_hasSignature ||
        (_uploadedSignatureBytes == null && _strokes.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please draw or upload your signature first'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      Uint8List? bytes;

      if (_uploadedSignatureBytes != null) {
        bytes = _uploadedSignatureBytes;
      } else {
        // Get the actual signature pad size using the GlobalKey
        final renderBox =
            _padKey.currentContext?.findRenderObject() as RenderBox?;
        final size = renderBox?.size ?? const Size(400, 200);

        debugPrint('[Signature] Exporting signature with size: $size');
        bytes = await _exportSignature(size);
      }

      if (bytes == null) {
        throw Exception('Failed to export signature image');
      }

      debugPrint('[Signature] Exported ${bytes.length} bytes');

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('Not authenticated. Please log in again.');
      }

      debugPrint('[Signature] Uploading for user: ${user.id}');

      // Upload to Supabase Storage
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = 'signature_${user.id}_$timestamp.png';

      try {
        // Try to upload with upsert
        await Supabase.instance.client.storage.from('signatures').uploadBinary(
              uniqueFileName,
              bytes,
              fileOptions: const FileOptions(
                contentType: 'image/png',
                upsert: true,
              ),
            );
        debugPrint('[Signature] Upload successful');
      } catch (storageError) {
        debugPrint('[Signature] Storage error: $storageError');

        // If storage bucket doesn't exist or RLS issue, skip storage and encode as base64
        final base64Signature = 'data:image/png;base64,${base64Encode(bytes)}';
        debugPrint('[Signature] Using base64 fallback');

        // Update profile with base64 signature directly
        // Update profile with base64 signature using helper
        await _updateProfileSignature(user.id, base64Signature);

        if (mounted) {
          // Update the auth state with the new signature URL directly
          final currentState = context.read<AuthBloc>().state;
          if (currentState is AuthAuthenticated) {
            final updatedUser =
                currentState.user.copyWith(signatureUrl: base64Signature);
            context.read<AuthBloc>().add(AuthUserUpdated(updatedUser));
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Signature saved successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          // Navigate back
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            context.go('/dashboard');
          }
        }
        return;
      }

      // Get public URL
      final signatureUrl = Supabase.instance.client.storage
          .from('signatures')
          .getPublicUrl(uniqueFileName);

      debugPrint('[Signature] URL: $signatureUrl');

      // Update user profile
      // Update user profile using helper
      await _updateProfileSignature(user.id, signatureUrl);

      debugPrint('[Signature] Profile updated successfully');

      if (mounted) {
        // Update the auth state with the new signature URL directly
        final currentState = context.read<AuthBloc>().state;
        if (currentState is AuthAuthenticated) {
          final updatedUser =
              currentState.user.copyWith(signatureUrl: signatureUrl);
          context.read<AuthBloc>().add(AuthUserUpdated(updatedUser));
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signature saved successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        // Navigate back
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          context.go('/dashboard');
        }
      }
    } catch (e) {
      debugPrint('[Signature] Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _updateProfileSignature(
      String userId, String signatureUrl) async {
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'signature_url': signatureUrl}).eq('id', userId);
    } catch (e) {
      debugPrint(
          '[Signature] Standard update failed: $e. Using backend fallback...');
      try {
        final response = await http.post(
          Uri.parse('http://127.0.0.1:5000/api/update-signature'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': userId,
            'signature_url': signatureUrl,
          }),
        );

        if (response.statusCode != 200) {
          throw Exception('Backend failed: ${response.body}');
        }
        debugPrint('[Signature] Backend update successful');
      } catch (backendError) {
        throw Exception(
            'All update methods failed. Main: $e, Backend: $backendError');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/dashboard');
            }
          },
        ),
        title: const Text('Setup Signature'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                'Create your digital signature',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Draw your signature below. This will be used to sign forms electronically.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
              ),
              const SizedBox(height: 32),

              // Signature pad
              Expanded(
                child: Container(
                  key: _padKey,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: _hasSignature
                          ? AppColors.primary
                          : Theme.of(context).dividerColor,
                      width: _hasSignature ? 2 : 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd - 1),
                    child: Stack(
                      children: [
                        // Drawing area or Image
                        Positioned.fill(
                          child: _uploadedSignatureBytes != null
                              ? Center(
                                  child: Image.memory(
                                    _uploadedSignatureBytes!,
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
                                        color: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.color ??
                                            AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                        ),

                        // Placeholder text
                        if (!_hasSignature && _uploadedSignatureBytes == null)
                          Center(
                            child: IgnorePointer(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.gesture,
                                    size: 48,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Draw your signature here',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.color,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Clear button
                        if (_hasSignature)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Material(
                              color: AppColors.surface,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusSm),
                              child: InkWell(
                                onTap: _clearSignature,
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusSm),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.radiusSm),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.refresh,
                                        size: 16,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.color,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Clear',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium,
                                      ),
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
              const SizedBox(height: 16),

              // Upload Button
              Center(
                child: TextButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload Signature Image'),
                ),
              ),

              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.go('/dashboard'),
                      child: const Text('Skip for now'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveSignature,
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save Signature'),
                    ),
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
    // Guards to avoid painting if size is invalid
    if (size.width <= 0 || size.height <= 0) return;

    final strokeScale = size.width / 400.0;
    final strokeWidth = 2.2 * strokeScale;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Draw completed strokes
    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      final path = Path();

      // Data migration check: If coordinate looks absolute (e.g., > 1.2), skip it
      // This prevents legacy pixel-based signatures from exploding on smaller screens
      if (stroke.first.dx > 1.2 || stroke.first.dy > 1.2) continue;

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

    // Draw current stroke
    if (currentStroke.isNotEmpty) {
      if (currentStroke.first.dx > 1.2 || currentStroke.first.dy > 1.2) return;

      final path = Path();
      var p0 = Offset(currentStroke.first.dx * size.width,
          currentStroke.first.dy * size.height);
      path.moveTo(p0.dx, p0.dy);

      for (int i = 0; i < currentStroke.length - 1; i++) {
        p0 = Offset(currentStroke[i].dx * size.width,
            currentStroke[i].dy * size.height);
        final p1 = Offset(currentStroke[i + 1].dx * size.width,
            currentStroke[i + 1].dy * size.height);
        path.quadraticBezierTo(
          p0.dx,
          p0.dy,
          (p0.dx + p1.dx) / 2,
          (p0.dy + p1.dy) / 2,
        );
      }

      final last = Offset(currentStroke.last.dx * size.width,
          currentStroke.last.dy * size.height);
      path.lineTo(last.dx, last.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) {
    return oldDelegate.strokes.length != strokes.length ||
        oldDelegate.currentStroke.length != currentStroke.length ||
        oldDelegate.color != color;
  }
}
