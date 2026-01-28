import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddressPickerSheet extends StatelessWidget {
  const AddressPickerSheet({super.key});

  Future<List<Map<String, dynamic>>> _fetchAddresses() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('addresses')
        .get();

    return snapshot.docs
        .map((doc) => {
      'id': doc.id,
      'address': doc['address'],
    })
        .toList();
  }

  Future<void> _deleteAddress(String docId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('addresses')
        .doc(docId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchAddresses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final addresses = snapshot.data ?? [];

          return Column(
            children: [
              const SizedBox(height: 10),
              const Text("Select Address",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const Divider(),

              /// If list is empty, show a message
              if (addresses.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text("No addresses found",
                      style: TextStyle(color: Colors.grey)),
                ),

              /// If there are addresses, show the list
              if (addresses.isNotEmpty)
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: addresses.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      return Dismissible(
                        key: Key(addresses[index]['id']),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Delete Address"),
                              content: const Text(
                                  "Are you sure you want to delete this address?"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: const Text("Delete",
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (direction) async {
                          await _deleteAddress(addresses[index]['id']);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Address deleted")),
                          );
                        },
                        child: ListTile(
                          leading: const Icon(Icons.location_on,
                              color: Colors.purple),
                          title: Text(addresses[index]['address']),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                "Swipe",
                                style:
                                TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_back_ios,
                                  size: 16, color: Colors.grey),
                            ],
                          ),
                          onTap: () {
                            Navigator.pop(
                                context, addresses[index]['address']);
                          },
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context, 'ADD_NEW');
                },
                icon: const Icon(Icons.add_location),
                label: const Text("Add New Address"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          );
        },
      ),
    );
  }
}
