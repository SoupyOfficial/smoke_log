import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'credential_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final CredentialService _credentialService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthService(this._auth, this._googleSignIn, this._credentialService);

  Future<void> _ensureUserDocument(UserCredential credential) async {
    final userDoc = _firestore.collection('users').doc(credential.user!.uid);
    final docSnapshot = await userDoc.get();

    if (!docSnapshot.exists) {
      await userDoc.set({
        'email': credential.user!.email,
        'createdAt': FieldValue.serverTimestamp(),
        'authType': credential.credential?.signInMethod ?? 'password',
      });

      // Create default logs collection for new user
      final logsCollection = userDoc.collection('logs');
      final logsSnapshot = await logsCollection.get();

      if (logsSnapshot.docs.isEmpty) {
        // You might want to add some initial logs or leave it empty
        // For now, we'll just ensure the collection exists
      }
    }
  }

  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _ensureUserDocument(credential);
      await _credentialService.addUserAccount(email, password, 'password');

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw Exception('Sign in aborted by user');

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      await _ensureUserDocument(userCredential);
      await _credentialService.addUserAccount(
        googleUser.email,
        null,
        'google',
      );

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> switchAccount(String email) async {
    final accountDetails = await _credentialService.getAccountDetails(email);
    if (accountDetails == null) throw Exception('Account not found');

    if (accountDetails['authType'] == 'google') {
      await signInWithGoogle();
    } else if (accountDetails['authType'] == 'password') {
      final password = accountDetails['password'];
      if (password == null || password.isEmpty) {
        throw Exception('Password not found for account');
      }
      await signInWithEmailAndPassword(email, password);
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut(); // Sign out from Google if signed in
      await _auth.signOut(); // Sign out from Firebase
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('No user found with this email');
      case 'wrong-password':
        return Exception('Wrong password');
      case 'invalid-email':
        return Exception('Invalid email address');
      default:
        return Exception(e.message ?? 'Authentication failed');
    }
  }
}
