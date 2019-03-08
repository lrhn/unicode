// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:unicode/src/grapheme_clusters/constants.dart";
import "package:unicode/src/grapheme_clusters/table.dart";

const otr = categoryOther;
const cr = categoryCR;
const lf = categoryLF;
const ext = categoryExtend;
const zwj = categoryZWJ;
const ctl = categoryControl;
const pre = categoryPrepend;
const reg = categoryRegionalIndicator;
const spc = categorySpacingMark;
const pic = categoryPictographic;
const l = categoryL;
const v = categoryV;
const t = categoryT;
const lv = categoryLV;
const lvt = categoryLVT;
const eot = categoryEoT;

const categories = [
  categoryOther,
  categoryCR,
  categoryLF,
  categoryControl,
  categoryExtend,
  categoryZWJ,
  categoryRegionalIndicator,
  categoryPrepend,
  categorySpacingMark,
  categoryL,
  categoryV,
  categoryT,
  categoryLV,
  categoryLVT,
  categoryPictographic,
  categoryEoT,
];

Map<int, String> name = {
  otr: "Other",
  cr: "CR",
  lf: "LF",
  ext: "Extend",
  ctl: "Control",
  zwj: "ZWJ",
  spc: "SpaceingMark",
  pre: "Prepend",
  pic: "\p{Extended_Pictographic}",
  reg: "RI",
  l: "L",
  v: "V",
  t: "T",
  lv: "LV",
  lvt: "LVT",
  eot: "eot",
};
String catString(int category) => name[category];

main() {
  var errors = <String>[];
  test(List<int> input, bool breakBeforeLast, String rule) {
    var state = stateSoT;
    for (var c in input) {
      state = move(state, c);
    }
    bool detectedBreak = state & stateNoBreak == 0;
    if (breakBeforeLast != detectedBreak) {
      var names = input.map(catString).toList();

      names.insert(names.length - 1, breakBeforeLast ? "÷" : "×");
      errors.add('Failed($rule): ' + names.join(" "));
    }
  }

  for (var cat in categories) {
    test([cat], cat != eot, "GB1");
    if (cat != eot) test([cat, eot], true, "GB2");
  }
  test([cr, lf], false, "GB3");
  for (var cat in categories) {
    if (cat != lf) test([cr, cat], true, "GB4");
    test([lf, cat], true, "GB4");
    test([ctl, cat], true, "GB4");

    if (cat != eot) {
      test([cat, cr], true, "GB5");
      if (cat != cr) test([cat, lf], true, "GB5");
      test([cat, ctl], true, "GB5");
    }
  }
  test([l, l], false, "GB6");
  test([l, v], false, "GB6");
  test([l, lv], false, "GB6");
  test([l, lvt], false, "GB6");

  test([v, v], false, "GB7");
  test([v, t], false, "GB7");
  test([lv, v], false, "GB7");
  test([lv, t], false, "GB7");

  test([t, t], false, "GB8");
  test([lvt, t], false, "GB8");

  for (var cat in categories) {
    if (cat != cr && cat != lf && cat != ctl && cat != eot) {
      test([cat, ext], false, "GB9");
      test([cat, zwj], false, "GB9");
      test([cat, spc], false, "GB9a");
      test([pre, cat], false, "GB9b");
    }
    test([reg, reg, ext], false, "GB9");
    test([reg, reg, zwj], false, "GB9");
    test([reg, reg, spc], false, "GB9a");
  }

  test([pic, zwj, pic], false, "GB11");
  test([pic, ext, zwj, pic], false, "GB11");
  test([pic, ext, ext, zwj, pic], false, "GB11");
  test([pic, zwj, pic, zwj, pic], false, "GB11");
  test([pre, pic, zwj, pic], false, "GB11");

  test([reg, reg], false, "GB12");
  test([reg, reg, reg, reg], false, "GB12");
  test([reg, reg, reg, reg, reg, reg], false, "GB12");
  for (var cat in categories) {
    if (cat != eot && cat != reg) {
      test([cat, reg, reg], false, "GB12");
      test([cat, reg, reg, reg, reg], false, "GB12");
      test([cat, reg, reg, reg, reg, reg, reg], false, "GB12");
    }
  }

  test([l, t], true, "GB999");
  test([v, l], true, "GB999");
  test([lv, l], true, "GB999");
  test([t, l], true, "GB999");
  test([t, v], true, "GB999");
  test([lvt, l], true, "GB999");
  test([lvt, v], true, "GB999");
  test([otr, zwj, pic], true, "GB999");
  test([otr, ext, zwj, pic], true, "GB999");

  test([reg, reg, reg], true, "GB999");
  test([otr, reg, reg, reg], true, "GB999");
  test([reg, reg, zwj, reg], true, "GB999");
  test([pre, pic, zwj, pre], true, "GB999");

  if (errors.isNotEmpty) {
    errors.sort();
    print(errors.join("\n"));
    throw "Failure";
  }
}
