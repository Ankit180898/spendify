import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/auth_controller/login_controller.dart';
import 'package:spendify/utils/size_helpers.dart';
import 'package:spendify/utils/utils.dart';
import 'package:spendify/widgets/custom_button.dart';
import '../../routes/app_pages.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController());
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        // leading: ImageConstants.leftArrow,
      ),
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: Material(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColor.secondarySoft,
                    fontSize: 16),
                "Don't have an account?",
              ),
              TextButton(
                  onPressed: () {
                    Get.offAllNamed(Routes.REGISTER);
                  },
                  child: Text(
                    "Register",
                    style: TextStyle(color: AppColor.primary, fontSize: 16),
                  ))
            ],
          ),
        ),
      ),
      body: ListView(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        children: [
          Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            color: Colors.white,
            padding: const EdgeInsets.only(left: 24, right: 24, top: 36),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: const Text(
                    'Sign In',
                    style: TextStyle(
                      fontSize: 24,
                      fontFamily: 'poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                verticalSpace(16),
                Container(
                  width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsets.only(left: 14, right: 14, top: 4),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        width: 1, color: AppColor.secondaryExtraSoft),
                  ),
                  child: TextField(
                    style: const TextStyle(fontSize: 14, fontFamily: 'poppins'),
                    maxLines: 1,
                    controller: controller.emailC,
                    decoration: InputDecoration(
                      label: Text(
                        "Email",
                        style: TextStyle(
                          color: AppColor.secondarySoft,
                          fontSize: 14,
                        ),
                      ),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      border: InputBorder.none,
                      hintText: "youremail@email.com",
                      hintStyle: TextStyle(
                        fontSize: 14,
                        fontFamily: 'poppins',
                        fontWeight: FontWeight.w500,
                        color: AppColor.secondarySoft,
                      ),
                    ),
                  ),
                ),
                verticalSpace(8),
                Container(
                  width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsets.only(left: 14, right: 14, top: 4),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        width: 1, color: AppColor.secondaryExtraSoft),
                  ),
                  child: Obx(
                    () => TextField(
                      style:
                          const TextStyle(fontSize: 14, fontFamily: 'poppins'),
                      maxLines: 1,
                      controller: controller.passwordC,
                      obscureText: controller.isHidden.value,
                      decoration: InputDecoration(
                        label: Text(
                          "Password",
                          style: TextStyle(
                            color: AppColor.secondarySoft,
                            fontSize: 14,
                          ),
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        border: InputBorder.none,
                        hintText: "*************",
                        suffixIcon: IconButton(
                          icon: (controller.isHidden.value != false)
                              ? const Icon(Iconsax.eye)
                              : const Icon(Iconsax.eye_slash4),
                          onPressed: () {
                            controller.isHidden.value =
                                !(controller.isHidden.value);
                          },
                        ),
                        hintStyle: TextStyle(
                          fontSize: 14,
                          fontFamily: 'poppins',
                          fontWeight: FontWeight.w500,
                          color: AppColor.secondarySoft,
                        ),
                      ),
                    ),
                  ),
                ),
                verticalSpace(16),
                Obx(() => CustomButton(
                    text: controller.isLoading.isFalse ? "Login" : "Loading",
                    onPressed: () {
                      if (controller.isLoading.isFalse) {
                        controller.login();
                      }
                    },
                    bgcolor: AppColor.primary,
                    height: displayHeight(context) * 0.08,
                    width: displayWidth(context),
                    textSize: 16,
                    textColor: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
