// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:unicode/src/grapheme_clusters/breaks.dart";
import "package:unicode/src/grapheme_clusters/constants.dart";

import "src/text_samples.dart";
import "src/unicode_grapheme_tests.dart";
import "src/various_tests.dart";

void main(List<String> args) {
  int count = 5;
  if (args.length > 0) {
    count = int.parse(args[0]);
  }
  var text =
      genesis + hangul + diacretics + recJoin(splitTests + emojis + zalgo);
  int codeUnits = text.length;
  int codePoints = text.runes.length;
  for (int i = 0; i < count; i++) {
    int n = 0;
    int c = 0;
    int e = 0;
    var sw = Stopwatch();
    sw.start();
    do {
      var breaks = Breaks(text, 0, text.length, stateSoTNoBreak);
      while (breaks.nextBreak() >= 0) {
        c++;
      }
      e = sw.elapsedMilliseconds;
      n++;
    } while (e < 2000);
    print("#$i: ${(c / e).toStringAsFixed(3)} gc/ms, "
        "${(n * codePoints / e).toStringAsFixed(3)} cp/ms, "
        "${(n * codeUnits / e).toStringAsFixed(3)} cu/ms");
  }
  print("gc: Grapheme Clusters, cp: Code Points, cu: Code Units.");
}

String recJoin(List<List<String>> texts) =>
    texts.map((x) => x.join("")).join("");
