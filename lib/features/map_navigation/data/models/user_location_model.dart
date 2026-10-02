import 'package:modern_locate/modern_locate.dart';
import '../../domain/entities/user_location.dart';

class UserLocationModel extends UserLocation {
  UserLocationModel({
    required super.latitude,
    required super.longitude,
    required super.heading,
    required super.accuracy,
  });

  // প্লাগইনের LocationData থেকে UserLocationModel এ রূপান্তর
  factory UserLocationModel.fromPlugin(LocationData data) {
    return UserLocationModel(
      latitude: data.latitude,
      longitude: data.longitude,
      heading: data.heading,
      accuracy: data.accuracy,
    );
  }
}