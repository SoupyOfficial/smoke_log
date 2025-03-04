import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/auth_service.dart';
import '../services/credential_service.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn(
    clientId:
        '660497517730-an04u70e9dfg71meco3ev6gvcri684hk.apps.googleusercontent.com',
  );
});

final credentialServiceProvider = Provider<CredentialService>((ref) {
  return CredentialService();
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.watch(firebaseAuthProvider),
    ref.watch(googleSignInProvider),
    ref.watch(credentialServiceProvider),
  );
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final userAuthTypeProvider = StreamProvider<String>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges().map((user) {
    if (user == null) return 'none';
    // Check if the user's providers list contains Google
    final isGoogleUser = user.providerData
        .any((provider) => provider.providerId == 'google.com');
    return isGoogleUser ? 'google' : 'password';
  });
});
