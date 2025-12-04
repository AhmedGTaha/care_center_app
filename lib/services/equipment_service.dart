import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/equipment_model.dart';

class EquipmentService {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  // Upload image to Firebase Storage
  Future<String> uploadImage(File file) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference ref = FirebaseStorage.instance.ref().child("equipment/$fileName");
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  // Add equipment
    // Add equipment with auto generated ID
  Future<void> addEquipment(Equipment eq) async {
    // Create a new document with a random ID
    final docRef = db.collection("equipment").doc();

    await docRef.set(eq.toMap());
  }

  // Update equipment
  Future<void> updateEquipment(Equipment eq) async {
    await db.collection("equipment").doc(eq.id).update(eq.toMap());
  }

  // Delete equipment
  Future<void> deleteEquipment(String id) async {
    await db.collection("equipment").doc(id).delete();
  }

  // Stream list of equipment
  Stream<List<Equipment>> getEquipmentStream() {
    return db.collection("equipment").snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Equipment.fromMap(doc.data(), doc.id))
          .toList();
    });
  }
}