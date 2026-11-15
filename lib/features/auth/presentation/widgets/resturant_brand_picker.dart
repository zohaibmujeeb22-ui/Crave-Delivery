import 'dart:io';
import 'package:crave_delivery1/app/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Dual image picker for restaurant logo and banner cover preview.
class RestaurantBrandingPicker extends StatelessWidget {
  final File? logoFile;
  final File? coverFile;
  final ValueChanged<File?> onLogoChanged;
  final ValueChanged<File?> onCoverChanged;

  const RestaurantBrandingPicker({
    super.key,
    required this.logoFile,
    required this.coverFile,
    required this.onLogoChanged,
    required this.onCoverChanged,
  });

  Future<void> _pickImage({
    required BuildContext context,
    required ImageSource source,
    required ValueChanged<File?> onPicked,
  }) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        onPicked(File(pickedFile.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Branding & Visuals (Optional)',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 10),

        // 1. Cover Photo Banner Picker (16:9)
        GestureDetector(
          onTap: () => _pickImage(
            context: context,
            source: ImageSource.gallery,
            onPicked: onCoverChanged,
          ),
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E24),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
                width: 1.2,
              ),
              image: coverFile != null
                  ? DecorationImage(
                      image: FileImage(coverFile!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: Stack(
              children: [
                if (coverFile == null)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          color: Colors.white.withOpacity(0.4),
                          size: 28,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Upload Cover Banner (16:9)',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (coverFile != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => onCoverChanged(null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 2. Square Logo Picker (Row layout)
        Row(
          children: [
            GestureDetector(
              onTap: () => _pickImage(
                context: context,
                source: ImageSource.gallery,
                onPicked: onLogoChanged,
              ),
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E24),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                    width: 1.2,
                  ),
                  image: logoFile != null
                      ? DecorationImage(
                          image: FileImage(logoFile!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: logoFile == null
                    ? Icon(
                        Icons.store_outlined,
                        color: Colors.white.withOpacity(0.4),
                        size: 26,
                      )
                    : Align(
                        alignment: Alignment.topRight,
                        child: GestureDetector(
                          onTap: () => onLogoChanged(null),
                          child: Container(
                            margin: const EdgeInsets.all(3),
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Restaurant Logo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Square icon displayed on discovery feeds and order tickets.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
