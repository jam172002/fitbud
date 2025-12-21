import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';

class ProfileSetupImageSelectionPage extends StatelessWidget {
  final XFile? selectedImageFile;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;

  const ProfileSetupImageSelectionPage({
    super.key,
    required this.selectedImageFile,
    required this.onPickImage,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 60),
            Text(
              'Please select an image for your profile.',
              style: TextStyle(color: XColors.bodyText, fontSize: 12),
            ),
            const SizedBox(height: 16),
            if (selectedImageFile == null)
              GestureDetector(
                onTap: onPickImage,
                child: DottedBorder(
                  options: RectDottedBorderOptions(
                    dashPattern: const [10, 5],
                    strokeWidth: 2,
                    color: XColors.bodyText.withValues(alpha: 0.3),
                  ),
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(color: XColors.secondaryBG),
                    child: Icon(
                      Iconsax.gallery_import,
                      color: XColors.primary.withValues(alpha: 0.5),
                      size: 60,
                    ),
                  ),
                ),
              )
            else
              Center(
                child: Stack(
                  children: [
                    Container(
                      height: 200,
                      width: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: FileImage(File(selectedImageFile!.path)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 6,
                      top: 6,
                      child: GestureDetector(
                        onTap: onRemoveImage,
                        child: Container(
                          decoration: BoxDecoration(
                            color: XColors.secondaryBG.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            LucideIcons.circle_x,
                            color: XColors.danger,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: onPickImage,
                        child: Container(
                          decoration: BoxDecoration(
                            color: XColors.secondaryBG.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit,
                                size: 14,
                                color: XColors.bodyText,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Change',
                                style: TextStyle(
                                  color: XColors.bodyText,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
