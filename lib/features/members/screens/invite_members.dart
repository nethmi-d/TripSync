import 'package:flutter/material.dart';

class InviteMembersScreen extends StatefulWidget {
  const InviteMembersScreen({super.key});

  @override
  State<InviteMembersScreen> createState() =>
      _InviteMembersScreenState();
}

class _InviteMembersScreenState
    extends State<InviteMembersScreen> {
  final TextEditingController emailController =
      TextEditingController();

  final List<Map<String, dynamic>> pendingRequests = [
    {
      "name": "Sarah Johnson",
      "email": "sarah@email.com",
      "role": "Member",
      "time": "2 hours ago",
      "initials": "SJ",
    },
    {
      "name": "Mike Chen",
      "email": "mike@email.com",
      "role": "Admin",
      "time": "5 hours ago",
      "initials": "MC",
    },
    {
      "name": "Emma Wilson",
      "email": "emma@email.com",
      "role": "Member",
      "time": "1 day ago",
      "initials": "EW",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF111827),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Invite Members",
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
            _inviteCard(),

            const SizedBox(height: 18),

            _pendingRequestsCard(),
          ],
        ),
      ),
    );
  }

  Widget _inviteCard() {
    return Container(
      padding: const EdgeInsets.all(18),
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
          Row(
            children: const [
              CircleAvatar(
                radius: 18,
                backgroundColor:
                    Color(0xFFE8F1FF),
                child: Icon(
                  Icons.person_add_alt_1,
                  color: Color(0xFF2563EB),
                ),
              ),
              SizedBox(width: 10),
              Text(
                "Invite Members",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          const Text(
            "Search users by email and send a join request",
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 18),

          TextField(
            controller: emailController,
            decoration: InputDecoration(
              hintText: "Search by email",
              prefixIcon:
                  const Icon(Icons.email_outlined),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                final email =
                    emailController.text.trim();

                if (email.isEmpty) return;

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  SnackBar(
                    content: Text(
                      "Request sent to $email",
                    ),
                  ),
                );

                emailController.clear();
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(14),
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
                    "Request to Join",
                    style: TextStyle(
                      fontWeight:
                          FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pendingRequestsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
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
              const Text(
                "Pending Requests",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const Spacer(),

              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F1FF),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    pendingRequests.length
                        .toString(),
                    style: const TextStyle(
                      color: Color(0xFF2563EB),
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          ...pendingRequests.map(
            (request) =>
                _requestTile(request),
          ),
        ],
      ),
    );
  }

  Widget _requestTile(
      Map<String, dynamic> request) {
    final isAdmin =
        request["role"] == "Admin";

    return Container(
      margin:
          const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
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
                  request["initials"],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight:
                        FontWeight.w600,
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
                      request["name"],
                      style: const TextStyle(
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                    Text(
                      request["email"],
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      request["time"],
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFFF3F4F6),
                    borderRadius:
                        BorderRadius.circular(
                            10),
                  ),
                  child: const Center(
                    child: Text(
                      "Member",
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isAdmin
                        ? const Color(
                            0xFFF3E8FF)
                        : const Color(
                            0xFFF3F4F6),
                    borderRadius:
                        BorderRadius.circular(
                            10),
                  ),
                  child: Center(
                    child: Text(
                      request["role"],
                      style: TextStyle(
                        color: isAdmin
                            ? const Color(
                                0xFF9333EA)
                            : const Color(
                                0xFF374151),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius:
                      BorderRadius.circular(
                          10),
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.close,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}