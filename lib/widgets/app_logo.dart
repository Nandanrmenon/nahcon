import 'package:flutter/material.dart';

class AppLogo extends StatefulWidget {
  final double? width;
  final double? height;
  final double? borderRadius;
  final BoxFit? boxFit;

  const AppLogo({super.key, this.width, this.height, this.borderRadius, this.boxFit});

  @override
  State<AppLogo> createState() => _AppLogoState();
}

class _AppLogoState extends State<AppLogo> {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius ?? 999),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          'assets/nahCon.png',
          width: widget.width ?? 64,
          height: widget.height ?? 64,
          fit: widget.boxFit ?? BoxFit.cover,
        ));
  }
}
