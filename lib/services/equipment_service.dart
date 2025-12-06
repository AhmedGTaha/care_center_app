import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/equipment_model.dart';

class EquipmentService {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  
  Future<String> saveLocalImage(File file) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final equipmentDir = Directory("${dir.path}/equipment");

      if (!equipmentDir.existsSync()) {
        equipmentDir.createSync(recursive: true);
      }

      final fileName =
          "eq_${DateTime.now().millisecondsSinceEpoch.toString()}.jpg";

      final savedFile = await file.copy("${equipmentDir.path}/$fileName");

      return savedFile.path;
    } catch (e) {
      debugPrint("SAVE LOCAL IMAGE ERROR: $e");
      return "";
    }
  }
  
  Future<void> deleteLocalFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint("DELETE LOCAL FILE ERROR: $e");
    }
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
