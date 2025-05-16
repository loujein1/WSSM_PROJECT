import 'package:flutter/material.dart';
import '../../constants.dart';

class BackgroundDecoration extends StatelessWidget {
  const BackgroundDecoration({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                kPrimaryColor.withOpacity(0.1),
                kPrimaryLightColor.withOpacity(0.2),
              ],
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          child: Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              color: kPrimaryLightColor,
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
              color: kPrimaryLightColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(100),
              ),
            ),
          ),
        ),
        Positioned(
          top: 50,
          right: 50,
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: kPrimaryColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: 50,
          left: 50,
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: kPrimaryColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          top: 120,
          left: 160,
          child: Container(
            width: 15,
            height: 15,
            decoration: const BoxDecoration(
              color: kPrimaryColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: 160,
          right: 160,
          child: Container(
            width: 15,
            height: 15,
            decoration: const BoxDecoration(
              color: kPrimaryColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
} 