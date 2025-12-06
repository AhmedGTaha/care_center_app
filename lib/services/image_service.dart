import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class ImageService {
  // ⚠️ REPLACE THESE WITH YOUR CLOUDINARY CREDENTIALS
  static const String cloudName = "dbjfoekyy";  // Replace this
  static const String uploadPreset = "care_center_uploads";     // Use "ml_default" or create your own
  
  /// Save image - works for both web and mobile
  Future<String> saveImage(XFile imageFile, String folder) async {
    if (kIsWeb) {
      return await _uploadToCloudinary(imageFile, folder);
    } else {
      // For mobile, still save locally
      return await _saveImageMobile(imageFile, folder);
    }
  }

  /// Upload image to Cloudinary (works on web and mobile)
  Future<String> _uploadToCloudinary(XFile imageFile, String folder) async {
    try {
      debugPrint('📤 Starting Cloudinary upload...');
      
      // Read image bytes
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      debugPrint('📸 Image size: ${bytes.length} bytes');
      
      // Cloudinary upload URL
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload'
      );
      
      // Prepare form data
      final request = http.MultipartRequest('POST', url);
      request.fields['upload_preset'] = uploadPreset;
      request.fields['folder'] = folder;
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: '${folder}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );
      
      debugPrint('🚀 Uploading to Cloudinary...');
      
      // Send request with timeout
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Upload timeout - please check your internet connection');
        },
      );
      
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final imageUrl = data['secure_url'] as String;
        debugPrint('✅ Upload successful: $imageUrl');
        return imageUrl;
      } else {
        debugPrint('❌ Upload failed: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        throw Exception('Upload failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Cloudinary upload error: $e');
      rethrow;
    }
  }

  /// Save image on mobile (local storage)
  Future<String> _saveImageMobile(XFile imageFile, String folder) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final targetDir = Directory("${dir.path}/$folder");

      if (!targetDir.existsSync()) {
        targetDir.createSync(recursive: true);
      }

      final outputPath = "${targetDir.path}/${folder}_${DateTime.now().millisecondsSinceEpoch}.jpg";

      final compressed = await FlutterImageCompress.compressAndGetFile(
        imageFile.path,
        outputPath,
        quality: 70,
      );

      return compressed?.path ?? imageFile.path;
    } catch (e) {
      debugPrint('Error saving image on mobile: $e');
      return imageFile.path;
    }
  }

  /// Delete image - only works for mobile local files
  Future<void> deleteImage(String imagePath) async {
    if (kIsWeb) {
      // On web with Cloudinary, we can't delete (or we'd need API key/secret)
      debugPrint('🗑️ Skipping delete on web (Cloudinary images persist)');
      return;
    } else {
      await _deleteImageMobile(imagePath);
    }
  }

  /// Delete image from local storage (mobile)
  Future<void> _deleteImageMobile(String imagePath) async {
    try {
      if (imagePath.isEmpty) return;
      
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting local image: $e');
    }
  }

  /// Get image widget - works for both web and mobile
  Widget getImageWidget(String imagePath, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    String defaultAsset = 'assets/default_equipment.png',
  }) {
    // Handle empty or invalid paths
    if (imagePath.isEmpty) {
      return Image.asset(
        defaultAsset,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            child: const Icon(Icons.image_not_supported),
          );
        },
      );
    }

    // Check if it's a Cloudinary URL or any HTTP URL
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Error loading network image: $error');
          return Image.asset(
            defaultAsset,
            width: width,
            height: height,
            fit: fit,
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            width: width,
            height: height,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      );
    }
    
    // For mobile local files
    if (!kIsWeb) {
      if (!File(imagePath).existsSync()) {
        return Image.asset(
          defaultAsset,
          width: width,
          height: height,
          fit: fit,
        );
      }
      return Image.file(
        File(imagePath),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            defaultAsset,
            width: width,
            height: height,
            fit: fit,
          );
        },
      );
    }
    
    // Fallback
    return Image.asset(
      defaultAsset,
      width: width,
      height: height,
      fit: fit,
    );
  }

  /// Check if image path is valid
  bool isValidImage(String imagePath) {
    if (imagePath.isEmpty) return false;
    
    if (imagePath.startsWith('http')) {
      return true;
    }
    
    if (!kIsWeb && File(imagePath).existsSync()) {
      return true;
    }
    
    return false;
  }
}