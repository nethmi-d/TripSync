import 'package:flutter/material.dart';

class AccommodationScreen extends StatelessWidget {
  const AccommodationScreen({super.key});

  Future<void> _openMap(String location) async {
    final Uri url = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$location",
    );
  }

  @override
  Widget build(BuildContext context) {
    final accommodations = [
      {
        "type": "Villa",
        "name": "Sunset Villa Seminyak",
        "address": "Jl. Kayu Aya No.42, Seminyak, Kuta",
        "phone": "+62 361 730 123",
        "email": "info@sunsetvilla.com",
        "checkIn": "Jun 15",
        "checkOut": "Jun 20",
        "note": "Code for gate: 1234. Pool is open 24/7",
        "image":
            "https://images.unsplash.com/photo-1564013799919-ab600027ffc6",
      },
      {
        "type": "Resort",
        "name": "Ubud Jungle Retreat",
        "address": "Jl. Raya Ubud No.88, Ubud, Gianyar",
        "phone": "+62 361 975 456",
        "email": "reservations@ubudretreat.com",
        "checkIn": "Jun 20",
        "checkOut": "Jun 25",
        "note": "Free yoga class daily at 7 AM. Breakfast included",
        "image":
            "https://images.unsplash.com/photo-1582719478250-c89cae4dc85b",
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          "Accommodation",
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: accommodations.length,
        itemBuilder: (context, index) {
          final item = accommodations[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 18),

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.05),
                  blurRadius: 12,
                ),
              ],
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      child: Image.network(
                        item["image"]!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),

                    Positioned(
                      right: 12,
                      top: 12,

                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),

                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(20),
                        ),

                        child: Text(
                          item["type"]!,
                          style: const TextStyle(
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.all(14),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      Text(
                        item["name"]!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 5),

                          Expanded(
                            child: Text(
                              item["address"]!,
                              style: const TextStyle(
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      Row(
                        children: [

                          Expanded(
                            child: Container(
                              padding:
                                  const EdgeInsets.all(12),

                              decoration: BoxDecoration(
                                color: const Color(
                                    0xFFEFF6FF),
                                borderRadius:
                                    BorderRadius.circular(
                                        12),
                              ),

                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,

                                children: [
                                  const Text(
                                    "Check-in",
                                    style: TextStyle(
                                      color:
                                          Colors.blue,
                                      fontSize: 12,
                                    ),
                                  ),

                                  Text(
                                    item["checkIn"]!,
                                    style:
                                        const TextStyle(
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: Container(
                              padding:
                                  const EdgeInsets.all(12),

                              decoration: BoxDecoration(
                                color: const Color(
                                    0xFFF3E8FF),
                                borderRadius:
                                    BorderRadius.circular(
                                        12),
                              ),

                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,

                                children: [
                                  const Text(
                                    "Check-out",
                                    style: TextStyle(
                                      color:
                                          Colors.purple,
                                      fontSize: 12,
                                    ),
                                  ),

                                  Text(
                                    item["checkOut"]!,
                                    style:
                                        const TextStyle(
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      Row(
                        children: [
                          const Icon(
                            Icons.phone_outlined,
                            size: 18,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(item["phone"]!),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          const Icon(
                            Icons.email_outlined,
                            size: 18,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item["email"]!,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),

                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFFFFBEB),
                          border: Border.all(
                            color:
                                const Color(0xFFFACC15),
                          ),
                          borderRadius:
                              BorderRadius.circular(12),
                        ),

                        child: Text(
                          item["note"]!,
                        ),
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 52,

                        child: ElevatedButton.icon(
                          onPressed: () {
                            _openMap(
                              item["address"]!,
                            );
                          },

                          icon: const Icon(
                            Icons.map_outlined,
                          ),

                          label: const Text(
                            "Open in Google Maps",
                          ),

                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(
                                    0xFF2563EB),
                            foregroundColor:
                                Colors.white,

                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                      14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}