import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'login_screen.dart';

const String kStorageBucket = 'gs://cleanspot-dc8b3.firebasestorage.app';

class CleanerHomeScreen extends StatefulWidget {
  const CleanerHomeScreen({Key? key}) : super(key: key);

  @override
  State<CleanerHomeScreen> createState() => _CleanerHomeScreenState();
}

class _CleanerHomeScreenState extends State<CleanerHomeScreen> {
  String selectedCategory = 'available'; // available | in_progress | completed
  String searchQuery = '';
  String? myUid;

  @override
  void initState() {
    super.initState();
    myUid = FirebaseAuth.instance.currentUser?.uid;
  }

  Future<bool> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
      if (!mounted) return false;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginScreen()),
            (route) => false,
      );
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _confirmLogout(); // Android back confirmation
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF23233C),
        appBar: AppBar(
          title: const Text("Cleaner Dashboard"),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        drawer: _buildDrawer(),
        body: Column(
          children: [
            _buildSearchBar(),
            Expanded(child: _buildList()),
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
            child: Text("Cleaner Menu", style: TextStyle(color: Colors.white, fontSize: 20)),
          ),
          _drawerItem("Available Jobs", 'available'),
          _drawerItem("In Progress", 'in_progress'),
          _drawerItem("Completed", 'completed'),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Logout"),
            onTap: () async {
              Navigator.pop(context); // close drawer first
              await _confirmLogout();
            },
          ),
        ],
      ),
    );
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
        onChanged: (v) => setState(() => searchQuery = v.toLowerCase()),
      ),
    );
  }

  Widget _buildList() {
    if (myUid == null) {
      return const Center(child: Text("Not signed in", style: TextStyle(color: Colors.white)));
    }

    final base = FirebaseFirestore.instance.collection('bookings');
    late Stream<QuerySnapshot<Map<String, dynamic>>> stream;

    if (selectedCategory == 'available') {
      stream = base.where('status', isEqualTo: 'Approved').snapshots();
    } else if (selectedCategory == 'in_progress') {
      stream = base.where('status', isEqualTo: 'in_progress').where('assignedCleanerId', isEqualTo: myUid).snapshots();
    } else {
      stream = base.where('status', isEqualTo: 'completed').where('assignedCleanerId', isEqualTo: myUid).snapshots();
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const Center(child: Text("No jobs found", style: TextStyle(color: Colors.white)));
        }

        List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = snap.data!.docs;

        if (selectedCategory == 'available') {
          docs = docs.where((d) {
            final m = d.data();
            if (!m.containsKey('assignedCleanerId')) return true;
            final val = m['assignedCleanerId'];
            if (val == null) return true;
            if (val is String && val.trim().isEmpty) return true;
            return false;
          }).toList();
        }

        if (searchQuery.isNotEmpty) {
          docs = docs.where((d) {
            final m = d.data();
            final service = (m['service'] ?? '').toString().toLowerCase();
            final address = (m['address'] ?? '').toString().toLowerCase();
            return service.contains(searchQuery) || address.contains(searchQuery);
          }).toList();
        }

        if (docs.isEmpty) {
          return const Center(child: Text("No jobs match", style: TextStyle(color: Colors.white)));
        }

        docs.sort((a, b) {
          final ta = (a['timestamp'] as Timestamp?)?.toDate() ?? DateTime(2000);
          final tb = (b['timestamp'] as Timestamp?)?.toDate() ?? DateTime(2000);
          return tb.compareTo(ta);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final doc = docs[i];
            final data = doc.data();
            final service = data['service'] ?? 'Unknown Service';
            final address = data['address'] ?? 'N/A';
            final date = data['date'] ?? 'N/A';
            final price = (data['price'] is num) ? (data['price'] as num).toDouble() : 0.0;

            final Map<String, dynamic>? itemsRaw = (data['items'] as Map?)?.cast<String, dynamic>();
            final String? note = (data['note'] == null || data['note'].toString().isEmpty) ? null : data['note'].toString();

            final List<String> proofList = ((data['cleanerProofs'] as List?) ?? const []).map((e) => e.toString()).toList();
            final bool reviewReady = (data['reviewReady'] == true);

            return Card(
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(service, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                        if (reviewReady)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(999)),
                            child: const Text("Ready for review"),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text("Address: $address"),
                    Text("Date: $date"),
                    Text("Price: RM${price.toStringAsFixed(2)}"),
                    if ((itemsRaw != null && itemsRaw.isNotEmpty) || note != null) ...[
                      const SizedBox(height: 6),
                      const Text("Details:", style: TextStyle(fontWeight: FontWeight.w600)),
                      if (itemsRaw != null && itemsRaw.isNotEmpty)
                        ...itemsRaw.entries.map((e) => Text("• ${e.key} x${e.value}")),
                      if (note != null) Text("Note: $note"),
                    ],
                    if (proofList.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text("Your Proof Photos:", style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: proofList.map((url) {
                          return Stack(
                            alignment: Alignment.topRight,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(url, height: 90, width: 90, fit: BoxFit.cover),
                              ),
                              if (selectedCategory == 'in_progress')
                                Material(
                                  color: Colors.transparent,
                                  child: IconButton(
                                    icon: const Icon(Icons.close, size: 18, color: Colors.red),
                                    onPressed: () => _deleteProof(doc.id, url),
                                  ),
                                ),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 10),
                    _actionsFor(doc, proofList.isNotEmpty),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _actionsFor(QueryDocumentSnapshot<Map<String, dynamic>> bookingDoc, bool hasAnyProof) {
    final data = bookingDoc.data();
    final userId = data['userId'] as String? ?? '';
    final assignedCleanerId = data['assignedCleanerId'] as String?;

    if (selectedCategory == 'available') {
      return Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton(
          onPressed: () async {
            try {
              await bookingDoc.reference.update({
                'assignedCleanerId': myUid,
                'assignedAt': FieldValue.serverTimestamp(),
              });
              await bookingDoc.reference.update({
                'status': 'in_progress',
                'workStartedAt': FieldValue.serverTimestamp(),
              });
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Job accepted — started")));
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to accept: $e")));
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          child: const Text("Accept Job"),
        ),
      );
    }

    if (selectedCategory == 'in_progress') {
      final canAct = assignedCleanerId == myUid;
      return Wrap(
        alignment: WrapAlignment.end,
        spacing: 8,
        children: [
          ElevatedButton(
            onPressed: canAct ? () => _notifyOnMyWay(userId) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white70,
            ),
            child: const Text("I'm on my way"),
          ),
          ElevatedButton(
            onPressed: canAct ? () => _uploadProof(bookingDoc.id) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white70,
            ),
            child: Text(hasAnyProof ? "Add More Photos" : "Upload Proof"),
          ),
          ElevatedButton(
            onPressed: canAct && hasAnyProof
                ? () async {
              await bookingDoc.reference.update({
                'reviewReady': true,
                'reviewAt': FieldValue.serverTimestamp(),
              });
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sent for admin review")));
            }
                : null,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, disabledForegroundColor: Colors.white70),
            child: const Text("Send for Review"),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _notifyOnMyWay(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'type': 'cleaner_on_way',
        'service': 'Cleaner On the Way',
        'reason': '',
        'senderId': myUid,
        'timestamp': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User notified: on the way")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to notify: $e")));
    }
  }

  Future<void> _uploadProof(String bookingId) async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 75);
      if (picked == null) return;

      final file = File(picked.path);
      final storage = FirebaseStorage.instanceFor(bucket: kStorageBucket);
      final ref = storage.ref().child('cleaner_proofs').child(bookingId).child(myUid!).child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      final task = await ref.putFile(file);
      final url = await task.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
        'cleanerProofs': FieldValue.arrayUnion([url]),
        'proofBy': myUid,
        'cleanerProofAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Photo uploaded")));
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: [${e.code}] ${e.message}")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
    }
  }

  Future<void> _deleteProof(String bookingId, String url) async {
    try {
      final storage = FirebaseStorage.instanceFor(bucket: kStorageBucket);
      final ref = storage.refFromURL(url);
      await ref.delete();

      await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
        'cleanerProofs': FieldValue.arrayRemove([url]),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Photo removed")));
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Delete failed: [${e.code}] ${e.message}")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Delete failed: $e")));
    }
  }
}
