import 'package:flutter/material.dart';

/// The same squirrel artwork used by the installed application's icons.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 72});
  final double size;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(size * 0.22),
    child: Image.asset('assets/brand/logo.png', width: size, height: size,
        fit: BoxFit.contain, semanticLabel: 'Ratatosk squirrel logo'),
  );
}
