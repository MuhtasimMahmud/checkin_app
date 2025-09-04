import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  FirebaseFirestore get db => _db;
  DocumentReference<Map<String, dynamic>> doc(String path) => _db.doc(path);
  CollectionReference<Map<String, dynamic>> col(String path) =>
      _db.collection(path);
}
