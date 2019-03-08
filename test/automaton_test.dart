// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:unicode/src/grapheme_clusters/table.dart";
import "package:unicode/src/grapheme_clusters/constants.dart";

import "src/unicode_tests.dart";
import "src/various_tests.dart";

main() {
  var errors = [];
  var tests = splitTests + emojis + zalgo;
  for (var expected in tests) {
    var trace = StringBuffer(stateName[stateSoT]);
    int state = stateSoT;
    bool error = false;
    for (var part in expected) {
      bool expectBreakBefore = true;
      for (var rune in part.runes) {
        var cat = rune < 65536 ? low(rune) : high(lead(rune), tail(rune));
        state = move(state, cat);
        trace..write("<")..write(categoryName[cat])..write(">");
        bool breakBefore = (state & stateNoBreak) == 0;
        if (breakBefore != expectBreakBefore) {
          error = true;
          trace.write("?");
        }
        if (breakBefore) trace.write("!");
        expectBreakBefore = false;
        trace.write(stateName[state & ~stateNoBreak]);
      }
    }
    if (error) {
      String name = testDescription(expected);
      errors.add('$name: $trace');
    }
  }
  print(
      "Successes: ${tests.length - errors.length}, Failures: ${errors.length}");
  if (errors.isNotEmpty) {
    print(errors.join("\n"));
    throw errors.join("\n");
  }
}

var stateName = <int, String>{
  stateSoT: "SoT",
  stateBreak: "Break",
  stateCR: "CR",
  stateOther: "Other",
  statePrepend: "Prepend",
  stateL: "L",
  stateLV: "LV",
  stateLVT: "LVT",
  statePictographic: "Pictographic",
  statePictographicZWJ: "PictographicZWJ",
  stateRegionalSingle: "RegionalSingle",
};

int lead(int cp) => 0xd800 | ((cp - 0x10000) >> 10);
int tail(int cp) => 0xdc00 | cp & 0x3ff;
