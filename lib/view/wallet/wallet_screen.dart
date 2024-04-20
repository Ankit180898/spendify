import 'package:flutter/material.dart';
import 'package:spendify/utils/size_helpers.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PreferredSize(
        preferredSize: Size.fromHeight(displayHeight(context)*0.30),
        child: AppBar(
          title: const Text("Wallet"),
          
        ),
      ),
    );
  }
}