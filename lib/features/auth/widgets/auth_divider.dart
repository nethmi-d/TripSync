import 'package:flutter/material.dart';

class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _line()),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'or continue with',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
          ),
        ),
        Expanded(child: _line()),
      ],
    );
  }

  Widget _line() {
    return Container(height: 1, color: const Color(0xFFE5E7EB));
  }
}
