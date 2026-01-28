import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'requestsummaryscreen.dart';
import 'address_picker_sheet.dart';
import 'add_address_screen.dart';

class BookingScreen extends StatefulWidget {
  final String service;
  const BookingScreen({super.key, required this.service});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final phoneController = TextEditingController();
  final remarkController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  bool _isLoading = true;

  // Optional selected items
  Map<String, int> selectedItems = {};

  // Item catalogs per service
  static const Map<String, List<String>> _itemCatalog = {
    'SOFA CLEANING': [
      '1-seater sofa',
      '2-seater sofa',
      '3-seater sofa',
      'L-shape / sectional',
      'Recliner',
      'Ottoman',
    ],
    'HOUSE CLEANING': [
      'Bedroom',
      'Living room',
      'Kitchen',
      'Bathroom',
      'Balcony',
      'Garage',
    ],
    'MATTRESS CLEANING': [
      'Single mattress',
      'Queen mattress',
      'King mattress',
      'Baby cot mattress',
    ],
    'WINDOW CLEANING': [
      'Small window',
      'Large window',
      'Sliding door glass',
      'Window grill cleaning',
    ],
    'CURTAIN CLEANING': [
      'Short curtain',
      'Long curtain',
      'Sheer curtain',
      'Roman blinds',
      'Roller blinds',
    ],
    'DEEP CLEANING': [
      'Full house deep clean',
      'Kitchen deep clean',
      'Bathroom deep clean',
      'Post-renovation clean',
    ],
    'CARPET CLEANING': [
      'Small carpet',
      'Medium carpet',
      'Large carpet',
      'Hallway runner',
    ],
    'MOVE IN/MOVE OUT CLEANING': [
      'Full house cleaning',
      'Kitchen only',
      'Bathrooms only',
      'Bedroom only',
      'Living room only',
    ],
  };


  static const servicePrices = {
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
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      if (data != null) {
        nameController.text = data['fullName'] ?? data['name'] ?? '';
        phoneController.text = data['phone'] ?? '';
      }
    } catch (e) {
      debugPrint("Error loading user profile: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showAddressPicker() async {
    final selectedAddress = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const AddressPickerSheet(),
    );

    if (selectedAddress == 'ADD_NEW') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AddAddressScreen()),
      );
      await _showAddressPicker();
    } else if (selectedAddress != null && selectedAddress.isNotEmpty) {
      setState(() {
        addressController.text = selectedAddress;
      });
    }
  }

  Future<void> _openItemsSheet() async {
    final items = _itemCatalog[widget.service.toUpperCase()];
    if (items == null || items.isEmpty) {
      // Nothing to pick for this service
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No extra items available for this service.")),
      );
      return;
    }

    final Map<String, int> temp = Map<String, int>.from(selectedItems);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 4,
                    width: 40,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(
                    "Add Details (Optional)",
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final item = items[i];
                        final qty = temp[item] ?? 0;
                        return ListTile(
                          title: Text(item),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: qty > 0
                                    ? () => setModal(() {
                                  if (qty <= 1) {
                                    temp.remove(item);
                                  } else {
                                    temp[item] = qty - 1;
                                  }
                                })
                                    : null,
                              ),
                              Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold)),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () => setModal(() {
                                  temp[item] = qty + 1;
                                }),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: remarkController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: "Extra notes (optional)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => selectedItems = Map<String, int>.from(temp));
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Done"),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF23233C),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text(
          "BOOK ${widget.service.toUpperCase()}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 2,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _roundedInput("Full Name", nameController, readOnly: true),
            const SizedBox(height: 16),

            // Address picker
            GestureDetector(
              onTap: _showAddressPicker,
              child: AbsorbPointer(child: _roundedInput("Address", addressController)),
            ),
            const SizedBox(height: 16),

            _roundedInput("Phone Number", phoneController,
                keyboardType: TextInputType.phone, readOnly: true),
            const SizedBox(height: 30),

            // Date & Time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _squarePicker(
                  label: selectedDate == null
                      ? "Date"
                      : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                  icon: Icons.calendar_today,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => selectedDate = picked);
                  },
                ),
                _squarePicker(
                  label: selectedTime == null ? "Time" : selectedTime!.format(context),
                  icon: Icons.access_time,
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (picked != null) setState(() => selectedTime = picked);
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Optional items button
            OutlinedButton.icon(
              onPressed: _openItemsSheet,
              icon: const Icon(Icons.add_shopping_cart),
              label: Text(
                selectedItems.isEmpty
                    ? "Add details (optional)"
                    : "Edit details (${selectedItems.length} selected)",
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
              ),
            ),

            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                if (_formKey.currentState!.validate() &&
                    selectedDate != null &&
                    selectedTime != null &&
                    addressController.text.isNotEmpty) {
                  final formattedDateTime =
                      "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}, ${selectedTime!.format(context)}";
                  final price = servicePrices[widget.service.toUpperCase()] ?? 0.0;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RequestSummaryScreen(
                        service: widget.service,
                        address: addressController.text,
                        dateTime: formattedDateTime,
                        price: price,
                        items: selectedItems.isEmpty ? null : selectedItems,
                        note: remarkController.text.trim().isEmpty
                            ? null
                            : remarkController.text.trim(),
                      ),
                    ),
                  );
                }
              },
              child: const Text("Submit Booking", style: TextStyle(fontWeight: FontWeight.bold)),
            ),

            const SizedBox(height: 40),
            Center(child: Image.asset('assets/image/logo.png', height: 60)),
          ],
        ),
      ),
    );
  }

  Widget _roundedInput(String hint, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text, bool readOnly = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
      ),
      validator: (value) => value == null || value.isEmpty ? "Required" : null,
    );
  }

  Widget _squarePicker({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black54),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
