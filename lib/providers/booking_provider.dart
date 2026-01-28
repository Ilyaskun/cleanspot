import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/booking.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingProvider with ChangeNotifier {
  final List<Booking> _bookings = [];

  List<Booking> get bookings => _bookings;

  /// new booking locally
  void addBooking(Booking booking) {
    _bookings.add(booking);
    notifyListeners();
  }

  /// user bookings from Firestore with null safety
  Future<void> fetchBookings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: user.uid)
          .get();

      _bookings.clear();
      for (var doc in snapshot.docs) {
        final data = doc.data();

        _bookings.add(Booking(
          id: doc.id,
          service: (data['service'] ?? 'No service selected').toString(),
          address: (data['address'] ?? 'No address provided').toString(),
          date: (data['date'] ?? 'No date specified').toString(),
          status: (data['status'] ?? 'ongoing').toString(),
        ));
      }

      notifyListeners();
    } catch (e) {
      print("Error fetching bookings: $e");
    }
  }

  /// Cancel booking
  Future<void> cancelBooking(String bookingId) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({'status': 'cancelled'});

      final index = _bookings.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        _bookings[index] = Booking(
          id: _bookings[index].id,
          service: _bookings[index].service,
          address: _bookings[index].address,
          date: _bookings[index].date,
          status: 'cancelled',
        );
        notifyListeners();
      }
    } catch (e) {
      print("Error cancelling booking: $e");
    }
  }
}
