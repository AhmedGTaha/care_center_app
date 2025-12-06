// This file handles storage for web platform
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';

class WebStorageService {
  final storage = FirebaseStorage.instance;
  
  Future<String> uploadImage(Uint8List imageData, String path) async {
    try {
      final ref = storage.ref().child(path);
      await ref.putData(imageData);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return '';
    }
  }
  
  Future<void> deleteImage(String url) async {
    try {
      final ref = storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      print('Error deleting image: $e');
    }
  }
}