import 'package:flutter/material.dart';

class TripSettingsScreen extends StatefulWidget {
  const TripSettingsScreen({super.key});

  @override
  State<TripSettingsScreen> createState() =>
      _TripSettingsScreenState();
}

class _TripSettingsScreenState
    extends State<TripSettingsScreen> {
  final tripNameController =
      TextEditingController(text: "Bali Adventure 2026");

  String coverImage =
    "https://images.unsplash.com/photo-1537996194471-e657df975ab4";

  final members = [
    {
      "name": "You",
      "email": "you@email.com",
      "role": "Admin",
      "canRemove": false,
      "initials": "Y",
    },
    {
      "name": "Sarah Johnson",
      "email": "sarah@email.com",
      "role": "Admin",
      "canRemove": true,
      "initials": "SJ",
    },
    {
      "name": "Mike Chen",
      "email": "mike@email.com",
      "role": "Member",
      "canRemove": true,
      "initials": "MC",
    },
    {
      "name": "Emma Wilson",
      "email": "emma@email.com",
      "role": "Admin",
      "canRemove": true,
      "initials": "EW",
    },
    {
      "name": "Alex Taylor",
      "email": "alex@email.com",
      "role": "Member",
      "canRemove": true,
      "initials": "AT",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF111827),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Trip Settings",
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            _tripDetailsCard(),

            const SizedBox(height: 16),

            _membersCard(),

            const SizedBox(height: 20),

            _saveButton(),

            const SizedBox(height: 16),

            _dangerZone(),
          ],
        ),
      ),
    );
  }

  Widget _coverImageSection() {
  return Column(
    crossAxisAlignment:
        CrossAxisAlignment.start,
    children: [
      const Text(
        "Cover Image",
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),

      const SizedBox(height: 10),

      Stack(
        children: [
          ClipRRect(
            borderRadius:
                BorderRadius.circular(16),
            child: Image.network(
              "https://images.unsplash.com/photo-1537996194471-e657df975ab4",
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          Positioned(
            right: 12,
            bottom: 12,
            child: Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.edit,
                  color: Color(0xFF2563EB),
                ),
                onPressed: () {
                  // TODO image picker
                },
              ),
            ),
          ),
        ],
      ),
    ],
  );
}


  Widget _tripDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.edit_outlined,
                color: Color(0xFF2563EB),
              ),
              SizedBox(width: 8),
              Text(
                "Trip Details",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          _coverImageSection(),

          const SizedBox(height: 20),

          const Text("Trip Name"),

          const SizedBox(height: 8),

          TextField(
            controller: tripNameController,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _dateField(
                  "Start Date",
                  "06/15/2026",
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _dateField(
                  "End Date",
                  "06/25/2026",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dateField(
    String label,
    String value,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(label),

        const SizedBox(height: 8),

        Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius:
                BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_month,
                size: 18,
                color: Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(value),
            ],
          ),
        ),
      ],
    );
  }

  Widget _membersCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.group_outlined,
                color: Color(0xFF2563EB),
              ),

              const SizedBox(width: 8),

              const Text(
                "Manage Members",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const Spacer(),

              Text(
                "${members.length} members",
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          ...members.map(
            (member) => _memberTile(member),
          ),
        ],
      ),
    );
  }

  Widget _memberTile(
    Map<String, dynamic> member,
  ) {
    final isAdmin =
        member["role"] == "Admin";

    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor:
                    const Color(0xFF1D9BF0),
                child: Text(
                  member["initials"],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      member["name"],
                      style: const TextStyle(
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                    Text(
                      member["email"],
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              if (member["canRemove"])
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.close,
                    color: Colors.red,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: isAdmin
                  ? const Color(0xFFF3E8FF)
                  : const Color(0xFFF3F4F6),
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                member["role"],
                style: TextStyle(
                  color: isAdmin
                      ? const Color(
                          0xFF9333EA,
                        )
                      : const Color(
                          0xFF374151,
                        ),
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _saveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {},

        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(16),
          ),
        ),

        child: Ink(
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(16),
            gradient:
                const LinearGradient(
              colors: [
                Color(0xFF0EA5E9),
                Color(0xFF2563EB),
              ],
            ),
          ),
          child: const Center(
            child: Text(
              "Save Changes",
              style: TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dangerZone() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: Colors.red.shade200,
        ),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.delete_outline,
                color: Colors.red,
              ),
              SizedBox(width: 8),
              Text(
                "Danger Zone",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          const Text(
            "Deleting this trip will permanently remove all data including expenses, settlements, itinerary and images.",
            style: TextStyle(
              color: Colors.black54,
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text(
                "Delete Trip",
              ),
            ),
          ),
        ],
      ),
    );
  }
}