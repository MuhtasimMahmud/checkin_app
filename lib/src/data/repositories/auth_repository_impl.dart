import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final _auth = FirebaseAuth.instance;

  @override
  String? currentUserId() => _auth.currentUser?.uid;

  @override
  Stream<String?> authStateChanges() =>
      _auth.authStateChanges().map((u) => u?.uid);

  @override
  Future<void> signInAnonymously() async {
    await _auth.signInAnonymously();
  }
}
