import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendify/main.dart';
import 'package:spendify/widgets/bottom_navigation.dart';
import 'package:spendify/widgets/toast/custom_toast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dart:io';

import 'package:image_picker/image_picker.dart';

class RegisterController extends GetxController {
  RxBool isLoading = false.obs;
  RxBool isHidden = true.obs;
  var balanceKeypad = TextEditingController();

  var emailC = TextEditingController();
  var passwordC = TextEditingController();
  var nameC = TextEditingController();
  Rx<XFile?> file = Rx<XFile?>(null);
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

  Future pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      file.value = pickedFile;
      return File(pickedFile.path);
    }
    return null;
  }

  Future<String?> uploadImage(File imageFile) async {
    final response = await supabaseC.storage
        .from('avatars/pics')
        .upload('${DateTime.now().millisecondsSinceEpoch}', imageFile);
    if (response.isEmpty) {
      return response.toString();
    }
    return null;
  }

  Future<void> uploadImageAndSaveToSupabase() async {
    if (file.value != null) {
      final imageUrl = await uploadImage(File(file.value!.path));
      if (imageUrl != null) {
        await supabaseC.storage.from('avatars/pics').upload(
            '${DateTime.now().millisecondsSinceEpoch}', File(file.value!.path));

        CustomToast.successToast("Success", "Image Uploaded Successfully");
      } else {
        CustomToast.errorToast("Failure", "Failed to upload image");
      }
    }
  }

  Future<void> register() async {
    if (emailC.text.isNotEmpty &&
        passwordC.text.isNotEmpty &&
        nameC.text.isNotEmpty) {
      isLoading.value = true;
      try {
        AuthResponse res = await supabaseC.auth
            .signUp(password: passwordC.text, email: emailC.text);
        isLoading.value = false;

        // insert registered user to table users
        await supabaseC.from("users").insert({
          "name": nameC.text,
          "email": emailC.text,
          "created_at": DateTime.now().toIso8601String(),
          "balance": 12334,
        });

        Get.offAll(const BottomNav());
      } catch (e) {
        isLoading.value = false;
        emailC.clear();
        nameC.clear();
        passwordC.clear();
        file.value = null;
        CustomToast.errorToast("Error", e.toString());
        debugPrint(e.toString());
      }
    } else {
      CustomToast.errorToast("ERROR", "Email, password and name are required");
    }
  }
}
