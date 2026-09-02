import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/secrets.dart';

class CloudinaryService {
  Future<String?> uploadImage(File file, {String folder = 'general'}) async {
    print('--- Cloudinary Direct Upload Start ---');
    final fileSize = await file.length();
    print('File Size: ${fileSize / (1024 * 1024)} MB');
    
    final url = Uri.parse('https://api.cloudinary.com/v1_1/${AppSecrets.cloudinaryCloudName}/image/upload');
    
    try {
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = AppSecrets.cloudinaryUploadPreset
        ..fields['folder'] = folder
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = utf8.decode(responseData);
      final jsonResponse = jsonDecode(responseString);

      if (response.statusCode == 200) {
        print('Upload Success! URL: ${jsonResponse['secure_url']}');
        return jsonResponse['secure_url'];
      } else {
        print('Upload Failed with status: ${response.statusCode}');
        print('Error Response: $responseString');
        return null;
      }
    } catch (e) {
      print('Unexpected Upload Error: $e');
      return null;
    } finally {
      print('--- Cloudinary Direct Upload End ---');
    }
  }
}
