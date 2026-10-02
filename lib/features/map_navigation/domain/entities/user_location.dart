class UserLocation {
  final double latitude;
  final double longitude;
  final double heading;
  final double accuracy;
  late final DateTime timestamp;

  UserLocation({
    required this.latitude,
    required this.longitude,
    this.heading = 0.0,
    this.accuracy = 0.0,
    DateTime? timestamp,
  }) {
    this.timestamp = timestamp ?? DateTime.now();
  }

  UserLocation copyWith({
    double? latitude,
    double? longitude,
    double? heading,
    double? accuracy,
    DateTime? timestamp,
  }) {
    return UserLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      heading: heading ?? this.heading,
      accuracy: accuracy ?? this.accuracy,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserLocation &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          heading == other.heading &&
          accuracy == other.accuracy;

  @override
  int get hashCode =>
      latitude.hashCode ^
      longitude.hashCode ^
      heading.hashCode ^
      accuracy.hashCode;

  @override
  String toString() {
    return 'UserLocation(lat: $latitude, lng: $longitude, heading: $heading, acc: $accuracy)';
  }
}
