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
import 'package:dart_mapper/dart_mapper.dart';
import 'package:dart_mapper_example/fast_immutable_collections/models/built_playlist.dart';
import 'package:dart_mapper_example/fast_immutable_collections/models/freezed_playlist.dart';
import 'package:dart_mapper_example/fast_immutable_collections/models/immutable.dart';
import 'package:dart_mapper_example/fast_immutable_collections/models/library.dart';
import 'package:dart_mapper_example/fast_immutable_collections/models/plain.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

part 'fast_immutable_collections_mapper.g.dart';

/// Plain classes: `dart:core` collections <-> immutable collections.
@Mapper()
abstract class PlaylistMapper {
  const PlaylistMapper();

  Playlist toPlaylist(PlaylistDto dto);

  PlaylistDto toDto(Playlist playlist);
}

/// Freezed classes holding immutable collections.
@Mapper()
abstract class FreezedPlaylistMapper {
  const FreezedPlaylistMapper();

  FreezedPlaylist fromDto(PlaylistDto dto);

  PlaylistDto toDto(FreezedPlaylist playlist);

  FreezedPlaylist fromPlaylist(Playlist playlist);

  Playlist toPlaylist(FreezedPlaylist playlist);
}

/// built_value classes: built collections <-> immutable collections.
@Mapper()
abstract class BuiltPlaylistMapper {
  const BuiltPlaylistMapper();

  BuiltPlaylist toBuilt(Playlist playlist);

  Playlist fromBuilt(BuiltPlaylist playlist);

  BuiltImmutablePlaylist toBuiltImmutable(PlaylistDto dto);

  PlaylistDto fromBuiltImmutable(BuiltImmutablePlaylist playlist);

  FreezedPlaylist toFreezed(BuiltPlaylist playlist);
}

/// `ListSet`, `ListMap` and `IMapOfSets`.
@Mapper()
abstract class LibraryMapper {
  const LibraryMapper();

  Library toLibrary(LibraryDto dto);

  LibraryDto toDto(Library library);
}

/// Classes holding immutable collections <-> `Map<String, dynamic>`.
@Mapper()
abstract class PlaylistMapMapper {
  const PlaylistMapMapper();

  Map<String, dynamic> toMap(Playlist playlist);

  Playlist fromMap(Map<String, dynamic> map);
}
