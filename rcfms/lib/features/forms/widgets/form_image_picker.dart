import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/supabase_config.dart';

import '../../../core/utils/responsive.dart';
import '../../../core/widgets/custom_error_dialog.dart';

class FormImagePicker extends StatefulWidget {
  final String label;
  final String? value;
  final Function(String) onChanged;
  final bool readOnly;
  final String bucketName;

  const FormImagePicker({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.readOnly = false,
    this.bucketName = SupabaseConfig.documentsBucket,
  });

  @override
  State<FormImagePicker> createState() => _FormImagePickerState();
}

class _FormImagePickerState extends State<FormImagePicker> {
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    if (widget.readOnly) return;

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
        maxWidth: 1024,
      );

      if (image == null) return;

      setState(() => _isUploading = true);

      // Check if we are on web or mobile/desktop
      // For Windows (target OS), File is supported.

      final bytes = await image.readAsBytes();
      final fileExt = image.path.split('.').last.toLowerCase();
      final fileName =
          'form_uploads/${DateTime.now().millisecondsSinceEpoch}_${image.name.replaceAll(RegExp(r'[^a-zA-Z0-9.]'), '_')}';

      final contentType = fileExt == 'png' ? 'image/png' : 'image/jpeg';

      await Supabase.instance.client.storage
          .from(widget.bucketName)
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: true,
            ),
          );

      final imageUrl = Supabase.instance.client.storage
          .from(widget.bucketName)
          .getPublicUrl(fileName);

      if (mounted) {
        widget.onChanged(imageUrl);
      }
    } catch (e) {
      if (mounted) {
        CustomErrorDialog.show(context,
            title: 'Upload Failed',
            error: e,
            message: 'Error uploading image.');
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screen = ScreenInfo.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: screen.value(mobile: 12.0, tablet: 14.0, desktop: 16.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: TextStyle(
              fontSize: screen.value(mobile: 14.0, tablet: 15.0, desktop: 16.0),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _buildContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isUploading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.value != null && widget.value!.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: widget.value!,
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(),
              ),
              errorWidget: (context, url, error) => const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.red),
                  SizedBox(height: 4),
                  Text('Failed to load', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
          if (!widget.readOnly)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_a_photo,
          size: 48,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 8),
        Text(
          widget.readOnly ? 'No photo' : 'Tap to upload photo',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
