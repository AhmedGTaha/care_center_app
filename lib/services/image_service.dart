import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class ImageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Save image - works for both web and mobile
  Future<String> saveImage(XFile imageFile, String folder) async {
    if (kIsWeb) {
      return await _saveImageWeb(imageFile, folder);
    } else {
      return await _saveImageMobile(imageFile, folder);
    }
  }

  /// Save image on web (upload to Firebase Storage)
  Future<String> _saveImageWeb(XFile imageFile, String folder) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final fileName = '${folder}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('$folder/$fileName');
      
      await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error saving image on web: $e');
      return '';
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

  /// Delete image - works for both web and mobile
  Future<void> deleteImage(String imagePath) async {
    if (kIsWeb) {
      await _deleteImageWeb(imagePath);
    } else {
      await _deleteImageMobile(imagePath);
    }
  }

  /// Delete image from Firebase Storage (web)
  Future<void> _deleteImageWeb(String imageUrl) async {
    try {
      if (imageUrl.isEmpty || !imageUrl.startsWith('http')) return;
      
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      debugPrint('Error deleting image from Firebase: $e');
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
    if (kIsWeb) {
      // On web, use network image for Firebase URLs
      if (imagePath.isEmpty || !imagePath.startsWith('http')) {
        return Image.asset(
          defaultAsset,
          width: width,
          height: height,
          fit: fit,
        );
      }
      return Image.network(
        imagePath,
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
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            width: width,
            height: height,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      );
    } else {
      // On mobile, use file image for local files
      if (imagePath.isEmpty || !File(imagePath).existsSync()) {
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
      );
    }
  }

  /// Check if image path is valid
  bool isValidImage(String imagePath) {
    if (kIsWeb) {
      return imagePath.isNotEmpty && imagePath.startsWith('http');
    } else {
      return imagePath.isNotEmpty && File(imagePath).existsSync();
    }
  }
}