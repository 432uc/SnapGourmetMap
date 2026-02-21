import 'dart:io';
import 'package:image/image.dart' as img;

class ImageHelper {
  /// Rotating an image by 90 degrees clockwise and saving it back to the same path.
  static Future<void> rotateImage(String path) async {
    final bytes = await File(path).readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    
    if (image == null) return;

    // Rotate 90 degrees clockwise
    img.Image rotated = img.copyRotate(image, angle: 90);

    // Save back
    await File(path).writeAsBytes(img.encodeJpg(rotated));
  }
}
