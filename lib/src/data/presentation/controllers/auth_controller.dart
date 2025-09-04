import 'package:checkin_app/src/domain/repositories/auth_repository.dart';
import 'package:get/get.dart';

class AuthController extends GetxController {
  final AuthRepository _auth;
  AuthController(this._auth);

  final userId = RxnString();

  @override
  void onInit() {
    super.onInit();
    _auth.authStateChanges().listen((uid) => userId.value = uid);
  }

  Future<void> ensureSignedIn() async {
    if (_auth.currentUserId() == null) {
      await _auth.signInAnonymously();
    }
  }
}
