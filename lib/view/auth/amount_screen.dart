import 'package:flutter/material.dart';
import 'package:spendify/widgets/num_pad/keyboard_pad.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    super.key,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with SingleTickerProviderStateMixin {
  bool showContent = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return const Scaffold(
      body: Stack(
        children: [
          Expanded(
            child: KeyboardPad(),
          )
        ],
      ),
    );
  }
}
