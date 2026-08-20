import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final iconFile = File('gymlog_app_icon.png');
  if (!iconFile.existsSync()) {
    print('gymlog_app_icon.png not found');
    exit(1);
  }

  final image = img.decodePng(iconFile.readAsBytesSync());
  if (image == null) {
    print('Failed to decode gymlog_app_icon.png');
    exit(1);
  }

  final densities = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };

  for (final entry in densities.entries) {
    final folder = 'android/app/src/main/res/${entry.key}';
    final targetDir = Directory(folder);
    if (!targetDir.existsSync()) {
      targetDir.createSync(recursive: true);
    }
    final resized = img.copyResize(image, width: entry.value, height: entry.value);
    final outFile = File('$folder/ic_launcher.png');
    outFile.writeAsBytesSync(img.encodePng(resized));
    print('Generated $folder/ic_launcher.png (${entry.value}x${entry.value})');
  }

  print('All Android launcher icons generated successfully!');
}
