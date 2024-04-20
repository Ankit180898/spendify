import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class ImageConstants {
  final Color colors;

  // Constructor accepting a Color parameter and initializing the 'colors' property
  ImageConstants({required this.colors});

  // Define static icons and set their color based on the 'colors' property
  Icon get success => Icon(Iconsax.tick_circle, color: colors);
  Icon get failure => Icon(Iconsax.info_circle, color: colors);
  Icon get settings => Icon(Icons.settings, color: colors);
  Icon get home => Icon(Iconsax.home, color: colors);
  Icon get profile => Icon(Iconsax.profile, color: colors);
  Icon get search => Icon(Iconsax.search_normal, color: colors);
  Icon get trash => Icon(Iconsax.trash, color: colors);
  Icon get income => Icon(Icons.arrow_upward_rounded, color: colors);
  Icon get expense => Icon(Icons.arrow_downward_rounded, color: colors);
  Icon get avatar => Icon(Icons.camera, color: colors);
  Icon get leftArrow => Icon(Iconsax.arrow_left, color: colors);
  Icon get rightArrow => Icon(Iconsax.arrow_right, color: colors);
  Icon get plus => Icon(Iconsax.add, color: colors);
  Icon get close => Icon(Iconsax.clipboard_close, color: colors);
    Icon get wallet => Icon(Iconsax.wallet, color: colors);

}
