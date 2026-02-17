import 'dart:convert';
import 'package:flutter/material.dart';

class Logo extends StatelessWidget {
  final double size;
  final String initials;

  const Logo({
    Key? key,
    this.size = 56,
    this.initials = 'ET',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Try to load an image asset first; if it fails, show the gradient initials fallback.
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 6),
      child: SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          'assets/logo.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Use an embedded sample PNG (1x1) as a fallback image so a real image displays.
            const samplePngBase64 =
                'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGNgYAAAAAMAASsJTYQAAAAASUVORK5CYII=';
            final bytes = base64Decode(samplePngBase64);
            return Image.memory(bytes, fit: BoxFit.cover);
          },
        ),
      ),
    );
  }
}
