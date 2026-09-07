import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/secrets.dart';

class CloudinaryService {
  Future<String?> uploadImage(File file, {String folder = 'general'}) async {
    print('--- Cloudinary Direct Upload Start ---');
    try {
      final fileSize = await file.length();
      print('File Path: ${file.path}');
      print('File Size: ${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB');
      print('Cloud Name: ${AppSecrets.cloudinaryCloudName}');
      print('Upload Preset: ${AppSecrets.cloudinaryUploadPreset}');

      final url = Uri.parse('https://api.cloudinary.com/v1_1/${AppSecrets.cloudinaryCloudName}/image/upload');
      
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = AppSecrets.cloudinaryUploadPreset
        ..fields['folder'] = folder
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = utf8.decode(responseData);
      
      // محاولة تحليل استجابة JSON للخطأ إن وجدت
      Map<String, dynamic> jsonResponse = {};
      try {
        jsonResponse = jsonDecode(responseString);
      } catch (_) {}

      if (response.statusCode == 200) {
        final secureUrl = jsonResponse['secure_url'];
        print('Upload Success! URL: $secureUrl');
        print('--- Cloudinary Direct Upload End ---');
        return secureUrl;
      } else {
        print('Upload Failed with status: ${response.statusCode}');
        // طباعة رسالة الخطأ الواردة من Cloudinary بوضوح
        final errorMessage = jsonResponse['error']?['message'] ?? responseString;
        print('Cloudinary Error Message: $errorMessage');
        print('--- Cloudinary Direct Upload End ---');
        return null;
      }
    } catch (e, stackTrace) {
      print('Unexpected Upload Error: $e');
      print('StackTrace: $stackTrace');
      print('--- Cloudinary Direct Upload End ---');
      return null;
    }
  }
}