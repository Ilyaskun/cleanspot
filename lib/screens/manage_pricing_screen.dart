import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManagePricingScreen extends StatefulWidget {
  const ManagePricingScreen({Key? key}) : super(key: key);

  @override
  State<ManagePricingScreen> createState() => _ManagePricingScreenState();
}

class _ManagePricingScreenState extends State<ManagePricingScreen> {
  final Map<String, TextEditingController> _controllers = {};

  Future<void> _updatePrice(String service, String price) async {
    final double? parsedPrice = double.tryParse(price);
    if (parsedPrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Invalid price entered for $service")),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('service_prices')
        .doc(service)
        .set({'price': parsedPrice});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Pricing"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      backgroundColor: const Color(0xFF23233C),
      body: StreamBuilder<QuerySnapshot>(
        stream:
        FirebaseFirestore.instance.collection('service_prices').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final services = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final doc = services[index];
              final service = doc.id;
              final price = (doc['price'] ?? 0).toString();
              _controllers[service] ??= TextEditingController(text: price);

              return Card(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(service),
                  subtitle: TextField(
                    controller: _controllers[service],
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: "Price (RM)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.save, color: Colors.green),
                    onPressed: () =>
                        _updatePrice(service, _controllers[service]!.text),
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
