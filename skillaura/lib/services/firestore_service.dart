import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveUserData(String userType, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(userType).add(data);
    } catch (e) {
      throw Exception('Error saving data: $e');
    }
  }
}
