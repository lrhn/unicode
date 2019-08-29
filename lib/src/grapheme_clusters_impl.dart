// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "grapheme_clusters.dart";

/// The grapheme clusters of a string.
class _GraphemeClusters extends Iterable<String> implements GraphemeClusters {
  // Try to avoid allocating more empty grapheme clusters.
  static const GraphemeClusters _empty = const _GraphemeClusters._("");

  final String string;

  const _GraphemeClusters._(this.string);

  factory _GraphemeClusters(String string) =>
      string.isEmpty ? _empty : _GraphemeClusters._(string);

  GraphemeCluster get iterator => _GraphemeCluster(string);

  String get first => string.isEmpty
      ? throw StateError("No element")
      : string.substring(
          0, Breaks(string, 0, string.length, stateSoTNoBreak).nextBreak());

  String get last => string.isEmpty
      ? throw StateError("No element")
      : string.substring(
          BackBreaks(string, string.length, 0, stateEoTNoBreak).nextBreak());

  String get single {
    if (string.isEmpty) throw StateError("No element");
    int firstEnd =
        Breaks(string, 0, string.length, stateSoTNoBreak).nextBreak();
    if (firstEnd == string.length) return string;
    throw StateError("Too many elements");
  }

  bool get isEmpty => string.isEmpty;

  bool get isNotEmpty => string.isNotEmpty;

  int get length {
    if (string.isEmpty) return 0;
    var brk = Breaks(string, 0, string.length, stateSoTNoBreak);
    int length = 0;
    while (brk.nextBreak() >= 0) length++;
    return length;
  }

  Iterable<T> whereType<T>() {
    Iterable<Object> self = this;
    if (self is Iterable<T>) {
      return self.map<T>((x) => x);
    }
    return Iterable<T>.empty();
  }

  String join([String separator = ""]) {
    if (separator == "") return string;
    return _explodeReplace(separator, "", 0);
  }

  String lastWhere(bool test(String element), {String orElse()}) {
    int cursor = string.length;
    var brk = BackBreaks(string, cursor, 0, stateEoTNoBreak);
    int next = 0;
    while ((next = brk.nextBreak()) >= 0) {
      String current = string.substring(next, cursor);
      if (test(current)) return current;
      cursor = next;
    }
    if (orElse != null) return orElse();
    throw StateError("no element");
  }

  String elementAt(int index) {
    RangeError.checkNotNegative(index, "index");
    int count = 0;
    if (string.isNotEmpty) {
      var breaks = Breaks(string, 0, string.length, stateSoTNoBreak);
      int start = 0;
      int end = 0;
      while ((end = breaks.nextBreak()) >= 0) {
        if (count == index) return string.substring(start, end);
        count++;
        start = end;
      }
    }
    throw RangeError.index(index, this, "index", null, count);
  }

  bool contains(Object other) {
    if (other is String) {
      if (other.isEmpty) return false;
      int next = Breaks(other, 0, other.length, stateSoTNoBreak).nextBreak();
      if (next != other.length) return false;
      // [other] is single grapheme cluster.
      return _indexOf(other, 0) >= 0;
    }
    return false;
  }

  int indexOf(GraphemeClusters other, [int startIndex]) {
    int length = string.length;
    if (startIndex == null) {
      startIndex = 0;
    } else {
      RangeError.checkValidRange(startIndex, length, length, "startIndex");
    }
    return _indexOf(other.string, startIndex);
  }

  /// Finds first occurrence of [otherString] at grapheme cluster boundaries.
  ///
  /// Only finds occurrences starting at or after [startIndex].
  int _indexOf(String otherString, int startIndex) {
    int otherLength = otherString.length;
    if (otherLength == 0) {
      return nextBreak(string, 0, string.length, startIndex);
    }
    int length = string.length;
    while (startIndex + otherLength <= length) {
      int matchIndex = string.indexOf(otherString, startIndex);
      if (matchIndex < 0) return matchIndex;
      if (isGraphemeClusterBoundary(string, 0, length, matchIndex) &&
          isGraphemeClusterBoundary(
              string, 0, length, matchIndex + otherLength)) {
        return matchIndex;
      }
      startIndex = matchIndex + 1;
    }
    return -1;
  }

