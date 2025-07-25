import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingPage extends StatelessWidget {
  const BookingPage({super.key});

  Future<DocumentSnapshot?> getEventFromId(String eventId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('Event').doc(eventId).get();
      return doc.exists ? doc : null;
    } catch (e) {
      return null;
    }
  }

  bool isExpired(DateTime date) {
    final now = DateTime.now();
    return date.isBefore(now);
  }

  Future<void> _deleteBooking(BuildContext context, String bookingId, String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('user')
          .doc(userId)
          .collection('Bookings')
          .doc(bookingId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Booking deleted successfully"), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete booking: $e"), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    final userId = currentUser.uid;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB993D6), Color(0xFF8CA6DB)], // Purple to blue
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Center(
                child: Text(
                  "My Bookings",
                  style: TextStyle(
                    fontSize: screenWidth * 0.07,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                  ),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('user')
                        .doc(userId)
                        .collection('Bookings')
                        .orderBy('bookingTime', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final bookings = snapshot.data!.docs;

                      if (bookings.isEmpty) {
                        return const Center(child: Text("No bookings yet."));
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: bookings.length,
                        itemBuilder: (context, index) {
                          final booking = bookings[index];
                          final eventId = booking['eventId'];
                          final bookingId = booking.id;

                          return FutureBuilder<DocumentSnapshot?>(
                            future: getEventFromId(eventId),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return const SizedBox();

                              final eventDoc = snapshot.data;
                              if (eventDoc == null || !eventDoc.exists) return const SizedBox();

                              final data = eventDoc.data() as Map<String, dynamic>;

                              final dateStr = data['Date'];
                              DateTime? eventDate;
                              if (dateStr is String) {
                                try {
                                  eventDate = DateTime.parse(dateStr);
                                } catch (_) {}
                              } else if (dateStr is Timestamp) {
                                eventDate = dateStr.toDate();
                              }

                              final expired = eventDate == null ? true : isExpired(eventDate);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F3FF),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 5,
                                      offset: Offset(0, 3),
                                    )
                                  ],
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.event, color: Colors.deepPurple),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            data['Name'] ?? 'Event Name',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                        ),
                                        if (expired)
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () => _deleteBooking(context, bookingId, userId),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: data['Image'] != null
                                              ? Image.network(
                                            data['Image'],
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return const Icon(Icons.image_not_supported, size: 80);
                                            },
                                          )
                                              : const Icon(Icons.image_not_supported, size: 80),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(Icons.location_on, size: 16),
                                                  const SizedBox(width: 5),
                                                  Expanded(
                                                    child: Text(data['Location'] ?? 'Unknown'),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 5),
                                              Row(
                                                children: [
                                                  const Icon(Icons.calendar_today, size: 16),
                                                  const SizedBox(width: 5),
                                                  Text(data['Date']?.toString() ?? 'N/A'),
                                                ],
                                              ),
                                              const SizedBox(height: 5),
                                              Row(
                                                children: [
                                                  const Icon(Icons.currency_rupee, size: 16),
                                                  const SizedBox(width: 5),
                                                  Text(data['Price']?.toString() ?? '0'),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
