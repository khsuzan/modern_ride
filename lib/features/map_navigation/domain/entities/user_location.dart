import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

class UserLocation extends Equatable {
  final double latitude;
  final double longitude;
  final double heading;
  final double accuracy;
  final DateTime? timestamp;

  const UserLocation({
    required this.latitude,
    required this.longitude,
    this.heading = 0.0,
    this.accuracy = 0.0,
    this.timestamp,
  });

  /// Convenient helper to obtain a [LatLng] coordinate.
  LatLng get toLatLng => LatLng(latitude, longitude);

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
  List<Object?> get props => [
    latitude,
    longitude,
    heading,
    accuracy,
    timestamp,
  ];

  @override
  String toString() {
    return 'UserLocation(lat: $latitude, lng: $longitude, heading: $heading, acc: $accuracy)';
  }
}
