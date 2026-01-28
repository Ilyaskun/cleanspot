import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'requestsummaryscreen.dart';
import 'completed_booking_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  /// Tabs: "In Process" | "Completed"
  String selectedTab = 'In Process';

  final Map<String, double> servicePrices = {
    'SOFA CLEANING': 180.0,
    'HOUSE CLEANING': 120.0,
    'MATTRESS CLEANING': 150.0,
    'WINDOW CLEANING': 100.0,
    'CURTAIN CLEANING': 150.0,
    'DEEP CLEANING': 350.0,
    'CARPET CLEANING': 120.0,
    'MOVE IN/MOVE OUT CLEANING': 450.0,
  };

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Not signed in')),
      );
    }

    // Build a Firestore query based on the selected tab.
    final col = FirebaseFirestore.instance.collection('bookings');
    final List<String> statusIn = (selectedTab == 'In Process')
        ? <String>[
      'ongoing',
      'Approved',
      'approved',
      'in_progress',
    ]
        : <String>[
      'completed',
    ];

    final stream = col
        .where('userId', isEqualTo: uid)
        .where('status', whereIn: statusIn)
        .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFF23233C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('History', style: TextStyle(color: Colors.white)),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTabButton('In Process'),
              const SizedBox(width: 16),
              _buildTabButton('Completed'),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: stream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No bookings found',
                        style: TextStyle(color: Colors.white70)),
                  );
                }

                final items = snap.data!.docs.map((d) {
                  final m = d.data() as Map<String, dynamic>;
                  return _BookingVM(
                    id: d.id,
                    service: (m['service'] ?? 'Unknown').toString(),
                    date: (m['date'] ?? '').toString(),
                    address: (m['address'] ?? '').toString(),
                    status: (m['status'] ?? '').toString(),
                    timestamp: (m['timestamp'] as Timestamp?)?.toDate(),
                  );
                }).toList()
                  ..sort((a, b) => (b.timestamp ?? DateTime(2000))
                      .compareTo(a.timestamp ?? DateTime(2000)));

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  itemBuilder: (_, i) => _buildCard(items[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tab) {
    final isSelected = selectedTab == tab;
    return ElevatedButton(
      onPressed: () => setState(() => selectedTab = tab),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.white : Colors.transparent,
        foregroundColor: isSelected ? Colors.black : Colors.white,
        elevation: isSelected ? 4 : 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: Text(tab, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildCard(_BookingVM b) {
    final price =
        servicePrices[b.service.toUpperCase()] ?? 0.0; // fallback if not stored

    return GestureDetector(
      onTap: () async {
        // If completed → open proof viewer. Otherwise show your summary page.
        if (b.status.toLowerCase() == 'completed') {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CompletedBookingDetailScreen(bookingId: b.id),
            ),
          );
          return;
        }

        // fetch items/note from Firestore for summary view
        Map<String, int>? itemsMap;
        String? note;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );

        try {
          final snap = await FirebaseFirestore.instance
              .collection('bookings')
              .doc(b.id)
              .get();
          if (snap.exists) {
            final data = snap.data() as Map<String, dynamic>;
            final rawItems = data['items'] as Map?;
            if (rawItems != null && rawItems.isNotEmpty) {
              itemsMap = rawItems.map<String, int>(
                    (k, v) => MapEntry(k.toString(), (v ?? 0) as int),
              );
            }
            final n = data['note'];
            if (n != null && n.toString().isNotEmpty) note = n.toString();
          }
        } finally {
          if (mounted) Navigator.pop(context);
        }

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RequestSummaryScreen(
              service: b.service,
              address: b.address,
              dateTime: b.date,
              price: price,
              viewMode: true,
              items: itemsMap,
              note: note,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(b.service,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.calendar_month, size: 18),
              const SizedBox(width: 8),
              Text(b.date),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.location_pin, size: 18),
              const SizedBox(width: 8),
              Flexible(child: Text(b.address)),
            ]),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Status chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (b.status.toLowerCase() == 'completed')
                        ? Colors.green
                        : Colors.grey[700],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _prettyStatus(b.status),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),

                // ✅ Add Cancel button ONLY when not yet approved (status = ongoing)
                if (b.status.toLowerCase() == 'ongoing')
                  ElevatedButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Confirm Cancel'),
                          content: const Text(
                            'Are you sure you want to cancel this booking?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('No'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Yes, Cancel'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        try {
                          await FirebaseFirestore.instance
                              .collection('bookings')
                              .doc(b.id)
                              .update({'status': 'cancelled'});

                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Booking cancelled successfully'),
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to cancel booking: $e'),
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Cancel'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _prettyStatus(String raw) {
    final s = raw.toLowerCase();
    if (s == 'in_progress') return 'In Process';
    if (s == 'ongoing') return 'Ongoing';
    if (s == 'approved') return 'Approved';
    if (s == 'completed') return 'Completed';
    if (s == 'cancelled') return 'Cancelled';
    if (s == 'rejected') return 'Rejected';
    return raw.replaceAll('_', ' ').capitalize();
  }
}

/// lightweight view model used just for rendering
class _BookingVM {
  final String id;
  final String service;
  final String date;
  final String address;
  final String status;
  final DateTime? timestamp;
  _BookingVM({
    required this.id,
    required this.service,
    required this.date,
    required this.address,
    required this.status,
    required this.timestamp,
  });
}

extension StringCasingExtension on String {
  String capitalize() {
    if (isEmpty) return '';
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
