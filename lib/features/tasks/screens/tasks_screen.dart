import 'package:flutter/material.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {

  final pendingTasks = [
    {
      "title": "Book scuba diving tour",
      "date": "Due May 10",
      "person": "Sarah",
      "priority": "high",
      "color": Colors.red,
    },
    {
      "title": "Get travel insurance",
      "date": "Due May 12",
      "person": "You",
      "priority": "high",
      "color": Colors.red,
    },
    {
      "title": "Confirm hotel check-in",
      "date": "Due May 15",
      "person": "Mike",
      "priority": "medium",
      "color": Colors.orange,
    },
    {
      "title": "Research local restaurants",
      "date": "Due May 20",
      "person": "Emma",
      "priority": "low",
      "color": Colors.blue,
    },
    {
      "title": "Pack sunscreen and hats",
      "date": "Due June 10",
      "person": "Lisa",
      "priority": "medium",
      "color": Colors.orange,
    },
  ];

  final completedTasks = [
    {
      "title": "Download offline maps",
      "date": "Due June 12",
      "person": "Alex",
    },
    {
      "title": "Print boarding passes",
      "date": "Due June 13",
      "person": "Sarah",
    },
  ];

  @override
  Widget build(BuildContext context) {

    const totalTasks = 7;
    const pending = 5;
    const completed = 2;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),

      body: Column(
        children: [

          Container(
            padding: const EdgeInsets.only(
              top: 60,
              left: 20,
              right: 20,
              bottom: 24,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF8B5CF6),
                  Color(0xFF7C3AED),
                ],
              ),
            ),
            child: Column(
              children: [

                Row(
                  children: [

                    CircleAvatar(
                      backgroundColor: Colors.white24,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),

                    const SizedBox(width: 16),

                    const Expanded(
                      child: Text(
                        "Tasks",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    CircleAvatar(
                      backgroundColor: Colors.white24,
                      child: IconButton(
                        icon: const Icon(
                          Icons.add,
                          color: Colors.white,
                        ),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Manage trip preparations",
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.08),
                          blurRadius: 12,
                        )
                      ],
                    ),
                    child: Column(
                      children: [

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceAround,
                          children: const [

                            _StatItem(
                              value: "7",
                              label: "Total Tasks",
                              color: Colors.black,
                            ),

                            _StatItem(
                              value: "5",
                              label: "Pending",
                              color: Colors.purple,
                            ),

                            _StatItem(
                              value: "2",
                              label: "Completed",
                              color: Colors.green,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(20),
                          child:
                              const LinearProgressIndicator(
                            value: 0.29,
                            minHeight: 10,
                            color: Color(0xFF8B5CF6),
                          ),
                        ),

                        const SizedBox(height: 10),

                        const Text("29% complete"),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  _sectionTitle(
                    "Pending Tasks",
                    "5 tasks",
                  ),

                  const SizedBox(height: 12),

                  ...pendingTasks.map(
                    (task) => _pendingTaskCard(task),
                  ),

                  const SizedBox(height: 24),

                  _sectionTitle(
                    "Completed Tasks",
                    "2 tasks",
                  ),

                  const SizedBox(height: 12),

                  ...completedTasks.map(
                    (task) => _completedTaskCard(task),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(
    String title,
    String count,
  ) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          count,
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _pendingTaskCard(Map task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [

          const Icon(
            Icons.radio_button_unchecked,
            color: Colors.grey,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                Text(
                  task["title"],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [

                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey,
                    ),

                    const SizedBox(width: 4),

                    Text(task["date"]),

                    const SizedBox(width: 12),

                    Text(task["person"]),

                    const SizedBox(width: 12),

                    Text(
                      task["priority"],
                      style: TextStyle(
                        color: task["color"],
                        fontWeight: FontWeight.bold,
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
  }

  Widget _completedTaskCard(Map task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFAF2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [

          const Icon(
            Icons.check_circle,
            color: Colors.green,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                Text(
                  task["title"],
                  style: const TextStyle(
                    decoration:
                        TextDecoration.lineThrough,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  "${task["date"]}   ${task["person"]}",
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {

  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label),
      ],
    );
  }
}