
import 'package:flutter/material.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/utils/utils.dart';

class IncomeExpenseTotal extends StatelessWidget {
  const IncomeExpenseTotal({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Divider(
          color: AppColor.secondaryExtraSoft,
          thickness: 1,
        ),
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Total Income",
                        style:
                            TextStyle(color: AppColor.secondary, fontSize: 16),
                      ),
                      Text('+20%',style:
                            TextStyle(color: AppColor.secondarySoft, fontSize: 16))
                    ],
                  ),
                  const Spacer(),
                  Text(
                    r'''$9844.00''',
                    style: TextStyle(
                        color: AppColor.secondary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              verticalSpace(32),
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Total Expense",
                        style:
                            TextStyle(color: AppColor.secondary, fontSize: 16),
                      ),
                     Text('-10%',style:
                            TextStyle(color: AppColor.secondarySoft, fontSize: 16))
                    ],
                  ),
                  const Spacer(),
                  Text(
                    r'''$9844.00''',
                    style: TextStyle(
                        color: AppColor.secondary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              )
            ],
          ),
        ),
        Divider(
          color: AppColor.secondaryExtraSoft,
          thickness: 1,
        ),
      ],
    );
  }
}
