class Address {
  final String id;
  final String title;
  final double latitude;
  final double longitude;

  Address({
    required this.id,
    required this.title,
    required this.latitude,
    required this.longitude,
  });

  factory Address.fromMap(Map<String, dynamic> data, String id) {
    return Address(
      id: id,
      title: data['title'],
      latitude: data['latitude'],
      longitude: data['longitude'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
