import 'dart:async';
import 'dart:io';

class AuraNetworkAuditor {
  final StreamController<bool> _networkShieldController = StreamController<bool>.broadcast();

  Stream<bool> get shieldStateStream => _networkShieldController.stream;

  void toggleNetworkShield(bool active) {
    _networkShieldController.add(active);
  }

  Future<bool> verifyGatewaySafety() async {
    try {
      final addresses = await InternetAddress.lookup('cloudflare.com');
      return addresses.isNotEmpty &&
          addresses.any((address) => address.rawAddress.isNotEmpty);
    } on SocketException {
      return false;
    }
  }
}