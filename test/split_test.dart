// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:unicode/unicode.dart";

import "src/unicode_tests.dart";
import "src/various_tests.dart";

main() {
  int testCount = 0;
  var errors = [];

  void splitTest(String name, List<String> expected) {
    testCount++;
    void fail(List<String> test, var expected, var result) {
      print(result.map((s) => "<$s>"));
      errors.add('Split: Expected $name, got ${testDescription(result)}.');
    }

    var input = expected.join("");
    var split = GraphemeClusters(input).toList();
    if (split.length == expected.length) {
      for (int i = 0; i < split.length; i++) {
        if (expected[i] != split[i]) {
          fail(expected, expected, split);
          break;
        }
      }
    } else {
      fail(expected, expected, split);
    }
  }

  void breakTest(String name, List<String> expected) {
    void fail(List<String> test, var expected, var result) {
      errors.add('Breaks of $name: Expected: <$expected>, got: <$result>.');
    }

    testCount++;
    var expectedBreaks = [];
    if (expected.isNotEmpty) {
      expectedBreaks.add(0);
      int index = 0;
      for (var grapheme in expected) {
        index += grapheme.length;
        expectedBreaks.add(index);
      }
    }
    var input = expected.join("");
    var breaks = graphemeClusterBoundaries(input, 0, input.length).toList();
    if (breaks.length != expectedBreaks.length) {
      fail(expected, expectedBreaks, breaks);
    } else {
      for (int i = 0; i < expectedBreaks.length; i++) {
        if (expectedBreaks[i] != breaks[i]) {
          fail(expected, expectedBreaks, breaks);
          break;
        }
      }
    }
  }

  for (var expected in splitTests + emojis + zalgo) {
    var name = testDescription(expected);
    splitTest(name, expected);
    breakTest(name, expected);
  }
  print("Successes: ${testCount - errors.length}, Failures: ${errors.length}");
  if (errors.isNotEmpty) {
    print(errors.join("\n"));
    throw errors.join("\n");
  }
}
