class LogEntry {
  final DateTime timestamp;
  final String eventType; // 'Drop internet', 'GPS mati', 'Internet pulih', 'GPS pulih'
  final String status;    // 'drop' / 'normal'
  final int? durationMs;  // durasi drop jika ada (opsional)

  LogEntry({
    required this.timestamp,
    required this.eventType,
    this.status = 'normal',
    this.durationMs,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.millisecondsSinceEpoch,
    'eventType': eventType,
    'status': status,
    'durationMs': durationMs,
  };

  factory LogEntry.fromJson(Map<String, dynamic> json) => LogEntry(
    timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] ?? 0),
    eventType: json['eventType'] ?? '',
    status: json['status'] ?? 'normal',
    durationMs: json['durationMs'],
  );
}