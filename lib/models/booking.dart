class Booking {
  final String id;
  final String service;
  final String address;
  final String date;
  final String? dateTime;
  final String status;
  final double? price;

  Booking({
    required this.id,
    required this.service,
    required this.address,
    required this.date,
    this.dateTime,
    required this.status,
    this.price,
  });

  factory Booking.fromFirestore(Map<String, dynamic> data, String id) {
    return Booking(
      id: id,
      service: data['service'] ?? '',
      address: data['address'] ?? '',
      date: data['date'] ?? '',
      dateTime: data['dateTime'],
      status: data['status'] ?? 'ongoing',
      price: (data['price'] != null)
          ? (data['price'] as num).toDouble()
          : null,
    );
  }
}
