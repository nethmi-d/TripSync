import 'package:flutter/material.dart';

class ItineraryScreen extends StatelessWidget {
  const ItineraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final itineraryDays = [
      {
        "day": "Day 1",
        "date": "June 15, 2026",
        "activities": [
          {
            "title": "Arrive at Ngurah Rai Airport",
            "location": "Denpasar",
            "time": "10:00 AM",
            "icon": Icons.flight,
          },
          {
            "title": "Hotel Check-in",
            "location": "Seminyak Beach Resort",
            "time": "12:00 PM",
            "icon": Icons.hotel,
          },
          {
            "title": "Beach Walk & Sunset",
            "location": "Seminyak Beach",
            "time": "3:00 PM",
            "icon": Icons.beach_access,
          },
          {
            "title": "Welcome Dinner",
            "location": "La Plancha Restaurant",
            "time": "7:00 PM",
            "icon": Icons.restaurant,
          },
        ],
      },
      {
        "day": "Day 2",
        "date": "June 16, 2026",
        "activities": [
          {
            "title": "Coffee Plantation Tour",
            "location": "Kintamani",
            "time": "4:00 PM",
            "icon": Icons.coffee,
          },
          {
            "title": "Traditional Balinese Dinner",
            "location": "Ubud",
            "time": "7:00 PM",
            "icon": Icons.dinner_dining,
          },
        ],
      },
      {
        "day": "Day 3",
        "date": "June 17, 2026",
        "activities": [
          {
            "title": "Scuba Diving",
            "location": "Tulamben Beach",
            "time": "9:00 AM",
            "icon": Icons.scuba_diving,
          },
          {
            "title": "Lunch by the Beach",
            "location": "Amed",
            "time": "2:00 PM",
            "icon": Icons.lunch_dining,
          },
          {
            "title": "Temple Visit",
            "location": "Tirta Gangga",
            "time": "5:00 PM",
            "icon": Icons.temple_buddhist,
          },
        ],
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),

      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 60,
              left: 20,
              right: 20,
              bottom: 25,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF2563EB),
                  Color(0xFF06B6D4),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      "Trip Itinerary",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                const Padding(
                  padding:
                      EdgeInsets.only(left: 52),
                  child: Text(
                    "Day-by-day travel schedule",
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...itineraryDays.map(
                  (day) => _DayCard(day),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {},
                    style:
                        ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                                16),
                      ),
                    ),
                    child: Ink(
                      decoration:
                          BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(
                                16),
                        gradient:
                            const LinearGradient(
                          colors: [
                            Color(0xFF2563EB),
                            Color(0xFF06B6D4),
                          ],
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          "+ Add New Activity",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  final Map day;

  const _DayCard(this.day);

  @override
  Widget build(BuildContext context) {
    final activities =
        day["activities"] as List;

    return Container(
      margin: const EdgeInsets.only(
        bottom: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(.05),
            blurRadius: 15,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF2563EB),
                  Color(0xFF06B6D4),
                ],
              ),
              borderRadius:
                  BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      day["day"],
                      style:
                          const TextStyle(
                        color:
                            Colors.white70,
                      ),
                    ),
                    Text(
                      day["date"],
                      style:
                          const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration:
                      BoxDecoration(
                    color: Colors.white24,
                    borderRadius:
                        BorderRadius.circular(
                            20),
                  ),
                  child: Text(
                    "${activities.length} activities",
                    style:
                        const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: List.generate(
                activities.length,
                (index) {
                  final item =
                      activities[index];

                  return _ActivityTile(
                    title: item["title"],
                    location:
                        item["location"],
                    time: item["time"],
                    icon: item["icon"],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final String title;
  final String location;
  final String time;
  final IconData icon;

  const _ActivityTile({
    required this.title,
    required this.location,
    required this.time,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withOpacity(.1),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: const Color(0xFF2563EB),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:
                    const Color(0xFFF9FAFB),
                borderRadius:
                    BorderRadius.circular(
                        16),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style:
                              const TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),

                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration:
                            BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(
                                  12),
                        ),
                        child: Text(
                          time,
                          style:
                              const TextStyle(
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 15,
                        color: Color(
                            0xFF2563EB),
                      ),
                      const SizedBox(
                          width: 4),
                      Text(
                        location,
                        style:
                            const TextStyle(
                          color:
                              Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}