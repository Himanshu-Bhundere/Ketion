import 'package:flutter_test/flutter_test.dart';
import 'package:ketion/core/theme/media_dimensions.dart';

void main() {
  group('MediaDimensions Specifications', () {
    test('standard 16:9 media dimensions are configured accurately', () {
      expect(MediaDimensions.width, 480.0);
      expect(MediaDimensions.height, 270.0);
      expect(MediaDimensions.aspectRatio, 16 / 9);
      expect(MediaDimensions.borderRadius, 8.0);
    });

    test('width and height ratio equals exact aspect ratio', () {
      expect(
        MediaDimensions.width / MediaDimensions.height,
        MediaDimensions.aspectRatio,
      );
    });
  });
}
