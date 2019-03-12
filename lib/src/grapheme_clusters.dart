// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:collection";

import "grapheme_clusters/constants.dart";
import "grapheme_clusters/breaks.dart";

/// The grapheme cluster boundaries in [string].
///
/// The [start] and [end] must satisfy `0 <= start <= end <= string.length`.
/// If [end] is omitted, it defaults to `string.length`.
///
/// Finds the boundaries of grapheme clusters after [start], and up to [end], in
/// the string `string.substring(start, end)`. Always includes [start] and [end]
/// unless `start == end`.
Iterable<int> graphemeClusterBoundaries(String string,
    [int start = 0, int end]) sync* {
  end = RangeError.checkValidRange(start, end, string.length);
  var breaks = Breaks(string, start, end, stateSoT);
  var breakAt;
  while ((breakAt = breaks.nextBreak()) >= 0) yield breakAt;
}

/// The grapheme clusters of a string.
abstract class GraphemeClusters implements Iterable<String> {
  /// Creates a [GraphemeClusters] allowing iteration of
  /// the grapheme clusters of [string].
  factory GraphemeClusters(String string) = _GraphemeClusters;

  /// The string to iterate over.
  String get string;

  /// A specialized grapheme cluster iterator.
  ///
  /// Allows iterating the grapheme clusters of [string] as a plain iterator,
  // as well as controlling the iteration in more detail.
  GraphemeCluster get iterator;

  /// The first string index where [other] occurs as a subsequence of these
  /// grapheme clusters.
  ///
  /// If [startIndex] is supplied, searching starts at [startIndex], which
  /// *should* be a grapheme cluster boundary.
  int indexOf(GraphemeClusters other, [int startIndex = 0]);

  /// Whether [other] is an initial subsequence of this sequence
  /// of grapheme clusters.
  ///
  /// If [startIndex] is provided, then checks whether
  /// [other] is an initial subsequence of the grapheme clusters
  /// of the substring of [string] starting at [startIndex].
  bool startsWith(GraphemeClusters other, [int startIndex = 0]);

  /// Returns a new grapheme clusters sequence where [source] has been
  /// replaced by [replacement].
  ///
  /// If [startIndex] is provided, instead replaces grapheme clusters of the
  /// substring of [string] starting at [startIndex].
  /// The [startIndex] should be a grapheme cluster boundary in [string],
  /// otherwise the replaced substrings may not correspond to grapheme
  /// clusters of this sequence.
  GraphemeClusters replaceAll(
      GraphemeClusters source, GraphemeClusters replacement,
      [int startIndex = 0]);

  /// Returns a new grapheme clusters sequence where the first occurrence of
  /// [source] has been replaced by [replacement].
  ///
  /// If [startIndex] is provided, instead replaces the first matching
  /// grapheme clusters of the substring of [string] starting at [startIndex].
  /// The [startIndex] should be a grapheme cluster boundary in [string],
  /// otherwise the replaced substrings may not correspond to grapheme
  /// clusters of this sequence.
  GraphemeClusters replaceFirst(
      GraphemeClusters source, GraphemeClusters replacement,
      [int startIndex = 0]);
}

/// Iterator over grapheme clusters of a string.
abstract class GraphemeCluster implements Iterator<String> {
  /// Creates a new grapheme cluster iterator iterating the grapheme
  /// clusters of [string].
  factory GraphemeCluster(String string) = _GraphemeCluster;

  /// The beginning of the current grapheme cluster in the underlying string.
  ///
  /// This index is always at a cluster boundary unless the iterator
  /// has been reset to a non-boundary index.
  ///
  /// If equal to [end], there is no current grapheme cluster, and [moveNext]
  /// needs to be called first before accessing [current].
  /// This is the case at the beginning of iteration,
  /// after [moveNext] has returned false,
  /// or after calling [reset].
  int get start;

  /// The end of the current grapheme cluster in the underlying string.
  ///
  /// This index is always at a cluster boundary unless the iterator
  /// has been reset to a non-boundary index.
  ///
  /// If equal to [start], there is no current grapheme cluster.
  int get end;

  /// The code units of the current grapheme cluster.
  List<int> get codeUnits;

  /// The code poin;ts of the current grapheme cluster.
  Runes get runes;

  /// Resets the iterator to the [index] position.
  ///
  /// There is no [current] grapheme cluster after a reset,
  /// a call to [moveNext] is needed.
  /// A `reset(0)` will reset to the beginning of the string, as for a newly
  /// created iterator.
  void reset(int index);

