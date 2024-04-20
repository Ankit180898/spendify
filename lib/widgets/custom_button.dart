import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color bgcolor;
  final Color textColor;
  final double borderRadius;
  final double height;
  final double width;
  final double textSize;
  final bool isCenter;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.bgcolor,
    required this.height,
    required this.width,
    required this.textSize,
    required this.textColor,
    this.isCenter=true,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onPressed,
        child: Container(
          decoration: BoxDecoration(
            color: bgcolor,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child:isCenter==true? Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  text,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor),
                ),
              ),
            ),
          ):Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      text,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor),
                    ),
                  ),
                  const Spacer(),
                  Lottie.asset("assets/right_arrow.json",height: 24)
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
