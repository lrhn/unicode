// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "constants.dart";
import "table.dart";

class Breaks {
  final String base;
  final int end;
  int cursor;
  int state;

  Breaks(this.base, this.cursor, this.end, this.state);

  Breaks copy() => Breaks(base, cursor, end, state);

  int nextBreak() {
    while (cursor < end) {
      int breakAt = cursor;
      int char = base.codeUnitAt(cursor++);
      if (char & 0xFC00 != 0xD800) {
        state = move(state, low(char));
        if (state & stateNoBreak == 0) {
          return breakAt;
        }
        continue;
      }
      // The category of an unpaired lead surrogate is Control.
      int category = categoryControl;
      if (cursor < end) {
        int nextChar = base.codeUnitAt(cursor);
        if (nextChar & 0xFC00 == 0xDC00) {
          category = high(char, nextChar);
          cursor++;
        }
      }
      state = move(state, category);
      if (state & stateNoBreak == 0) {
        return breakAt;
      }
    }
    state = move(state, categoryEoT);
    if (state & stateNoBreak == 0) return cursor;
    return -1;
  }
}
