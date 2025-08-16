import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    // Create user with email and password
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Save user data to Firestore
    await _firestore.collection('users').doc(userCredential.user!.uid).set({
      'username': username,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
      'uid': userCredential.user!.uid,
    });

    return userCredential;
  }

  static Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  static Future<void> signOut() {
    return _auth.signOut();
  }

  static Future<DocumentSnapshot?> getUserData(String uid) {
    return _firestore.collection('users').doc(uid).get();
  }

  static Future<void> saveFinancialProfile({
    required String uid,
    required double currentIncome,
    required String financialStatus,
    required double familyIncome,
    double? debt,
    required String maritalStatus,
    required bool isParent,
    required String financialGoals,
  }) async {
    final data = {
      'currentIncome': currentIncome,
      'financialStatus': financialStatus,
      'familyIncome': familyIncome,
      'maritalStatus': maritalStatus,
      'isParent': isParent,
      'financialGoals': financialGoals,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (debt != null) {
      data['debt'] = debt;
    }
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('financial_profile')
        .doc('profile')
        .set(data);
  }
}
