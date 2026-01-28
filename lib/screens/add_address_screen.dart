import 'package:flutter/material.dart';
import 'package:google_place/google_place.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({super.key});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final TextEditingController _searchController = TextEditingController();
  late GooglePlace googlePlace;
  List<AutocompletePrediction> predictions = [];
  bool isLoading = false;
  bool isSaving = false; // ✅ Prevent multiple taps

  @override
  void initState() {
    super.initState();
    const apiKey = "AIzaSyCN-hNCEu3zFGgyoMoX0XggqUbWeEfu1LY"; // API Key
    googlePlace = GooglePlace(apiKey);
  }

  /// search suggestion
  void autoCompleteSearch(String value) async {
    if (value.isNotEmpty) {
      setState(() => isLoading = true);

      var result = await googlePlace.autocomplete.get(value, components: [
        Component('country', 'my') // only show Malaysian results
      ]);

      if (mounted) {
        setState(() {
          predictions = result?.predictions ?? [];
          isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          predictions = [];
          isLoading = false;
        });
      }
    }
  }

  /// Save selected address to Firestore
  Future<void> _saveAddress(String address) async {
    if (isSaving) return;
    setState(() => isSaving = true);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      // Avoid saving duplicate addresses for same user
      final existing = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('addresses')
          .where('address', isEqualTo: address)
          .limit(1)
          .get();

      if (existing.docs.isEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('addresses')
            .add({'address': address});
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Address saved successfully")),
      );

      Navigator.pop(context, address); // return selected address
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to save address: $e")),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF23233C),
      appBar: AppBar(
        title: const Text("Add Address"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// Search input
            TextField(
              controller: _searchController,
              onChanged: autoCompleteSearch,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: "Search address",
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// Loading spinner
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),

            /// Show suggestions
            Expanded(
              child: predictions.isEmpty
                  ? const Center(
                child: Text("No suggestions",
                    style: TextStyle(color: Colors.white70)),
              )
                  : ListView.builder(
                itemCount: predictions.length,
                itemBuilder: (context, index) {
                  final prediction = predictions[index];
                  return ListTile(
                    leading: const Icon(Icons.location_on,
                        color: Colors.white),
                    title: Text(prediction.description ?? '',
                        style: const TextStyle(color: Colors.white)),
                    onTap: () => _saveAddress(prediction.description ?? ''),
                  );
                },
              ),
            ),

            /// Saving indicator
            if (isSaving)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  "Saving address...",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
