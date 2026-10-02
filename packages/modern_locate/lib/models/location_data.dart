class LocationData {
  final double latitude;
  final double longitude;
  final double heading;
  final double accuracy;

  const LocationData({
    required this.latitude,
    required this.longitude,
    required this.heading,
    required this.accuracy,
  });

  factory LocationData.fromMap(Map<dynamic, dynamic> map) {
    return LocationData(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      heading: (map['heading'] as num?)?.toDouble() ?? 0.0,
      accuracy: (map['accuracy'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() => {
        'latitude': latitude,
        'longitude': longitude,
        'heading': heading,
        'accuracy': accuracy,
      };

  @override
  String toString() =>
      'LocationData(lat: $latitude, lng: $longitude, heading: $heading, acc: $accuracy)';
}