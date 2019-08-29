// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:collection";

import "grapheme_clusters/constants.dart";
import "grapheme_clusters/breaks.dart";

part "grapheme_clusters_impl.dart";

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
  int breakAt;
  while ((breakAt = breaks.nextBreak()) >= 0) yield breakAt;
}

/// The grapheme clusters of a string.
///
/// A grapheme cluster is a substring of the original string.
/// The `GraphemeClusters` class is an [Iterable] of those strings.
/// However, unlike most iterables, many of the operations are
/// *eager*. Since the underlying string is known in its entirety,
/// and is known not to change, operations which select a subset of
/// the elements can be computed eagerly, and in that case the
/// operation returns a new `GraphemeClusters` object.
///
/// A `GraphemeClusters` also supports operations based on
/// string indices into the underlying string.
///
/// Inspection operations like [indexOf] or [lastIndexAfter]
/// returns such indices which are guranteed to be at grapheme cluster
/// boundaries.
/// Most such operations use the index as starting point,
/// but will still only work on entire grapheme clusters.
/// A few, like [substring] and [replaceSubstring], work directly
/// on the underlying string, independently of grapheme cluster
/// boundaries.
abstract class GraphemeClusters implements Iterable<String> {
  /// Creates a [GraphemeClusters] allowing iteration of
  /// the grapheme clusters of [string].
  factory GraphemeClusters(String string) = _GraphemeClusters;

  factory GraphemeClusters.empty() = _GraphemeClusters.empty;

  /// The string to iterate over.
  String get string;

  /// A specialized grapheme cluster iterator.
  ///
  /// Allows iterating the grapheme clusters of [string] as a plain iterator,
  // as well as controlling the iteration in more detail.
  GraphemeCluster get iterator;

  /// Whether [graphemeCluster] is an element of this sequence of
  /// grapheme clusters.
  ///
  /// Returns false if [graphemeCluster] is not a string containing
  /// a single grapheme cluster,
  /// because then it is not a single element of this [Iterable]
  /// of grapheme clusters.
  bool contains(Object graphemeCluster);

  /// Whether this sequence of grapheme clusters contains [other]
  /// as a subsequence.
  bool containsAll(GraphemeClusters other);

  /// Whether [other] is an initial subsequence of this sequence
  /// of grapheme clusters.
  ///
  /// If [startIndex] is provided, then checks whether
  /// [other] is an initial subsequence of the grapheme clusters
  /// starting at the grapheme cluster boundary [startIndex].
  ///
  /// Returns `true` if [other] is a sub-sequence of this sequence of
  /// grapheme clusters startings at the grapheme cluster boundary [startIndex].
  /// Returns `false` if [startIndex] is not a grapheme cluster boundary,
  /// or if [other] does not occur at that position.
  bool startsWith(GraphemeClusters other, [int startIndex = 0]);

  /// Whether [other] is an trailing subsequence of this sequence
  /// of grapheme clusters.
  ///
  /// If [endIndex] is provided, then checks whether
  /// [other] is a trailing subsequence of the grapheme clusters
  /// starting at the grapheme cluster boundary [endIndex].
  ///
  /// Returns `true` if [other] is a sub-sequence of this sequence of
  /// grapheme clusters startings at the grapheme cluster boundary [endIndex].
  /// Returns `false` if [endIndex] is not a grapheme cluster boundary,
  /// or if [other] does not occur at that position.
  bool endsWith(GraphemeClusters other, [int endIndex]);

  /// The string index before the first place where [other] occurs as
  /// a subsequence of these grapheme clusters.
  ///
  /// Returns the [string] index before first occurrence of the grapheme
  /// clusters of [other] in the sequence of grapheme clusters of [string].
  /// Returns a negative number if there is no such occurrence of [other].
  ///
  /// If [startIndex] is supplied, returns the index after the first occurrence
  /// of [other] in this which starts no earlier than [startIndex], and again
  /// returns `null` if there is no such occurrence. That is, if the result
  /// is non-negative, it is greater than or equal to [startIndex].
  int indexOf(GraphemeClusters other, [int startIndex]);