  /// Finds last occurrence of [otherString] at grapheme cluster boundaries.
  ///
  /// Starts searching backwards at [startIndex].
  int _lastIndexOf(String otherString, int startIndex) {
    int otherLength = otherString.length;
    if (otherLength == 0) {
      return previousBreak(string, 0, string.length, startIndex);
    }
    int length = string.length;
    while (startIndex >= 0) {
      int matchIndex = string.lastIndexOf(otherString, startIndex);
      if (matchIndex < 0) return matchIndex;
      if (isGraphemeClusterBoundary(string, 0, length, matchIndex) &&
          isGraphemeClusterBoundary(
              string, 0, length, matchIndex + otherLength)) {
        return matchIndex;
      }
      startIndex = matchIndex - 1;
    }
    return -1;
  }

  bool startsWith(GraphemeClusters other, [int startIndex = 0]) {
    int length = string.length;
    RangeError.checkValueInInterval(startIndex, 0, length, "startIndex");
    String otherString = other.string;
    if (otherString.isEmpty) return true;
    return string.startsWith(otherString, startIndex) &&
        isGraphemeClusterBoundary(
            string, 0, length, startIndex + otherString.length);
  }

  bool endsWith(GraphemeClusters other, [int endIndex]) {
    int length = string.length;
    if (endIndex == null) {
      endIndex = length;
    } else {
      RangeError.checkValueInInterval(endIndex, 0, length, "endIndex");
    }
    String otherString = other.string;
    if (otherString.isEmpty) return true;
    int otherLength = otherString.length;
    int start = endIndex - otherLength;
    return start >= 0 &&
        string.startsWith(otherString, start) &&
        isGraphemeClusterBoundary(string, 0, endIndex, start);
  }

  GraphemeClusters replaceAll(
      GraphemeClusters pattern, GraphemeClusters replacement,
      [int startIndex = 0]) {
    if (startIndex > 0) {
      RangeError.checkValueInInterval(
          startIndex, 0, string.length, "startIndex");
    }
    if (pattern.string.isEmpty) {
      if (string.isEmpty) return replacement;
      var replacementString = replacement.string;
      return GraphemeClusters(
          _explodeReplace(replacementString, replacementString, startIndex));
    }
    int start = startIndex;
    StringBuffer buffer;
    int next = -1;
    while ((next = this.indexOf(pattern, start)) >= 0) {
      (buffer ??= StringBuffer())
        ..write(string.substring(start, next))
        ..write(replacement);
      start = next + pattern.string.length;
    }
    if (buffer == null) return this;
    buffer.write(string.substring(start));
    return GraphemeClusters(buffer.toString());
  }

  // Replaces every internal grapheme cluster boundary with
  // [internalReplacement] and adds [outerReplacement] at both ends
  // Starts at [startIndex].
  String _explodeReplace(
      String internalReplacement, String outerReplacement, int startIndex) {
    var buffer = StringBuffer(string.substring(0, startIndex));
    var breaks = Breaks(string, startIndex, string.length, stateSoTNoBreak);
    int index = 0;
    String replacement = outerReplacement;
    while ((index = breaks.nextBreak()) >= 0) {
      buffer..write(replacement)..write(string.substring(startIndex, index));
      startIndex = index;
      replacement = internalReplacement;
    }
    buffer.write(outerReplacement);
    return buffer.toString();
  }