  /// Creates a copy of this [GraphemeIterator].
  ///
  /// The copy is in the exact same state as this iterator.
  GraphemeCluster copy();
}

/// The grapheme clusters of a string.
class _GraphemeClusters extends Iterable<String> implements GraphemeClusters {
  final String string;

  _GraphemeClusters(this.string);

  GraphemeCluster get iterator => _GraphemeCluster(string);

  int indexOf(GraphemeClusters other, [int startIndex = 0]) {
    RangeError.checkValueInInterval(startIndex, 0, null, "startIndex");
    var startBreaks =
        Breaks(string, startIndex, string.length, stateSoTNoBreak);
    var endBreaks = Breaks(string, startIndex, string.length, stateSoTNoBreak);
    int start = startIndex;
    int end = startIndex;
    int otherLength = other.string.length;
    do {
      int length = end - start;
      if (length == otherLength && string.startsWith(other.string, start)) {
        return start;
      } else if (length < otherLength) {
        end = endBreaks.nextBreak();
      } else {
        assert(length > otherLength);
        start = startBreaks.nextBreak();
      }
    } while (end >= 0);
    return -1;
  }

  bool startsWith(GraphemeClusters other, [int startIndex = 0]) {
    RangeError.checkValueInInterval(startIndex, 0, null, "startIndex");
    if (other.string.isEmpty) return true;
    if (!string.startsWith(other.string, startIndex)) return false;
    int end = startIndex + other.string.length;
    var breaks = Breaks(string, startIndex, string.length, stateSoTNoBreak);
    int nextBreak = 0;
    do {
      nextBreak = breaks.nextBreak();
      if (nextBreak == end) return true;
    } while (nextBreak < end);
    return false;
  }

  GraphemeClusters replaceAll(
      GraphemeClusters source, GraphemeClusters replacement,
      [int startIndex = 0]) {
    if (startIndex != 0) {
      RangeError.checkValueInInterval(
          startIndex, 0, string.length, "startIndex");
    }
    int start = startIndex;
    StringBuffer buffer;
    int next = -1;
    while ((next = this.indexOf(source, start)) >= 0) {
      (buffer ??= StringBuffer())
        ..write(string.substring(start, next))
        ..write(replacement);
      start = next + source.string.length;
    }
    if (buffer == null) return this;
    buffer.write(string.substring(start));
    return GraphemeClusters(buffer.toString());
  }

  GraphemeClusters replaceFirst(
      GraphemeClusters source, GraphemeClusters replacement,
      [int startIndex = 0]) {
    if (startIndex != 0) {
      RangeError.checkValueInInterval(
          startIndex, 0, string.length, "startIndex");
    }
    int index = this.indexOf(source, startIndex);
    if (index < 0) return this;
    return GraphemeClusters(string.replaceRange(
        index, index + source.string.length, replacement.string));
  }
}

class _GraphemeCluster implements GraphemeCluster {
  final String _string;
  int _start;
  int _end;
  Breaks _breaks;
  String _currentCache;

  _GraphemeCluster(String string) : this._(string, 0, 0, null);
  _GraphemeCluster._(this._string, this._start, this._end, this._breaks);

  int get start => _start;
  int get end => _end;

  String get current => _currentCache ??=
      (_start == _end ? null : _string.substring(_start, _end));

  bool moveNext() {
    int next = (_breaks ??=
            Breaks(_string, _start, _string.length, stateSoTNoBreak))
        .nextBreak();
    _currentCache = null;
    if (next >= 0) {
      _start = _end;
      _end = next;
      return true;
    }
    _start = _end;
    return false;
  }

  List<int> get codeUnits => _CodeUnits(_string, _start, _end);

  // TODO: Make [Runes] constructor accept a start and end, then use that.
  Runes get runes => Runes(current);

  void reset(int index) {
    RangeError.checkValueInInterval(index, 0, _string.length, "index");
    if (index != _end) _breaks = null;
    _currentCache = null;
    _start = _end = index;
  }

  GraphemeCluster copy() {
    return _GraphemeCluster._(_string, _start, _end, _breaks.copy());
  }

  // TODO: Optimize these to not create the substrings.
  int get hashCode => current.hashCode;
  bool operator ==(Object other) =>
      other is GraphemeCluster && current == other.current;
}

class _CodeUnits extends ListBase<int> {
  final String _string;
  final int _start;
  final int _end;

  _CodeUnits(this._string, this._start, this._end);

  int get length => _end - _start;
  int operator [](int index) {
    RangeError.checkValidIndex(index, this);
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
