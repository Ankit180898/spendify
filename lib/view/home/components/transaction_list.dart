
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/utils/image_constants.dart';

class TransactionsContent extends StatelessWidget {
  const TransactionsContent({super.key});

  @override
  Widget build(BuildContext context) {
    List<String> transactionList = [
      'Transaction 1',
      'Income 2',
      'Transaction 1',
      'Income 2',
      'Transaction 1',
      'Income 2',
      'Transaction 1',
      'Income 2',
      'Transaction 1',
      'Income 2',
    ];
    DateTime now = DateTime.now(); // Get the current date and time

// Format the date to display the day of the month
    String formattedDate = DateFormat("d").format(now);

// Check if the date is today
    String dateDisplay;
    if (now.day == DateTime.now().day) {
      formattedDate = DateFormat("hh:mm a").format(now);
      dateDisplay = "Today, $formattedDate";
    } else {
      dateDisplay = formattedDate;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0),
          child: Text(
            'TRANSACTIONS',
            style: TextStyle(color: AppColor.secondarySoft, fontSize: 16,fontWeight: FontWeight.w500),
          ),
        ),
        ListView.builder(
          padding: const EdgeInsets.all(0),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactionList.length,
          itemBuilder: (context, index) {
            var i = transactionList[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
              child: ListTile(
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColor.secondaryExtraSoft,
                  child: ImageConstants(colors: AppColor.secondary).home,
                ),
                title: Text(
                  i,
                  style: const TextStyle(fontSize: 16),
                ),
                subtitle: Text(
                  dateDisplay,
                  style: TextStyle(fontSize: 14, color: AppColor.secondarySoft),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ImageConstants(colors: AppColor.success).income,
                    const Text("\$100"),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