  GraphemeClusters replaceFirst(
      GraphemeClusters source, GraphemeClusters replacement,
      [int startIndex = 0]) {
    if (startIndex != 0) {
      RangeError.checkValueInInterval(
          startIndex, 0, string.length, "startIndex");
    }
    int index = _indexOf(source.string, startIndex);
    if (index < 0) return this;
    return GraphemeClusters(string.replaceRange(
        index, index + source.string.length, replacement.string));
  }

  bool containsAll(GraphemeClusters other) {
    return _indexOf(other.string, 0) >= 0;
  }

  GraphemeClusters skip(int count) {
    RangeError.checkNotNegative(count, "count");
    if (count == 0) return this;
    if (string.isNotEmpty) {
      var breaks = Breaks(string, 0, string.length, stateSoTNoBreak);
      int startIndex = 0;
      while (count > 0) {
        int index = breaks.nextBreak();
        if (index >= 0) {
          count--;
          startIndex = index;
        } else {
          return _empty;
        }
      }
      return _GraphemeClusters(string.substring(startIndex));
    }
    return this;
  }

  GraphemeClusters take(int count) {
    RangeError.checkNotNegative(count, "count");
    if (count == 0) return _empty;
    if (string.isNotEmpty) {
      var breaks = Breaks(string, 0, string.length, stateSoTNoBreak);
      int endIndex = 0;
      while (count > 0) {
        int index = breaks.nextBreak();
        if (index >= 0) {
          count--;
          endIndex = index;
        } else {
          return this;
        }
      }
      return _GraphemeClusters._(string.substring(0, endIndex));
    }
    return this;
  }

  GraphemeClusters skipWhile(bool Function(String) test) {
    if (string.isNotEmpty) {
      var breaks = Breaks(string, 0, string.length, stateSoTNoBreak);
      int index = 0;
      int startIndex = 0;
      while ((index = breaks.nextBreak()) >= 0) {
        if (!test(string.substring(startIndex, index))) {
          if (startIndex == 0) return this;
          return _GraphemeClusters._(string.substring(startIndex));
        }
        startIndex = index;
      }
    }
    return _empty;
  }

  GraphemeClusters takeWhile(bool Function(String) test) {
    if (string.isNotEmpty) {
      var breaks = Breaks(string, 0, string.length, stateSoTNoBreak);
      int index = 0;
      int endIndex = 0;
      while ((index = breaks.nextBreak()) >= 0) {
        if (!test(string.substring(endIndex, index))) {
          if (endIndex == 0) return _empty;
          return _GraphemeClusters._(string.substring(0, endIndex));
        }
        endIndex = index;
      }
    }
    return this;
  }

  GraphemeClusters where(bool Function(String) test) =>
      _GraphemeClusters(super.where(test).join());

  GraphemeClusters operator +(GraphemeClusters other) =>
      _GraphemeClusters(string + other.string);

  GraphemeClusters getRange(int start, int end) {
    RangeError.checkNotNegative(start, "start");
    if (end < start) throw RangeError.range(end, start, null, "end");
    if (string.isEmpty) return this;
    var breaks = Breaks(string, 0, string.length, stateSoTNoBreak);
    int startIndex = 0;
    int endIndex = string.length;
    end -= start;
    while (start > 0) {
      int index = breaks.nextBreak();
      if (index >= 0) {
        startIndex = index;
        start--;
      } else {
        return _empty;
      }
    }
    while (end > 0) {
      int index = breaks.nextBreak();
      if (index >= 0) {
        endIndex = index;
        end--;
      } else {
        if (startIndex == 0) return this;
        return _GraphemeClusters(string.substring(startIndex));
      }
    }
    if (startIndex == 0 && endIndex == string.length) return this;
    return _GraphemeClusters(string.substring(startIndex, endIndex));
  }

