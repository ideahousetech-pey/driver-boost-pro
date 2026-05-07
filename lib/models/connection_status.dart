class ConnectionStatus {
  final bool isConnected; // stabilitas berdasarkan ping
  final String connectionType; // 'wifi', 'mobile', 'none'
  final int latencyMs;
  final bool reachable; // berhasil ping 8.8.8.8

  ConnectionStatus({
    required this.isConnected,
    required this.connectionType,
    required this.latencyMs,
    required this.reachable,
  });

  String get stabilityText => isConnected ? 'Stabil' : 'Tidak Stabil';
  String get typeText {
    switch (connectionType) {
      case 'wifi': return 'WiFi';
      case 'mobile': return 'Seluler';
      default: return 'Tidak ada';
    }
  }

  Map<String, dynamic> toJson() => {
    'isConnected': isConnected,
    'connectionType': connectionType,
    'latencyMs': latencyMs,
    'reachable': reachable,
  };

  factory ConnectionStatus.fromJson(Map<String, dynamic> json) =>
      ConnectionStatus(
        isConnected: json['isConnected'] ?? false,
        connectionType: json['connectionType'] ?? 'none',
        latencyMs: json['latencyMs'] ?? 0,
        reachable: json['reachable'] ?? false,
      );

  static ConnectionStatus empty() => ConnectionStatus(
    isConnected: false, connectionType: 'none', latencyMs: 0, reachable: false);
}