import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Golden tests in this folder accept a tiny pixel difference, so goldens
/// made on a Mac also pass on CI's Linux runners (anti-aliasing differs a
/// little). Text uses Flutter's test font (boxes): the goldens check
/// layout, colours, direction and theme — not glyph shapes.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final base = goldenFileComparator;
  if (base is LocalFileComparator) {
    goldenFileComparator = TolerantGoldenComparator(
      base.basedir.resolve('golden_test.dart'),
    );
  }
  await testMain();
}

class TolerantGoldenComparator extends LocalFileComparator {
  TolerantGoldenComparator(super.testFile, {this.tolerance = 0.005});

  /// Largest share of differing pixels still accepted (0.5 %).
  final double tolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed || result.diffPercent <= tolerance) {
      result.dispose();
      return true;
    }
    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}
