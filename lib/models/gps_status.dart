class GpsStatus {
  final bool isFixed;
  final double latitude;
  final double longitude;
  final double accuracy;
  final double speed;
  final double bearing;
  final double altitude;

  GpsStatus({
    required this.isFixed,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.accuracy = 0.0,
    this.speed = 0.0,
    this.bearing = 0.0,
    this.altitude = 0.0,
  });

  String get fixText => isFixed ? 'Terkunci' : 'Tidak Terkunci';
  String get accuracyText => '${accuracy.toStringAsFixed(1)} m';

  Map<String, dynamic> toJson() => {
    'isFixed': isFixed,
    'latitude': latitude,
    'longitude': longitude,
    'accuracy': accuracy,
    'speed': speed,
    'bearing': bearing,
    'altitude': altitude,
  };

  factory GpsStatus.fromJson(Map<String, dynamic> json) => GpsStatus(
    isFixed: json['isFixed'] ?? false,
    latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
    longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
    speed: (json['speed'] as num?)?.toDouble() ?? 0.0,
    bearing: (json['bearing'] as num?)?.toDouble() ?? 0.0,
    altitude: (json['altitude'] as num?)?.toDouble() ?? 0.0,
  );

  static GpsStatus empty() => GpsStatus(isFixed: false);
}