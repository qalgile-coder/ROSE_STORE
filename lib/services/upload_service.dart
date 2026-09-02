import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers.dart';

class UploadService {
  final Ref ref;
  final ImagePicker _picker = ImagePicker();
  bool _isPicking = false; // Add a global picking state

  UploadService(this.ref);

  Future<String?> pickAndUploadImage({
    required BuildContext context,
    required String folder,
    ImageSource source = ImageSource.gallery,
  }) async {
    if (_isPicking) return null; // Prevent multiple pickers

    _isPicking = true;
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1000,
      );

      if (image == null) {
        _isPicking = false;
        return null;
      }

      final url = await uploadImage(File(image.path), folder: folder);
      _isPicking = false;
      return url;
    } catch (e) {
      _isPicking = false;
      if (e.toString().contains('already_active')) {
        debugPrint('Image picker is already active.');
      } else {
        debugPrint('Error picking/uploading image: $e');
      }
      return null;
    }
  }

  Future<String?> uploadImage(File file, {required String folder}) async {
    try {
      final cloudinary = ref.read(cloudinaryServiceProvider);
      return await cloudinary.uploadImage(file, folder: folder);
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }
}

final uploadServiceProvider = Provider((ref) => UploadService(ref));
