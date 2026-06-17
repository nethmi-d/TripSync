import 'package:flutter/material.dart';

class AddExpensesScreen extends StatefulWidget {
  const AddExpensesScreen({super.key});

  @override
  State<AddExpensesScreen> createState() => _AddExpensesScreenState();
}

class _AddExpensesScreenState extends State<AddExpensesScreen> {

  final titleController = TextEditingController();
  final amountController = TextEditingController();

  String? paidBy;
  String? category;

  final members = [
    "You",
    "Sarah Chen",
    "Mike Johnson",
    "Emma Davis",
    "Alex Kim",
    "Lisa Park",
  ];

  final Set<String> selectedMembers = {
    "You",
    "Sarah Chen",
    "Alex Kim",
    "Lisa Park",
  };

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      appBar: AppBar(
        backgroundColor: const Color(0xFFD946EF),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Add Expense",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const SizedBox(height: 10),

            const Text(
              "Record a new group expense",
              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 20),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),

              child: Padding(
                padding: const EdgeInsets.all(16),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text("Expense Title"),

                    const SizedBox(height: 8),

                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: "e.g., Dinner at Restaurant",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text("Amount"),

                    const SizedBox(height: 8),

                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,

                      decoration: InputDecoration(
                        prefixText: "\$ ",
                        hintText: "0.00",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text("Paid By"),

                    const SizedBox(height: 8),

                    DropdownButtonFormField<String>(
                      value: paidBy,

                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),

                      items: members.map((member) {
                        return DropdownMenuItem(
                          value: member,
                          child: Text(member),
                        );
                      }).toList(),

                      onChanged: (value) {
                        setState(() {
                          paidBy = value;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    const Text("Category"),

                    const SizedBox(height: 8),

                    DropdownButtonFormField<String>(
                      value: category,

                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),

                      items: [
                        "Food",
                        "Transport",
                        "Hotel",
                        "Entertainment",
                        "Shopping"
                      ].map((e) {
                        return DropdownMenuItem(
                          value: e,
                          child: Text(e),
                        );
                      }).toList(),

                      onChanged: (value) {
                        setState(() {
                          category = value;
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      "Split Between",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 10,
                      runSpacing: 10,

                      children: members.map((member) {

                        final selected =
                            selectedMembers.contains(member);

                        return GestureDetector(
                          onTap: () {

                            setState(() {

                              if (selected) {
                                selectedMembers.remove(member);
                              } else {
                                selectedMembers.add(member);
                              }
                            });
                          },

                          child: Container(
                            width: 150,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),

                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),

                              border: Border.all(
                                color: selected
                                    ? Colors.purple
                                    : Colors.grey.shade300,
                              ),
                            ),

                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,

                              children: [

                                Text(member),

                                Icon(
                                  selected
                                      ? Icons.check_circle
                                      : Icons.circle_outlined,

                                  color: selected
                                      ? Colors.purple
                                      : Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "${selectedMembers.length} members selected",
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 55,

                      child: ElevatedButton(
                        onPressed: () {},

                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                        ),

                        child: const Text(
                          "Add Expense",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      height: 50,

                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },

                        child: const Text("Cancel"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}