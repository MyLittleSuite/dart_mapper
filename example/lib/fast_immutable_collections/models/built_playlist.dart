/*
 * Copyright (c) 2026 MyLittleSuite
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */


import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

part 'built_playlist.g.dart';

abstract class BuiltTrack implements Built<BuiltTrack, BuiltTrackBuilder> {
  String get id;

  String get title;

  BuiltTrack._();

  // ignore: use_function_type_syntax_for_parameters
  factory BuiltTrack([void updates(BuiltTrackBuilder b)]) = _$BuiltTrack;
}

/// A built_value class holding the collections of built_collection.
abstract class BuiltPlaylist
    implements Built<BuiltPlaylist, BuiltPlaylistBuilder> {
  String get name;

  BuiltList<BuiltTrack> get tracks;

  BuiltSet<String> get tags;

  BuiltMap<String, int> get plays;

  BuiltMap<String, BuiltTrack> get featured;

  BuiltList<String>? get notes;

  BuiltPlaylist._();

  // ignore: use_function_type_syntax_for_parameters
  factory BuiltPlaylist([void updates(BuiltPlaylistBuilder b)]) =
      _$BuiltPlaylist;
}

/// A built_value class holding the collections of fast_immutable_collections.
abstract class BuiltImmutablePlaylist
    implements Built<BuiltImmutablePlaylist, BuiltImmutablePlaylistBuilder> {
  String get name;

  IList<BuiltTrack> get tracks;

  ISet<String> get tags;

  IMap<String, int> get plays;

  IMap<String, BuiltTrack> get featured;

  IList<String>? get notes;

  BuiltImmutablePlaylist._();

  factory BuiltImmutablePlaylist([
    // ignore: use_function_type_syntax_for_parameters
    void updates(BuiltImmutablePlaylistBuilder b),
  ]) = _$BuiltImmutablePlaylist;
}
