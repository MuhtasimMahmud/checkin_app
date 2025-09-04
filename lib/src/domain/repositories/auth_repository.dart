abstract class AuthRepository {
  Future<void> signInAnonymously();
  Stream<String?> authStateChanges();
  String? currentUserId();
}
