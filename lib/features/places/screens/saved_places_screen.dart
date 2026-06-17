import 'package:flutter/material.dart';

class SavedPlacesScreen extends StatelessWidget {
  const SavedPlacesScreen({super.key});

  Future<void> openMap(String query) async {
    final Uri url = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$query",
    );
  }

  @override
  Widget build(BuildContext context) {

    final places = [

      {
        "name": "Tanah Lot Temple",
        "location": "Beraban, Tabanan Regency",
        "note": "Best sunset view! Go around 5:30 PM",
        "addedBy": "You",
        "image":
            "https://images.unsplash.com/photo-1537996194471-e657df975ab4",
      },

      {
        "name": "Tegalalang Rice Terraces",
        "location": "Tegallalang, Gianyar Regency",
        "note":
            "Perfect for morning photos. Bring cash for entrance fee",
        "addedBy": "Sarah Johnson",
        "image":
            "https://images.unsplash.com/photo-1518509562904-e7ef99cdcc86",
      },

      {
        "name": "Uluwatu Temple",
        "location": "Uluwatu, Bali",
        "note":
            "Watch the Kecak Fire Dance performance",
        "addedBy": "Mike Chen",
        "image":
            "https://images.unsplash.com/photo-1555400038-63f5ba517a47",
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text(
          "Saved Places",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: places.length,

        itemBuilder: (context, index) {

          final place = places[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 16),

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

                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),

                  child: Stack(
                    children: [

                      Image.network(
                        place["image"]!,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),

                      Positioned(
                        bottom: 12,
                        left: 12,

                        child: Text(
                          place["name"]!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(14),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      Row(
                        children: [

                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Colors.grey,
                          ),

                          const SizedBox(width: 4),

                          Expanded(
                            child: Text(
                              place["location"]!,
                              style: const TextStyle(
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),

                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius:
                              BorderRadius.circular(12),
                        ),

                        child: Text(
                          place["note"]!,
                          style: const TextStyle(
                            fontSize: 13,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [

                          Expanded(
                            child: Text(
                              "Added by ${place["addedBy"]}",
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ),

                          ElevatedButton.icon(
                            onPressed: () {
                              openMap(
                                place["location"]!,
                              );
                            },

                            style:
                                ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(
                                      0xFFDCFCE7),
                              foregroundColor:
                                  Colors.green,
                              elevation: 0,
                            ),

                            icon: const Icon(
                              Icons.map_outlined,
                              size: 18,
                            ),

                            label: const Text(
                              "Maps",
                            ),
                          ),

                          const SizedBox(width: 8),

                          Container(
                            decoration: BoxDecoration(
                              color: const Color(
                                  0xFFFEE2E2),
                              borderRadius:
                                  BorderRadius.circular(
                                      10),
                            ),

                            child: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),

                              onPressed: () {},
                            ),
                          ),
                        ],
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