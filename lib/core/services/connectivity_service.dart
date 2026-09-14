abstract class ConnectivityService {
  /// Check if the device is currently connected to the internet
  Future<bool> get isConnected;
  
  /// Stream of connectivity changes
  Stream<bool> get onConnectivityChanged;
}
