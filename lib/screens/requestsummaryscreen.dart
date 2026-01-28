import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'main_navigation.dart';
import '../models/booking.dart';
import '../providers/booking_provider.dart';

class RequestSummaryScreen extends StatelessWidget {
  final String service;
  final String address;
  final String dateTime;
  final double price;
  final bool viewMode;

  // NEW (optional)
  final Map<String, int>? items;
  final String? note;

  const RequestSummaryScreen({
    Key? key,
    required this.service,
    required this.address,
    required this.dateTime,
    required this.price,
    this.viewMode = false,
    this.items,
    this.note,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF23233C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF23233C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Request Summary', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Container(
        color: Colors.grey.shade300,
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Service', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            _infoBox(service),

            const SizedBox(height: 16),
            const Text('Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            _infoBox(address),

            const SizedBox(height: 16),
            const Text('Preferred Date & Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            _infoBox(dateTime),

            // OPTIONAL details
            if ((items != null && items!.isNotEmpty) || (note != null && note!.isNotEmpty)) ...[
              const SizedBox(height: 16),
              const Text('Details (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (items != null && items!.isNotEmpty) ...[
                      ...items!.entries.map((e) => Text("• ${e.key}  x${e.value}")),
                      if (note != null && note!.isNotEmpty) const SizedBox(height: 8),
                    ],
                    if (note != null && note!.isNotEmpty) Text("Note: $note"),
                  ],
                ),
              ),
            ],

            const Spacer(),
            Container(
              color: const Color(0xFF23233C),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Estimated Amount', style: TextStyle(color: Colors.white70)),
                        Text('RM${price.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  if (!viewMode)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      ),
                      onPressed: () async {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("User not logged in")),
                          );
                          return;
                        }

                        final docRef = FirebaseFirestore.instance.collection('bookings').doc();

                        final newBooking = Booking(
                          id: docRef.id,
                          service: service,
                          address: address,
                          date: dateTime,
                          dateTime: dateTime,
                          status: 'ongoing',
                          price: price,
                        );

                        Provider.of<BookingProvider>(context, listen: false).addBooking(newBooking);

                        await docRef.set({
                          'userId': user.uid,
                          'service': service,
                          'address': address,
                          'date': dateTime,
                          'dateTime': dateTime,
                          'price': price,
                          'status': 'ongoing',
                          'timestamp': FieldValue.serverTimestamp(),

                          // save optional details
                          if (items != null && items!.isNotEmpty) 'items': items,
                          if (note != null && note!.isNotEmpty) 'note': note,
                        });

                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => MainNavigation(initialIndex: 1)),
                              (route) => false,
                        );
                      },
                      child: const Text('Next', style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoBox(String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      child: Text(value, style: const TextStyle(fontSize: 16)),
    );
  }
}
