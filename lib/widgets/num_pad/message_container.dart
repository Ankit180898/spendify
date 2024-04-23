import 'package:flutter/material.dart';


class MessageContainer extends StatelessWidget {
   const MessageContainer({super.key});

  final double height = 50;


  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
       
        Expanded(
          child: Container(
            height: height,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 40,
                    spreadRadius: 2,
                  )
                ]),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              cursorColor: Colors.black,
              decoration: InputDecoration(
                hintText: "Say Something",
                hintStyle: TextStyle(color: Colors.grey.shade300),
                border: InputBorder.none,
                contentPadding: EdgeInsets.only(bottom: height / 4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
