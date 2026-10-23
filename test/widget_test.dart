import 'package:tokoku/core/responsive/breakpoints.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Breakpoints', () {
    test('maps widths to window sizes', () {
      expect(Breakpoints.of(390), WindowSize.compact);
      expect(Breakpoints.of(600), WindowSize.medium);
      expect(Breakpoints.of(839), WindowSize.medium);
      expect(Breakpoints.of(840), WindowSize.expanded);
    });

    test('adds grid columns as the screen gets wider', () {
      expect(Breakpoints.gridColumns(390), 2);
      expect(Breakpoints.gridColumns(700), 3);
      expect(Breakpoints.gridColumns(1000), 4);
      expect(Breakpoints.gridColumns(1280), 5);
    });
  });
}