  GraphemeClusters skipLast(int count) {
    RangeError.checkNotNegative(count, "count");
    if (count == 0) return this;
    if (string.isNotEmpty) {
      var breaks = BackBreaks(string, string.length, 0, stateEoTNoBreak);
      int endIndex = string.length;
      while (count > 0) {
        int index = breaks.nextBreak();
        if (index >= 0) {
          endIndex = index;
          count--;
        } else {
          return _empty;
        }
      }
      return _GraphemeClusters(string.substring(0, endIndex));
    }
    return _empty;
  }

  GraphemeClusters skipLastWhile(bool Function(String) test) {
    if (string.isNotEmpty) {
      var breaks = BackBreaks(string, string.length, 0, stateEoTNoBreak);
      int index = 0;
      int end = string.length;
      while ((index = breaks.nextBreak()) >= 0) {
        if (!test(string.substring(index, end))) {
          if (end == string.length) return this;
          return _GraphemeClusters(string.substring(0, end));
        }
        end = index;
      }
    }
    return _GraphemeClusters.empty();
  }

  GraphemeClusters takeLast(int count) {
    RangeError.checkNotNegative(count, "count");
    if (count == 0) return this;
    if (string.isNotEmpty) {
      var breaks = BackBreaks(string, string.length, 0, stateEoTNoBreak);
      int startIndex = string.length;
      while (count > 0) {
        int index = breaks.nextBreak();
        if (index >= 0) {
          startIndex = index;
          count--;
        } else {
          return this;
        }
      }
      return _GraphemeClusters(string.substring(startIndex));
    }
    return this;
  }

  GraphemeClusters takeLastWhile(bool Function(String) test) {
    if (string.isNotEmpty) {
      var breaks = BackBreaks(string, string.length, 0, stateEoTNoBreak);
      int index = 0;
      int start = string.length;
      while ((index = breaks.nextBreak()) >= 0) {
        if (!test(string.substring(index, start))) {
          return _GraphemeClusters(string.substring(start));
        }
        start = index;
      }
    }
    return this;
  }

  int indexAfter(GraphemeClusters other, [int startIndex]) {
    int length = string.length;
    String otherString = other.string;
    int otherLength = otherString.length;
    if (startIndex == null) {
      startIndex = 0;
    } else {
      RangeError.checkValueInInterval(startIndex, 0, length, "startIndex");
    }
    if (otherLength > startIndex) startIndex = otherLength;
    int start = _indexOf(other.string, startIndex - otherLength);
    if (start < 0) return start;
    return start + otherLength;
  }

  GraphemeClusters insertAt(int index, GraphemeClusters other) {
    int length = string.length;
    RangeError.checkValidRange(index, length, length, "index");
    if (string.isEmpty) {
      assert(index == 0);
      return other;
    }
    return _GraphemeClusters._(string.replaceRange(index, index, other.string));
  }

  int lastIndexAfter(GraphemeClusters other, [int startIndex]) {
    String otherString = other.string;
    int otherLength = otherString.length;
    if (startIndex == null) {
      startIndex = string.length;
    } else {
      RangeError.checkValueInInterval(
          startIndex, 0, string.length, "startIndex");
    }
    if (otherLength > startIndex) return -1;
    int start = _lastIndexOf(otherString, startIndex - otherLength);
    if (start < 0) return start;
    return start + otherLength;
  }

  int lastIndexOf(GraphemeClusters other, [int startIndex]) {
    if (startIndex == null) {
      startIndex = string.length;
    } else {
      RangeError.checkValueInInterval(
          startIndex, 0, string.length, "startIndex");
    }
    return _lastIndexOf(other.string, startIndex);
  }

  GraphemeClusters replaceSubstring(
      int startIndex, int endIndex, GraphemeClusters other) {
    RangeError.checkValidRange(
        startIndex, endIndex, string.length, "startIndex", "endIndex");
    if (startIndex == 0 && endIndex == string.length) return other;
    return _GraphemeClusters._(
        string.replaceRange(startIndex, endIndex, other.string));
  }

