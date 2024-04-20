import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:spendify/config/app_color.dart';
import 'package:spendify/utils/image_constants.dart';

class CustomSpeedDial extends StatefulWidget {
  final List<CustomSpeedDialChild> children;
  final double buttonSize;
  final double spacing;


  CustomSpeedDial({
    required this.children,
    this.buttonSize = 56.0,
    this.spacing = 16.0,
  });

  @override
  _CustomSpeedDialState createState() => _CustomSpeedDialState();
}

class _CustomSpeedDialState extends State<CustomSpeedDial>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotateAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 200));
    _rotateAnimation =
        Tween<double>(begin: 0, end: math.pi / 2).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      _isOpen ? _animationController.forward() : _animationController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (int i = 0; i < widget.children.length; i++)
          AnimatedBuilder(
            animation: _rotateAnimation,
            builder: (context, child) {
              final angle = math.pi / 2 * i;
              final offsetX =
                  math.cos(angle + math.pi / 4) * (widget.buttonSize + widget.spacing);
              final offsetY =
                  math.sin(angle + math.pi / 4) * (widget.buttonSize + widget.spacing);

              return Positioned(
                right: 16.0 + offsetX,
                bottom: 16.0 + offsetY,
                child: ImageConstants(colors: Colors.white).plus,
              );
            },
            child: Visibility(
              visible: _isOpen,
              child: widget.children[i],
            ),
          ),
        Positioned(
          right: 16.0,
          bottom: 16.0,
          child: FloatingActionButton(
            onPressed: _toggle,
            backgroundColor: AppColor.primaryExtraSoft,
            child: AnimatedIcon(
              icon: AnimatedIcons.close_menu,
              progress: _rotateAnimation,
            ),
          ),
        ),
      ],
    );
  }
}

class CustomSpeedDialChild extends StatelessWidget {
  final IconData icon;
  final Color backgroundColor;
  final VoidCallback onTap;

  CustomSpeedDialChild({
    required this.icon,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: backgroundColor,
      onPressed: onTap,
      child: Icon(icon),
    );
  }
}
