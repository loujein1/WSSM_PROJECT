import 'package:flutter/material.dart';

class Background extends StatelessWidget {
  final Widget child;
  const Background({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: Color(0xFFFCE4EC),
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(100),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 160,
              height: 160,
              decoration: const BoxDecoration(
                color: Color(0xFFFCE4EC),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(100),
                ),
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: 30,
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF2196F3),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 80,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF2196F3),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 60,
            right: 40,
            child: Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Color(0xFF2196F3),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.2,
            left: 30,
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF2196F3),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.2,
            right: 50,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF2196F3),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 140,
            left: 40,
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF2196F3),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: 30,
            child: Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Color(0xFF2196F3),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: 80,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF2196F3),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.4,
            right: 60,
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: Color(0xFF2196F3),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.3,
            left: 50,
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xFF2196F3),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(child: child),
        ],
      ),
    );
  }
} 