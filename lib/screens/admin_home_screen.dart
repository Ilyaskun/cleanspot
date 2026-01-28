import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'manage_pricing_screen.dart';
import 'login_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({Key? key}) : super(key: key);

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  String selectedCategory = 'ongoing'; // ongoing | Approved | Rejected | completed
  String searchQuery = '';
  Map<String, double> servicePrices = {};

  @override
  void initState() {
    super.initState();
    _loadServicePrices();
  }

  Future<void> _loadServicePrices() async {
    final snapshot = await FirebaseFirestore.instance.collection('service_prices').get();
    final prices = <String, double>{};
    for (var doc in snapshot.docs) {
      prices[doc.id.toUpperCase()] = (doc.data()['price'] ?? 0).toDouble();
    }
    if (!mounted) return;
    setState(() => servicePrices = prices);
  }

  @override
  Widget build(BuildContext context) {
    // ⬇️ Show confirm dialog when Android back is pressed
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _confirmLogout(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Admin Dashboard"),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        drawer: _buildDrawer(),
        backgroundColor: const Color(0xFF23233C),
        body: Column(
          children: [
            if (selectedCategory == 'Approved') _buildSearchBar(),
            Expanded(child: _buildBookingList()),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              "Admin Menu",
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
          _drawerItem("Ongoing Bookings", 'ongoing'),
          _drawerItem("Approved / Review", 'Approved'),
          _drawerItem("Rejected Bookings", 'Rejected'),
          _drawerItem("Completed Bookings", 'completed'),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.price_change),
            title: const Text("Manage Pricing"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagePricingScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Logout"),
            onTap: () async {
              Navigator.pop(context); // close the drawer first
              await _confirmLogout(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Logout", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (shouldLogout == true) {
      try { await FirebaseAuth.instance.signOut(); } catch (_) {}
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginScreen()),
            (route) => false,
      );
    }
  }

  Widget _drawerItem(String title, String status) {
    return ListTile(
      leading: const Icon(Icons.list),
      title: Text(title),
      selected: selectedCategory == status,
      onTap: () {
        setState(() {
          selectedCategory = status;
          searchQuery = '';
        });
        Navigator.pop(context);
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search by address or service',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
      ),
    );
  }

  Widget _buildBookingList() {
    final col = FirebaseFirestore.instance.collection('bookings');
    Stream<QuerySnapshot> stream;

    if (selectedCategory == 'Approved') {
      // Treat this tab as "review queue": show Approved + In Progress
      stream = col
          .where('status', whereIn: ['Approved', 'in_progress'])
          .orderBy('timestamp', descending: true)
          .snapshots();
    } else {
      stream = col.where('status', isEqualTo: selectedCategory).orderBy('timestamp', descending: true).snapshots();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final bookings = snapshot.data!.docs;

        final filtered = bookings.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final service = (data['service'] ?? '').toString().toLowerCase();
          final address = (data['address'] ?? '').toString().toLowerCase();
          return service.contains(searchQuery) || address.contains(searchQuery);
        }).toList();

        if (filtered.isEmpty) {
          return const Center(child: Text("No bookings found", style: TextStyle(color: Colors.white)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final doc = filtered[index];
            final data = doc.data() as Map<String, dynamic>;
            final service = data['service'] ?? 'Unknown';
            final price = servicePrices[service.toUpperCase()] ?? 0.0;
            final List<String> proofs = ((data['cleanerProofs'] as List?) ?? const [])
                .map((e) => e.toString())
                .toList();
            final bool reviewReady = (data['reviewReady'] == true);

            return Card(
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(service, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        if (reviewReady)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text("Ready for review"),
                          ),
                      ],
                    ),
                    Text("Address: ${data['address'] ?? 'N/A'}"),
                    Text("Date: ${data['date'] ?? 'N/A'}"),
                    Text("Price: RM${price.toStringAsFixed(2)}"),

                    if (proofs.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      const Text("Cleaner Proofs:", style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),

                      // Tap-to-fullscreen (unchanged behavior you wanted)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: proofs.map((u) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FullscreenImagePage(imageUrl: u, heroTag: u),
                                ),
                              );
                            },
                            child: Hero(
                              tag: u,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(u, height: 90, width: 90, fit: BoxFit.cover),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 8),
                    _buildActionsForStatus(selectedCategory, doc),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActionsForStatus(String status, QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final userId = data['userId'] ?? '';
    final service = data['service'] ?? '';
    final String s = (data['status'] ?? '').toString();

    if (status == 'ongoing') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              await doc.reference.update({'status': 'Approved'});
              await _sendNotification(userId, 'approved', service);
            },
            child: const Text("Approve"),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => _showRejectDialog(doc.id, userId, service),
            child: const Text("Reject"),
          ),
        ],
      );
    } else if (status == 'Approved') {
      // In review queue we also show items whose status is in_progress
      return ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
        onPressed: () async {
          await doc.reference.update({'status': 'completed', 'reviewReady': false});
          await _sendNotification(userId, 'completed', service);
        },
        child: Text(s == 'in_progress' ? "Mark Complete (reviewed)" : "Mark Complete"),
      );
    }
    return const SizedBox.shrink();
  }

  Future<void> _showRejectDialog(String bookingId, String userId, String service) async {
    final reasonController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reject Booking"),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(labelText: "Reason for rejection"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
                'status': 'Rejected',
                'rejectionReason': reasonController.text.trim(),
                'reviewReady': false,
              });
              await _sendNotification(userId, 'rejected', service, reason: reasonController.text.trim());
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Reject", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _sendNotification(
      String userId,
      String type,
      String service, {
        String? reason,
      }) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': userId,
      'type': type, // approved, rejected, completed
      'service': service,
      'reason': reason ?? '',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}

/// Fullscreen image (unchanged)
class FullscreenImagePage extends StatelessWidget {
  final String imageUrl;
  final String heroTag;
  const FullscreenImagePage({Key? key, required this.imageUrl, required this.heroTag}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: Hero(
            tag: heroTag,
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4,
              child: Image.network(imageUrl),
            ),
          ),
        ),
      ),
    );
  }
}