  GraphemeClusters substring(int startIndex, [int endIndex]) {
    endIndex = RangeError.checkValidRange(
        startIndex, endIndex, string.length, "startIndex", "endIndex");
    return _GraphemeClusters(string.substring(startIndex, endIndex));
  }

  GraphemeClusters toLowerCase() => _GraphemeClusters(string.toLowerCase());

  GraphemeClusters toUpperCase() => _GraphemeClusters(string.toUpperCase());

  bool operator ==(Object other) =>
      other is GraphemeClusters && string == other.string;

  int get hashCode => string.hashCode;

  String toString() => string;
}

class _GraphemeCluster implements GraphemeCluster {
  static const int _directionForward = 0;
  static const int _directionBackward = 0x04;
  static const int _directionMask = 0x04;
  static const int _cursorDeltaMask = 0x03;

  final String _string;
  int _start;
  int _end;
  // Encodes current state,
  // whether we are moving forwards or backwards ([_directionMask]),
  // and how far ahead the cursor is from the start/end ([_cursorDeltaMask]).
  int _state;
  // The [current] value is created lazily and cached to avoid repeated
  // or unnecessary string allocation.
  String _currentCache;

  _GraphemeCluster(String string) : this._(string, 0, 0, stateSoTNoBreak);
  _GraphemeCluster._(this._string, this._start, this._end, this._state);

  int get start => _start;
  int get end => _end;

  String get current => _currentCache ??=
      (_start == _end ? null : _string.substring(_start, _end));

  bool moveNext() {
    int state = _state;
    int cursor = _end;
    if (state & _directionMask != _directionForward) {
      state = stateSoTNoBreak;
    } else {
      cursor += state & _cursorDeltaMask;
    }
    var breaks = Breaks(_string, cursor, _string.length, state);
    var next = breaks.nextBreak();
    _currentCache = null;
    _start = _end;
    if (next >= 0) {
      _end = next;
      _state =
          (breaks.state & 0xF0) | _directionForward | (breaks.cursor - next);
      return true;
    }
    _state = stateEoTNoBreak | _directionBackward;
    return false;
  }

  bool movePrevious() {
    int state = _state;
    int cursor = _start;
    if (state & _directionMask == _directionForward) {
      state = stateEoTNoBreak;
    } else {
      cursor -= state & _cursorDeltaMask;
    }
    var breaks = BackBreaks(_string, cursor, 0, state);
    var next = breaks.nextBreak();
    _currentCache = null;
    _end = _start;
    if (next >= 0) {
      _start = next;
      _state =
          (breaks.state & 0xF0) | _directionBackward | (next - breaks.cursor);
      return true;
    }
    _state = stateSoTNoBreak | _directionForward;
    return false;
  }

  List<int> get codeUnits => _CodeUnits(_string, _start, _end);

  Runes get runes => Runes(current);

  void reset(int index) {
    RangeError.checkValueInInterval(index, 0, _string.length, "index");
    _reset(index);
  }

  void resetStart() {
    _reset(0);
  }

  void resetEnd() {
    _state = stateEoTNoBreak | _directionBackward;
    _currentCache = null;
    _start = _end = _string.length;
  }

  void _reset(int index) {
    _state = stateSoTNoBreak | _directionForward;
    _currentCache = null;
    _start = _end = index;
  }

  GraphemeCluster copy() {
    return _GraphemeCluster._(_string, _start, _end, _state);
  }
}

class _CodeUnits extends ListBase<int> {
  final String _string;
  final int _start;
  final int _end;

  _CodeUnits(this._string, this._start, this._end);

  int get length => _end - _start;

  int operator [](int index) {
    RangeError.checkValidIndex(index, this, "index", _end - _start);
    return _string.codeUnitAt(_start + index);
  }

  void operator []=(int index, int value) {
    throw UnsupportedError("Cannot modify an unmodifiable list");
  }

  @override
  void set length(int newLength) {
    throw UnsupportedError("Cannot modify an unmodifiable list");
  }
}
