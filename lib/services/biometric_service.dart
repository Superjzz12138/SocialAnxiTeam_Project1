import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final LocalAuthentication auth = LocalAuthentication();

  static Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate = await auth.isDeviceSupported();
      return canAuthenticateWithBiometrics && canAuthenticate;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> authenticate() async {
    try {
      return await auth.authenticate(
        localizedReason: 'Please authenticate to access Fitness Track',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      print('Biometric authentication error: $e');
      return false;
    }
  }
}