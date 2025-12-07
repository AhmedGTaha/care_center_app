import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../models/equipment_model.dart';
import 'image_service.dart';

class EquipmentService {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final ImageService _imageService = ImageService();
  
  Future<String> saveLocalImage(dynamic file) async {
    if (file is XFile) {
      return await _imageService.saveImage(file, 'equipment');
    }
    final xFile = XFile(file.path);
    return await _imageService.saveImage(xFile, 'equipment');
  }
  
  Future<void> deleteLocalFile(String path) async {
    await _imageService.deleteImage(path);
  }
  
  Future<void> addEquipment(Equipment eq) async {
    final docRef = db.collection("equipment").doc();
    eq.id = docRef.id;

    await docRef.set(eq.toMap());
  }
  
  Future<void> updateEquipment(Equipment eq, {String? oldImagePath}) async {
    if (oldImagePath != null && oldImagePath.isNotEmpty) {
      if (oldImagePath != eq.imagePath) {
        await deleteLocalFile(oldImagePath);
      }
    }

    await db.collection("equipment").doc(eq.id).update(eq.toMap());
  }
  
  Future<void> deleteEquipment(Equipment eq) async {
    if (eq.imagePath.isNotEmpty) {
      await deleteLocalFile(eq.imagePath);
    }

    await db.collection("equipment").doc(eq.id).delete();
  }
  
  Stream<List<Equipment>> getEquipmentStream() {
    return db.collection("equipment").snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Equipment.fromMap(doc.data(), doc.id))
          .toList();
    });
  }
}