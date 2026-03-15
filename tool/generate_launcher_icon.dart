import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  const size = 1024;

  final logoFile = File('assets/app_logo.png');
  if (!logoFile.existsSync()) {
    print('Error: assets/app_logo.png not found');
    exit(1);
  }

  var logo = img.decodePng(logoFile.readAsBytesSync())!;

  // Trim any transparent/blank padding around the actual icon
  logo = img.trim(logo);

  // Scale to full canvas
  logo = img.copyResize(logo, width: size, height: size,
      interpolation: img.Interpolation.cubic);

  File('assets/launcher_icon.png').writeAsBytesSync(img.encodePng(logo));
  print('Generated assets/launcher_icon.png (${size}x$size)');
}
