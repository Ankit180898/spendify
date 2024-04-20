import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/auth_controller/register_controller.dart';
import 'package:spendify/utils/size_helpers.dart';
import 'package:spendify/widgets/custom_button.dart';
import 'package:spendify/widgets/toast/custom_toast.dart';

class AvatarPickerDialog extends StatefulWidget {
  const AvatarPickerDialog({super.key});

  @override
  _AvatarPickerDialogState createState() => _AvatarPickerDialogState();
}

class _AvatarPickerDialogState extends State<AvatarPickerDialog> {
  final controller = Get.find<RegisterController>();

  // RxString to hold the selected avatar URL
  RxString selectedAvatarUrl = ''.obs;
  var isFile = false.obs;
  XFile? file;

  // ImagePicker instance
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text('Pick an Avatar'),
      ),
      body: Column(
        children: [
          // Main content of the dialog
          Expanded(
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                
              ),
              itemCount: controller.avatarList.length,
              itemBuilder: (context, index) {
                var avatarUrl = controller.avatarList[index];

                // Handle the camera image click
                if (avatarUrl ==
                    'https://i.pinimg.com/originals/d4/3d/fb/d43dfb69c55f602950d23b9df2450cb6.jpg') {
                  return AvatarItem(
                    isFile: file!.path.isEmpty?false:true,
                    avatarUrl: file!.path.isEmpty?avatarUrl:file!.path,
                    isSelected: false,
                    onTap: () => showBottomSheetOptions(context),
                  );
                } else {
                  // Handle the regular avatar selection
                  return AvatarItem(
                    isFile: false,
                    avatarUrl: avatarUrl,
                    isSelected: avatarUrl == selectedAvatarUrl.value,
                    onTap: () {
                      selectedAvatarUrl.value = avatarUrl.toString();
                    },
                  );
                }
              },
            ),
          ),
          // "Get Started" button at the bottom of the screen
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: CustomButton(
              isCenter: true,
              text: "Get Started",
              onPressed: () {
                // Check if an avatar is selected
                if (selectedAvatarUrl.value.isNotEmpty) {
                } else {
                  // Display a message if no avatar is selected
                  Get.snackbar(
                    'No Avatar Selected',
                    'Please select an avatar before proceeding.',
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              },
              bgcolor: AppColor.secondary,
              height: displayHeight(context) * 0.08,
              width: displayWidth(context),
              textSize: 16,
              textColor: AppColor.secondaryExtraSoft,
            ),
          ),
        ],
      ),
    );
  }

  // Function to handle bottom sheet options
  void showBottomSheetOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  pickImage(ImageSource.gallery);
                  
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera),
                title: const Text('Camera'),
                onTap: () {
                  pickImage(ImageSource.camera);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Function to handle image picking
Future<void> pickImage(ImageSource source) async {
    isFile.value = true;
    // Use image picker to pick an image from the specified source (gallery or camera)
    final pickedFile = await _picker.pickImage(
        source: source,
    );

    if (pickedFile != null) {
        // Update the state with the new image URL
        file = pickedFile; // Assign pickedFile directly to file variable
    } else {
        // Handle the case where no image is selected (e.g., user cancels the operation)

        CustomToast.errorToast('No Image Selected',
            'Please select an image from the gallery or camera.');
    }
}
}

class AvatarItem extends StatelessWidget {
  var avatarUrl;
  final bool isSelected;
  final bool isFile;
  final VoidCallback onTap;

  AvatarItem({
    required this.avatarUrl,
    required this.isSelected,
    required this.onTap,
    super.key,
    required this.isFile,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Display the avatar image
          CircleAvatar(
            radius: 40,
            child: isFile == true
                ? Image.file(File(avatarUrl))
                : Image.network(avatarUrl),
          ),
          // Display selection ring if avatar is selected
          if (isSelected)
            Container(
              width: 85,
              height: 85,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.blue,
                  width: 3,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
