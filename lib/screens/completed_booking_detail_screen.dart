import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CompletedBookingDetailScreen extends StatelessWidget {
  final String bookingId;
  const CompletedBookingDetailScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF23233C),
      appBar: AppBar(
        title: const Text('Booking Details'),
        centerTitle: true,
        backgroundColor: const Color(0xFF23233C),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('bookings')
            .doc(bookingId)
            .get(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || !snap.data!.exists) {
            return const Center(
              child: Text('Booking not found', style: TextStyle(color: Colors.white70)),
            );
          }

          final m = snap.data!.data() as Map<String, dynamic>;
          final service = (m['service'] ?? 'Unknown').toString();
          final address = (m['address'] ?? 'N/A').toString();
          final date = (m['date'] ?? '').toString();
          final price = (m['price'] is num) ? (m['price'] as num).toDouble() : null;
          final List<String> proofs =
          ((m['cleanerProofs'] as List?) ?? const []).map((e) => e.toString()).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(service,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: const [
                        Icon(Icons.calendar_month, size: 18),
                        SizedBox(width: 8),
                      ],
                    ),
                    Text(date),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Icon(Icons.location_pin, size: 18),
                        SizedBox(width: 8),
                      ],
                    ),
                    Text(address),
                    if (price != null) ...[
                      const SizedBox(height: 6),
                      Text('Price: RM${price.toStringAsFixed(2)}'),
                    ],
                    const SizedBox(height: 16),
                    const Text('Cleaner Proofs:',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    if (proofs.isEmpty)
                      const Text('No proof photos were attached.',
                          style: TextStyle(color: Colors.black54))
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: proofs.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemBuilder: (context, i) {
                          final url = proofs[i];
                          return InkWell(
                            onTap: () => _showFullPhoto(context, url),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(url, fit: BoxFit.cover),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showFullPhoto(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          color: Colors.black,
          child: Center(
            child: InteractiveViewer(
              child: Image.network(url),
            ),
          ),
        ),
      ),
    );
  }
}