  /// The string index after the first place [other] occurs as a subsequence of
  /// these grapheme clusters.
  ///
  /// Returns the [string] index after the first occurrence of the grapheme
  /// clusters of [other] in the sequence of grapheme clusters of [string].
  /// Returns a negative number if there is no such occurrence of [other].
  ///
  /// If [startIndex] is supplied, returns the index after the first occurrence
  /// of [other] in this which starts no earlier than [startIndex], and again
  /// returns `null` if there is no such occurrence. That is, if the result
  /// is non-negative, it is greater than or equal to [startIndex].
  int indexAfter(GraphemeClusters other, [int startIndex]);

  /// The string index before the last place where [other] occurs as
  /// a subsequence of these grapheme clusters.
  ///
  /// Returns the [string] index before last occurrence of the grapheme
  /// clusters of [other] in the sequence of grapheme clusters of [string].
  /// Returns a negative number if there is no such occurrence of [other].
  ///
  /// If [startIndex] is supplied, returns the before after the first occurrence
  /// of [other] in this which starts no later than [startIndex], and again
  /// returns `null` if there is no such occurrence. That is the result
  /// is less than or equal to [startIndex].
  int lastIndexOf(GraphemeClusters other, [int startIndex]);

  /// The string index after the last place where [other] occurs as
  /// a subsequence of these grapheme clusters.
  ///
  /// Returns the [string] index after the last occurrence of the grapheme
  /// clusters of [other] in the sequence of grapheme clusters of [string].
  /// Returns a negative number if there is no such occurrence of [other].
  ///
  /// If [startIndex] is supplied, returns the index after the last occurrence
  /// of [other] in this which ends no later than [startIndex], and again
  /// returns `null` if there is no such occurrence. That is the result
  /// is less than or equal to [startIndex].
  int lastIndexAfter(GraphemeClusters other, [int startIndex]);

  /// Eagerly selects a subset of the grapheme clusters.
  ///
  /// Tests each grapheme cluster against [test], and returns the
  /// grapheme clusters of the concatenation of those grapheme cluster strings.
  GraphemeClusters where(bool Function(String) test);

  /// Eagerly selects all but the first [count] grapheme clusters.
  ///
  /// If [count] is greater than [length], the count of grapheme
  /// clusters available, then the empty sequence of grapheme clusters
  /// is returned.
  GraphemeClusters skip(int count);

  /// Eagerly selects the first [count] grapheme clusters.
  ///
  /// If [count] is greater than [length], the count of grapheme
  /// clusters available, then the entire sequence of grapheme clusters
  /// is returned.
  GraphemeClusters take(int count);

  /// Eagerly selects all but the last [count] grapheme clusters.
  ///
  /// If [count] is greater than [length], the count of grapheme
  /// clusters available, then the empty sequence of grapheme clusters
  /// is returned.
  GraphemeClusters skipLast(int count);

  /// Eagerly selects the last [count] grapheme clusters.
  ///
  /// If [count] is greater than [length], the count of grapheme
  /// clusters available, then the entire sequence of grapheme clusters
  /// is returned.
  GraphemeClusters takeLast(int count);

  /// Eagerly selects a range of grapheme clusters.
  ///
  /// Both [start] and [end] are offsets of grapheme clusters,
  /// not indices into [string].
  /// The [start] must be non-negative and [end] must be at least
  /// as large as [start].
  ///
  /// If [start] is at least as great as [length], then the result
  /// is an empty sequence of graphemes.
  /// If [end] is greater than [length], the count of grapheme
  /// clusters available, then it acts the same as if it was [length].
  ///
  /// A call like `gc.getRange(a, b)` is equivalent to `gc.take(b).skip(a)`.
  GraphemeClusters getRange(int start, int end);

  /// Eagerly selects a trailing sequence of grapheme clusters.
  ///
  /// Checks each grapheme cluster, from first to last, against [test],
  /// until one is found whwere [test] returns `false`.
  /// The grapheme clusters starting with the first one
  /// where [test] returns `false`, are included in the result.
  ///
  /// If no grapheme clusters test `false`, the result is an empty sequence
  /// of grapheme clusters.
  GraphemeClusters skipWhile(bool Function(String) test);

  /// Eagerly selects a leading sequnce of grapheme clusters.
  ///
  /// Checks each grapheme cluster, from first to last, against [test],
  /// until one is found whwere [test] returns `false`.
  /// The grapheme clusters up to, but not including, the first one
  /// where [test] returns `false` are included in the result.
  ///
  /// If no grapheme clusters test `false`, the entire sequence of grapheme
  /// clusters is returned.
  GraphemeClusters takeWhile(bool Function(String) test);

