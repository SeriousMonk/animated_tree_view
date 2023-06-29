import 'package:flutter/material.dart';

class Disabled extends StatelessWidget {
  final Widget child;

  const Disabled({
    required this.child
  });

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        Colors.grey.withOpacity(0.5),
        BlendMode.srcOver,
      ),
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(
          Colors.grey,
          BlendMode.saturation,
        ),
        child: child,
      ),
    );
  }
}