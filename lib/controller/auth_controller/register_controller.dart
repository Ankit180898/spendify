import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendify/main.dart';
import 'package:spendify/widgets/bottom_navigation.dart';
import 'package:spendify/widgets/toast/custom_toast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterController extends GetxController {
  RxBool isLoading = false.obs;
  RxBool isHidden = true.obs;
  var balanceKeypad = TextEditingController();

  var emailC = TextEditingController();
  var passwordC = TextEditingController();
  var nameC = TextEditingController();
  var imageUrl = ''.obs;
  RxString selectedAvatarUrl = ''.obs;
  List<String> avatarList = [
    'https://i.pinimg.com/originals/d4/3d/fb/d43dfb69c55f602950d23b9df2450cb6.jpg', // Add a camera icon
    'https://avatar.iran.liara.run/public/32',
    'https://avatar.iran.liara.run/public/35',
    'https://avatar.iran.liara.run/public/23',
    'https://avatar.iran.liara.run/public/50',
    'https://avatar.iran.liara.run/public/73',
    'https://avatar.iran.liara.run/public/64',
    'https://avatar.iran.liara.run/public/77',
  ];

  @override
  void dispose() {
    super.dispose();
    emailC.dispose();
    passwordC.dispose();
    nameC.dispose();
  }

  // Future pickImage() async {
  //   final picker = ImagePicker();
  //   final pickedFile = await picker.pickImage(source: ImageSource.gallery);
  //   if (pickedFile != null) {
  //     file.value = pickedFile;
  //     return File(pickedFile.path);
  //   }
  //   return null;
  // }

  Future<String?> uploadImage(File imageFile) async {
    final response = await supabaseC.storage
        .from('avatars/pics')
        .upload('${DateTime.now().millisecondsSinceEpoch}', imageFile);
    if (response.isEmpty) {
      return response.toString();
    }
    return null;
  }

  // Future<void> uploadImageAndSaveToSupabase() async {
  //   if (file.value != null) {
  //     final imageUrl = await uploadImage(File(file.value!.path));
  //     if (imageUrl != null) {
  //       await supabaseC.storage.from('avatars/pics').upload(
  //           '${DateTime.now().millisecondsSinceEpoch}', File(file.value!.path));

  //       CustomToast.successToast("Success", "Image Uploaded Successfully");
  //     } else {
  //       CustomToast.errorToast("Failure", "Failed to upload image");
  //     }
  //   }
  // }

  Future<void> register() async {
    if (emailC.text.isNotEmpty &&
        passwordC.text.isNotEmpty &&
        nameC.text.isNotEmpty) {
      isLoading.value = true;
      try {
        AuthResponse res = await supabaseC.auth
            .signUp(password: passwordC.text, email: emailC.text);

        if (res.user != null) {
          await supabaseC.from("users").insert({
            "id": res.user!.id, // Use the user ID returned from auth
            "name": nameC.text,
            "email": emailC.text,
            "balance": 0.0, // Use a double value for balance
            "url": ""
          });
          Get.offAll(const BottomNav());
        }
        isLoading.value = false;
      } catch (e) {
        isLoading.value = false;
        debugPrint("Error during registration: $e");
        CustomToast.errorToast("Error", e.toString());
      }
    } else {
      CustomToast.errorToast("ERROR", "Email, password, and name are required");
    }
  }
}
