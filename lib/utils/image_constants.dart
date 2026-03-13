import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ImageConstants {
  final Color colors;

  // Constructor accepting a Color parameter and initializing the 'colors' property
  ImageConstants({required this.colors});

  // Define static icons and set their color based on the 'colors' property
  PhosphorIcon get success => PhosphorIcon(PhosphorIconsFill.checkCircle, color: colors);
  PhosphorIcon get failure => PhosphorIcon(PhosphorIconsFill.info, color: colors);
  PhosphorIcon get settings => PhosphorIcon(PhosphorIconsLight.gear, color: colors);
  PhosphorIcon get home => PhosphorIcon(PhosphorIconsLight.house, color: colors);
  PhosphorIcon get profile => PhosphorIcon(PhosphorIconsLight.user, color: colors);
  PhosphorIcon get search => PhosphorIcon(PhosphorIconsLight.magnifyingGlass, color: colors);
  PhosphorIcon get trash => PhosphorIcon(PhosphorIconsLight.trash, color: colors);
  PhosphorIcon get income => PhosphorIcon(PhosphorIconsLight.arrowUp, color: colors);
  PhosphorIcon get expense => PhosphorIcon(PhosphorIconsLight.arrowDown, color: colors);
  PhosphorIcon get avatar => PhosphorIcon(PhosphorIconsLight.camera, color: colors);
  PhosphorIcon get leftArrow => PhosphorIcon(PhosphorIconsLight.arrowLeft, color: colors);
  PhosphorIcon get rightArrow => PhosphorIcon(PhosphorIconsLight.arrowRight, color: colors);
  PhosphorIcon get plus => PhosphorIcon(PhosphorIconsRegular.plus, color: colors);
  PhosphorIcon get close => PhosphorIcon(PhosphorIconsLight.x, color: colors);
  PhosphorIcon get wallet => PhosphorIcon(PhosphorIconsLight.wallet, color: colors);
}
