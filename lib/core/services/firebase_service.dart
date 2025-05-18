import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Centralized service for Firebase interactions
class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Auth methods
  FirebaseAuth get auth => _auth;
  
  // Firestore methods
  FirebaseFirestore get firestore => _firestore;
  
  // Storage methods
  FirebaseStorage get storage => _storage;
  
  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;
  
  // Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;
  
  // Get user-specific collection reference
  CollectionReference getUserCollection(String collection) {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    
    return _firestore.collection('users').doc(userId).collection(collection);
  }
  
  // Get document from a user-specific collection
  Future<DocumentSnapshot> getUserDocument(String collection, String documentId) {
    return getUserCollection(collection).doc(documentId).get();
  }
  
  // Add document to a user-specific collection
  Future<DocumentReference> addToUserCollection(String collection, Map<String, dynamic> data) {
    return getUserCollection(collection).add(data);
  }
  
  // Set document in a user-specific collection
  Future<void> setUserDocument(String collection, String documentId, Map<String, dynamic> data, {bool merge = true}) {
    return getUserCollection(collection).doc(documentId).set(data, SetOptions(merge: merge));
  }
  
  // Update document in a user-specific collection
  Future<void> updateUserDocument(String collection, String documentId, Map<String, dynamic> data) {
    return getUserCollection(collection).doc(documentId).update(data);
  }
  
  // Delete document from a user-specific collection
  Future<void> deleteUserDocument(String collection, String documentId) {
    return getUserCollection(collection).doc(documentId).delete();
  }
  
  // Query documents from a user-specific collection
  Query queryUserCollection(String collection) {
    return getUserCollection(collection);
  }
  
  // Get all documents from a user-specific collection
  Future<QuerySnapshot> getAllFromUserCollection(String collection) {
    return getUserCollection(collection).get();
  }
  
  // Stream of all documents from a user-specific collection
  Stream<QuerySnapshot> streamUserCollection(String collection) {
    return getUserCollection(collection).snapshots();
  }
  
  // Stream a specific document from a user-specific collection
  Stream<DocumentSnapshot> streamUserDocument(String collection, String documentId) {
    return getUserCollection(collection).doc(documentId).snapshots();
  }
  
  // Batch write for multiple operations
  Future<void> performBatchOperation(
    Function(WriteBatch batch) operations,
  ) async {
    final batch = _firestore.batch();
    operations(batch);
    await batch.commit();
  }
  
  // Transaction for atomic operations
  Future<T> performTransaction<T>(
    Future<T> Function(Transaction transaction) transactionFunction,
  ) {
    return _firestore.runTransaction(transactionFunction);
  }
}