  /// Eagerly selects a leading sequnce of grapheme clusters.
  ///
  /// Checks each grapheme cluster, from last to first, against [test],
  /// until one is found whwere [test] returns `false`.
  /// The grapheme clusters up to and including the one with the latest index
  /// where [test] returns `false` are included in the result.
  ///
  /// If no grapheme clusters test `false`, the empty sequence of grapheme
  /// clusters is returned.
  GraphemeClusters skipLastWhile(bool Function(String) test);

  /// Eagerly selects a trailing sequence of grapheme clusters.
  ///
  /// Checks each grapheme cluster, from last to first, against [test],
  /// until one is found whwere [test] returns `false`.
  /// The grapheme clusters after the one with the latest index where
  /// [test] returns `false` are included in the result.
  ///
  /// If no grapheme clusters test `false`, the entire sequence of grapheme
  /// clusters is returned.
  GraphemeClusters takeLastWhile(bool Function(String) test);

  /// The grapheme clusters of the concatenation of this and [other].
  ///
  /// This is the grapheme clusters of the concatenation of the underlying
  /// strings. If there is no grapheme cluster break at the concatenation
  /// point in the resulting string, then the result is not the concatenation
  /// of the two grapheme cluster sequences.
  ///
  /// This differs from [followedBy] which provides the lazy concatenation
  /// of this sequence of strings with any other sequence of strings.
  GraphemeClusters operator +(GraphemeClusters other);

  /// The grapheme clusters of [string] with [other] inserted at [index].
  ///
  /// The [index] is a string can be any index into [string].
  GraphemeClusters insertAt(int index, GraphemeClusters other);

  /// The grapheme clusters of [string] with a substring replaced by other.
  GraphemeClusters replaceSubstring(
      int startIndex, int endIndex, GraphemeClusters other);

  /// The grapheme clusters of a substring of [string].
  ///
  /// The [startIndex] and [endIndex] must be a valid range of [string]
  /// (0 &le; `startIndex` &le; `endIndex` &le; `string.length`).
  /// If [endIndex] is omitted, it defaults to `string.length`.
  GraphemeClusters substring(int startIndex, [int endIndex]);

  /// Replaces [source] with [replacement].
  ///
  /// Returns a new [GrapehemeClusters] where all occurrences of the
  /// [source] grapheme cluster sequence are replaced by [replacement],
  /// unless the occurrence overlaps a prior replaced sequence.
  ///
  /// If [startIndex] is provided, only replace grapheme clusters
  /// starting no earlier than [startIndex] in [string].
  GraphemeClusters replaceAll(
      GraphemeClusters source, GraphemeClusters replacement,
      [int startIndex = 0]);

  /// Replaces the first [source] with [replacement].
  ///
  /// Returns a new [GraphemeClusters] where the first occurence of the
  /// [source] grapheme cluster sequence, if any, is replaced by [replacement].
  ///
  /// If [startIndex] is provided, replaces the first occurrence
  /// of [source] starting no earlier than [startIndex] in [string], if any.
  GraphemeClusters replaceFirst(
      GraphemeClusters source, GraphemeClusters replacement,
      [int startIndex = 0]);

  /// The grapheme clusters of the lower-case version of [string].
  GraphemeClusters toLowerCase();

  /// The grapheme clusters of the upper-case version of [string].
  GraphemeClusters toUpperCase();

  /// The hash code of [string].
  int get hashCode;

  /// Whether [other] to another [GraphemeClusters] with the same [string].
  bool operator ==(Object other);

  /// The [string] content of these grapheme clusters.
  String toString();
}

/// Iterator over grapheme clusters of a string.
abstract class GraphemeCluster implements BidirectionalIterator<String> {
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

  /// The code points of the current grapheme cluster.
  Runes get runes;

  /// Resets the iterator to the [index] position.
  ///
  /// There is no [current] grapheme cluster after a reset,
  /// a call to [moveNext] is needed to find the end of the grapheme cluster
  /// at the [index] position.
  /// A `reset(0)` will reset to the beginning of the string, as for a newly
  /// created iterator.
  void reset(int index);

  /// Creates a copy of this [GraphemeIterator].
  ///
  /// The copy is in the exact same state as this iterator.
  /// Can be used to iterate the following grapheme clusters more than once
  /// at the same time. To simply rewind an iterator, remember the
  /// [start] or [end] position and use [reset] to reset the iterator
  /// to that position.
  GraphemeCluster copy();
}
