import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Centralized service for Firebase interactions
class FirebaseService {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  FirebaseService._({
    required this.auth,
    required this.firestore,
  });

  static FirebaseService? _instance;

  static FirebaseService get instance {
    if (_instance == null) {
      throw Exception('FirebaseService not initialized');
    }
    return _instance!;
  }

  static Future<FirebaseService> initialize() async {
    if (_instance != null) {
      return _instance!;
    }

    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    _instance = FirebaseService._(
      auth: auth,
      firestore: firestore,
    );

    return _instance!;
  }

  // Get current user ID
  String? get currentUserId => auth.currentUser?.uid;
  
  // Check if user is authenticated
  bool get isAuthenticated => auth.currentUser != null;
  
  // Get user-specific collection reference
  CollectionReference getUserCollection(String collection) {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return firestore.collection('users').doc(userId).collection(collection);
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
    final batch = firestore.batch();
    operations(batch);
    await batch.commit();
  }
  
  // Transaction for atomic operations
  Future<T> performTransaction<T>(
    Future<T> Function(Transaction transaction) transactionFunction,
  ) {
    return firestore.runTransaction(transactionFunction);
  }

  Future<void> signOut() async {
    await auth.signOut();
  }

  Future<void> deleteUser() async {
    final user = auth.currentUser;
    if (user != null) {
      await user.delete();
    }
  }
}
