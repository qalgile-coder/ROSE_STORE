import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers.dart';

class UploadService {
  final Ref ref;
  final ImagePicker _picker = ImagePicker();
  bool _isPicking = false;

  UploadService(this.ref);

  Future<String?> pickAndUploadImage({
    required BuildContext context,
    required String folder,
    ImageSource source = ImageSource.gallery,
  }) async {
    if (_isPicking) return null;

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

      final url = await uploadFile(file: File(image.path), folder: folder);
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

  // الدالة المطلوبة لمنع خطأ البناء في AddProductScreen
  Future<String?> uploadFile({required File file, required String folder}) async {
    try {
      final cloudinary = ref.read(cloudinaryServiceProvider);
      return await cloudinary.uploadImage(file, folder: folder);
    } catch (e) {
      debugPrint('Error uploading file: $e');
      return null;
    }
  }

  // للإبقاء على التوافقية مع أي استدعاء قديم لـ uploadImage
  Future<String?> uploadImage(File file, {required String folder}) async {
    return uploadFile(file: file, folder: folder);
  }
}

final uploadServiceProvider = Provider((ref) => UploadService(ref));