import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authServiceProvider = Provider((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    await cred.user?.updateDisplayName(displayName);
    return cred;
  }

  Future<UserCredential> signIn(
      {required String email, required String password}) async {
    final cred = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    if (cred.user != null) {
      await _db.collection('users').doc(cred.user!.uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    }
    return cred;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<String> getUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return 'buyer';
    final token = await user.getIdTokenResult(true);
    return (token.claims?['role'] as String?) ?? 'buyer';
  }

  Future<String?> getBusinessId() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final token = await user.getIdTokenResult(true);
    return token.claims?['businessId'] as String?;
  }

  Future<void> refreshToken() async {
    await _auth.currentUser?.getIdToken(true);
  }
}
