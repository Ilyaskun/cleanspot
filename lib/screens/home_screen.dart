import 'package:flutter/material.dart';
import 'package:cleanspot/screens/booking_screen.dart';
import 'package:cleanspot/screens/history_screen.dart';
import 'package:cleanspot/screens/notification_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});
  final List<Map<String, String>> services = [
    {"title": "SOFA CLEANING", "image": "sofa.png"},
    {"title": "HOUSE CLEANING", "image": "house.png"},
    {"title": "MATTRESS CLEANING", "image": "mattress.png"},
    {"title": "WINDOW CLEANING", "image": "window.png"},
    {"title": "CURTAIN CLEANING", "image": "curtain.png"},
    {"title": "DEEP CLEANING", "image": "deep.png"},
    {"title": "CARPET CLEANING", "image": "carpet.png"},
    {"title": "MOVE IN/MOVE OUT CLEANING", "image": "move.png"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF23233C),
      appBar: AppBar(
        title: const Text(
          "BOOKING",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 2,
      ),
      body: Column(
        children: [
          // Top banner
          SizedBox(
            height: 150,
            width: double.infinity,
            child: Image.asset(
              'assets/image/banner.jpeg',
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 20),

          // Centered grid
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: GridView.builder(
                  shrinkWrap: true,
                  itemCount: services.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.8,
                  ),
                  itemBuilder: (context, index) {
                    return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookingScreen(
                                service: services[index]["title"]!,
                              ),
                            ),
                          );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(
                            image: AssetImage(
                              'assets/image/${services[index]["image"]}',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(16),
                            ),
                          ),
                          child: Text(
                            services[index]["title"]!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
