import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  Color _colorForType(String type) {
    switch (type) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      case 'cleaner_on_way':
        return Colors.orange;           // on the way
      case 'cleaner_arrived':
        return Colors.orange.shade700;  // if ever used later
      default:
        return Colors.grey;
    }
  }

  String _messageForType(String type, String service, String? reason) {
    switch (type) {
      case 'approved':
        return "Your booking for $service has been approved.";
      case 'rejected':
        return "Your booking for $service was rejected. Reason: ${reason ?? 'No reason provided'}";
      case 'completed':
        return "Your booking for $service is completed.";
      case 'cleaner_on_way':
        return "Cleaner is on the way for your $service booking.";
      case 'cleaner_arrived':
        return "Cleaner has arrived for your $service booking.";
      default:
        return "Notification: $service";
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text("Not signed in")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        centerTitle: true,
        backgroundColor: const Color(0xFF23233C),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF23233C),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No notifications", style: TextStyle(color: Colors.white)),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final type = (data['type'] ?? '').toString();
              final service = (data['service'] ?? 'Service').toString();
              final reason = data['reason']?.toString();
              final color = _colorForType(type);
              final msg = _messageForType(type, service, reason);

              return Card(
                color: Colors.white,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color,
                    child: const Icon(Icons.notifications, color: Colors.white),
                  ),
                  title: Text(msg, style: const TextStyle(fontSize: 14)),
                  subtitle: Text(
                    (data['timestamp'] as Timestamp?)?.toDate().toString() ?? '',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
