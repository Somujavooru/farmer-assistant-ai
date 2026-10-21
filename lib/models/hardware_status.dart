enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  error
}

class DeviceMetadata {
  final String deviceId;
  final int signalStrength; // 0 to 4 bars
  final DateTime lastSeen;
  final String firmwareVersion;

  DeviceMetadata({
    required this.deviceId,
    required this.signalStrength,
    required this.lastSeen,
    required this.firmwareVersion,
  });

  bool get isOnline => DateTime.now().difference(lastSeen).inMinutes < 5;
}
