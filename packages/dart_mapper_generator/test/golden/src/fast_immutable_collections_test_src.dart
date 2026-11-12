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

// Golden test source for the collections of fast_immutable_collections
// (IList, ISet, IMap, IMapOfSets, ListSet, ListMap) held by plain,
// freezed-like and built_value classes.
//
// The built_value classes are not generated here: the generator only needs
// their `Built<T, TBuilder>` shape.

// ignore_for_file: depend_on_referenced_packages

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:dart_mapper/dart_mapper.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:source_gen_test/annotations.dart';

// --- Plain classes holding dart:core collections ---

class FicTrackDto {
  final String id;

  const FicTrackDto({required this.id});
}

class FicPlaylistDto {
  final List<FicTrackDto> tracks;
  final Set<String> tags;
  final Map<String, int> plays;
  final Map<String, FicTrackDto> featured;
  final List<String>? notes;

  const FicPlaylistDto({
    required this.tracks,
    required this.tags,
    required this.plays,
    required this.featured,
    this.notes,
  });
}

// --- Plain classes holding immutable collections ---

class FicTrack {
  final String id;

  const FicTrack({required this.id});
}

class FicPlaylist {
  final IList<FicTrack> tracks;
  final ISet<String> tags;
  final IMap<String, int> plays;
  final IMap<String, FicTrack> featured;
  final IList<String>? notes;

  const FicPlaylist({
    required this.tracks,
    required this.tags,
    required this.plays,
    required this.featured,
    this.notes,
  });
}

// --- Freezed-like classes holding immutable collections ---

class FicFreezedLikeTrack {
  final String id;

  const FicFreezedLikeTrack({required this.id});
}

class FicFreezedLikePlaylist {
  final IList<FicFreezedLikeTrack> tracks;
  final ISet<String> tags;
  final IMap<String, int> plays;
  final IMap<String, FicFreezedLikeTrack> featured;
  final IList<String>? notes;

  const FicFreezedLikePlaylist({
    required this.tracks,
    required this.tags,
    required this.plays,
    required this.featured,
    this.notes,
  });
}

// --- built_value classes ---

abstract class FicBuiltTrack
    implements Built<FicBuiltTrack, FicBuiltTrackBuilder> {
  String get id;

  factory FicBuiltTrack([void Function(FicBuiltTrackBuilder)? updates]) =>
      throw UnimplementedError();
}

abstract class FicBuiltTrackBuilder
    implements Builder<FicBuiltTrack, FicBuiltTrackBuilder> {
  String? id;

  factory FicBuiltTrackBuilder() => throw UnimplementedError();
}

/// Holds the collections of built_collection.
abstract class FicBuiltPlaylist
    implements Built<FicBuiltPlaylist, FicBuiltPlaylistBuilder> {
  BuiltList<FicBuiltTrack> get tracks;

  BuiltSet<String> get tags;

  BuiltMap<String, int> get plays;

  BuiltMap<String, FicBuiltTrack> get featured;

  BuiltList<String>? get notes;

  factory FicBuiltPlaylist([void Function(FicBuiltPlaylistBuilder)? updates]) =>
      throw UnimplementedError();
}

abstract class FicBuiltPlaylistBuilder
    implements Builder<FicBuiltPlaylist, FicBuiltPlaylistBuilder> {
  ListBuilder<FicBuiltTrack>? tracks;
  SetBuilder<String>? tags;
  MapBuilder<String, int>? plays;
  MapBuilder<String, FicBuiltTrack>? featured;
  ListBuilder<String>? notes;

  factory FicBuiltPlaylistBuilder() => throw UnimplementedError();
}

/// Holds the collections of fast_immutable_collections.
abstract class FicBuiltImmutablePlaylist
    implements
        Built<FicBuiltImmutablePlaylist, FicBuiltImmutablePlaylistBuilder> {
  IList<FicBuiltTrack> get tracks;

  ISet<String> get tags;

  IMap<String, int> get plays;

  IMap<String, FicBuiltTrack> get featured;

  IList<String>? get notes;

  factory FicBuiltImmutablePlaylist([
    void Function(FicBuiltImmutablePlaylistBuilder)? updates,
  ]) =>
      throw UnimplementedError();
}

abstract class FicBuiltImmutablePlaylistBuilder
    implements
        Builder<FicBuiltImmutablePlaylist, FicBuiltImmutablePlaylistBuilder> {
  IList<FicBuiltTrack>? tracks;
  ISet<String>? tags;
  IMap<String, int>? plays;
  IMap<String, FicBuiltTrack>? featured;
  IList<String>? notes;

  factory FicBuiltImmutablePlaylistBuilder() => throw UnimplementedError();
}

// --- ListSet, ListMap and IMapOfSets ---

class FicLibraryDto {
  final List<FicTrackDto> queue;
  final Map<String, int> ratings;
  final IMapOfSets<String, FicTrackDto> tracksByGenre;
  final Map<String, Set<String>> genresByArtist;
  final List<String>? history;

  const FicLibraryDto({
    required this.queue,
    required this.ratings,
    required this.tracksByGenre,
    required this.genresByArtist,
    this.history,
  });
}

class FicLibrary {
  final ListSet<FicTrack> queue;
  final ListMap<String, int> ratings;
  final IMapOfSets<String, FicTrack> tracksByGenre;
  final IMapOfSets<String, String> genresByArtist;
  final ListSet<String>? history;

  const FicLibrary({
    required this.queue,
    required this.ratings,
    required this.tracksByGenre,
    required this.genresByArtist,
    this.history,
  });
}

// --- Mappers ---

@ShouldGenerate(
  r'''class FicPlainMapperImpl extends FicPlainMapper {
  FicPlainMapperImpl();

  @override
  FicPlaylist toPlaylist(FicPlaylistDto dto) {
    return FicPlaylist(
      tracks: dto.tracks
          .map((item) => _mapFicTrackDtoToFicTrack(item))
          .toIList(),
      tags: dto.tags.toISet(),
      plays: dto.plays.toIMap(),
      featured: dto.featured
          .map((key, value) => MapEntry(key, _mapFicTrackDtoToFicTrack(value)))
          .toIMap(),
      notes: dto.notes?.toIList(),
    );
  }

  @override
  FicPlaylistDto toDto(FicPlaylist playlist) {
    return FicPlaylistDto(
      tracks: playlist.tracks
          .map((item) => _mapFicTrackToFicTrackDto(item))
          .toList(growable: true),
      tags: playlist.tags.map((item) => item).toSet(),
      plays: playlist.plays.unlock,
      featured: playlist.featured
          .map((key, value) => MapEntry(key, _mapFicTrackToFicTrackDto(value)))
          .unlock,
      notes: playlist.notes?.map((item) => item).toList(growable: true),
    );
  }

  FicTrack _mapFicTrackDtoToFicTrack(FicTrackDto ficTrackDto) {
    return FicTrack(id: ficTrackDto.id);
  }

  FicTrackDto _mapFicTrackToFicTrackDto(FicTrack ficTrack) {
    return FicTrackDto(id: ficTrack.id);
  }
}''',
  contains: true,
)
@Mapper()
abstract class FicPlainMapper {
  FicPlaylist toPlaylist(FicPlaylistDto dto);

  FicPlaylistDto toDto(FicPlaylist playlist);
}

@ShouldGenerate(
  r'''class FicFreezedLikeMapperImpl extends FicFreezedLikeMapper {
  FicFreezedLikeMapperImpl();

  @override
  FicFreezedLikePlaylist fromPlaylist(FicPlaylist playlist) {
    return FicFreezedLikePlaylist(
      tracks: playlist.tracks
          .map((item) => _mapFicTrackToFicFreezedLikeTrack(item))
          .toIList(),
      tags: playlist.tags,
      plays: playlist.plays,
      featured: playlist.featured.map(
        (key, value) => MapEntry(key, _mapFicTrackToFicFreezedLikeTrack(value)),
      ),
      notes: playlist.notes,
    );
  }

  @override
  FicFreezedLikePlaylist fromDto(FicPlaylistDto dto) {
    return FicFreezedLikePlaylist(
      tracks: dto.tracks
          .map((item) => _mapFicTrackDtoToFicFreezedLikeTrack(item))
          .toIList(),
      tags: dto.tags.toISet(),
      plays: dto.plays.toIMap(),
      featured: dto.featured
          .map(
            (key, value) =>
                MapEntry(key, _mapFicTrackDtoToFicFreezedLikeTrack(value)),
          )
          .toIMap(),
      notes: dto.notes?.toIList(),
    );
  }

  FicFreezedLikeTrack _mapFicTrackToFicFreezedLikeTrack(FicTrack ficTrack) {
    return FicFreezedLikeTrack(id: ficTrack.id);
  }

  FicFreezedLikeTrack _mapFicTrackDtoToFicFreezedLikeTrack(
    FicTrackDto ficTrackDto,
  ) {
    return FicFreezedLikeTrack(id: ficTrackDto.id);
  }
}''',
  contains: true,
)
@Mapper()
abstract class FicFreezedLikeMapper {
  FicFreezedLikePlaylist fromPlaylist(FicPlaylist playlist);

  FicFreezedLikePlaylist fromDto(FicPlaylistDto dto);
}

@ShouldGenerate(
  r'''class FicBuiltMapperImpl extends FicBuiltMapper {
  FicBuiltMapperImpl();

  @override
  FicBuiltPlaylist toBuilt(FicPlaylist playlist) {
    return FicBuiltPlaylist(
      (b) => b
        ..tracks = ListBuilder(
          playlist.tracks
              .map((item) => _mapFicTrackToFicBuiltTrack(item).build())
              .toList(growable: true),
        )
        ..tags = SetBuilder(playlist.tags.map((item) => item).toSet())
        ..plays = MapBuilder(playlist.plays.unlockView)
        ..featured = MapBuilder(
          playlist.featured
              .map(
                (key, value) =>
                    MapEntry(key, _mapFicTrackToFicBuiltTrack(value).build()),
              )
              .unlockView,
        )
        ..notes = playlist.notes != null
            ? ListBuilder(
                playlist.notes?.map((item) => item).toList(growable: true) ??
                    [],
              )
            : null,
    );
  }

  @override
  FicPlaylist fromBuilt(FicBuiltPlaylist playlist) {
    return FicPlaylist(
      tracks: playlist.tracks
          .map((item) => _mapFicBuiltTrackToFicTrack(item))
          .toIList(),
      tags: playlist.tags.toISet(),
      plays: playlist.plays.asMap().toIMap(),
      featured: playlist.featured
          .map(
            (key, value) => MapEntry(key, _mapFicBuiltTrackToFicTrack(value)),
          )
          .asMap()
          .toIMap(),
      notes: playlist.notes?.toIList(),
    );
  }

  @override
  FicBuiltImmutablePlaylist toBuiltImmutable(FicPlaylistDto dto) {
    return FicBuiltImmutablePlaylist(
      (b) => b
        ..tracks = dto.tracks
            .map((item) => _mapFicTrackDtoToFicBuiltTrack(item).build())
            .toIList()
        ..tags = dto.tags.toISet()
        ..plays = dto.plays.toIMap()
        ..featured = dto.featured
            .map(
              (key, value) =>
                  MapEntry(key, _mapFicTrackDtoToFicBuiltTrack(value).build()),
            )
            .toIMap()
        ..notes = dto.notes?.toIList(),
    );
  }

  @override
  FicPlaylistDto fromBuiltImmutable(FicBuiltImmutablePlaylist playlist) {
    return FicPlaylistDto(
      tracks: playlist.tracks
          .map((item) => _mapFicBuiltTrackToFicTrackDto(item))
          .toList(growable: true),
      tags: playlist.tags.map((item) => item).toSet(),
      plays: playlist.plays.unlock,
      featured: playlist.featured
          .map(
            (key, value) =>
                MapEntry(key, _mapFicBuiltTrackToFicTrackDto(value)),
          )
          .unlock,
      notes: playlist.notes?.map((item) => item).toList(growable: true),
    );
  }

  FicBuiltTrackBuilder _mapFicTrackToFicBuiltTrack(FicTrack ficTrack) {
    return FicBuiltTrackBuilder()
      ..replace(FicBuiltTrack((b) => b..id = ficTrack.id));
  }

  FicTrack _mapFicBuiltTrackToFicTrack(FicBuiltTrack ficBuiltTrack) {
    return FicTrack(id: ficBuiltTrack.id);
  }

  FicBuiltTrackBuilder _mapFicTrackDtoToFicBuiltTrack(FicTrackDto ficTrackDto) {
    return FicBuiltTrackBuilder()
      ..replace(FicBuiltTrack((b) => b..id = ficTrackDto.id));
  }

  FicTrackDto _mapFicBuiltTrackToFicTrackDto(FicBuiltTrack ficBuiltTrack) {
    return FicTrackDto(id: ficBuiltTrack.id);
  }
}''',
  contains: true,
)
@Mapper()
abstract class FicBuiltMapper {
  FicBuiltPlaylist toBuilt(FicPlaylist playlist);

  FicPlaylist fromBuilt(FicBuiltPlaylist playlist);

  FicBuiltImmutablePlaylist toBuiltImmutable(FicPlaylistDto dto);

  FicPlaylistDto fromBuiltImmutable(FicBuiltImmutablePlaylist playlist);
}

@ShouldGenerate(
  r'''class FicLibraryMapperImpl extends FicLibraryMapper {
  FicLibraryMapperImpl();

  @override
  FicLibrary toLibrary(FicLibraryDto dto) {
    return FicLibrary(
      queue: ListSet.of(
        dto.queue.map((item) => _mapFicTrackDtoToFicTrack(item)),
      ),
      ratings: ListMap.of(dto.ratings),
      tracksByGenre: dto.tracksByGenre.map(
        (key, value) => MapEntry(
          key,
          value.map((item) => _mapFicTrackDtoToFicTrack(item)).toISet(),
        ),
      ),
      genresByArtist: IMapOfSets(dto.genresByArtist),
      history: dto.history != null ? ListSet.of(dto.history!) : null,
    );
  }

  @override
  FicLibraryDto toDto(FicLibrary library) {
    return FicLibraryDto(
      queue: library.queue
          .map((item) => _mapFicTrackToFicTrackDto(item))
          .toList(growable: true),
      ratings: library.ratings.map((key, value) => MapEntry(key, value)),
      tracksByGenre: library.tracksByGenre.map(
        (key, value) => MapEntry(
          key,
          value.map((item) => _mapFicTrackToFicTrackDto(item)).toISet(),
        ),
      ),
      genresByArtist: library.genresByArtist.unlock,
      history: library.history?.map((item) => item).toList(growable: true),
    );
  }

  FicTrack _mapFicTrackDtoToFicTrack(FicTrackDto ficTrackDto) {
    return FicTrack(id: ficTrackDto.id);
  }

  FicTrackDto _mapFicTrackToFicTrackDto(FicTrack ficTrack) {
    return FicTrackDto(id: ficTrack.id);
  }
}''',
  contains: true,
)
@Mapper()
abstract class FicLibraryMapper {
  FicLibrary toLibrary(FicLibraryDto dto);

  FicLibraryDto toDto(FicLibrary library);
}

@ShouldGenerate(
  r'''class FicMapMapperImpl extends FicMapMapper {
  FicMapMapperImpl();

  @override
  Map<String, dynamic> toMap(FicPlaylist playlist) {
    return {
      'tracks': playlist.tracks.map((item) => _mapFicTrackToMap(item)).toList(),
      'tags': playlist.tags.toSet(),
      'plays': playlist.plays.unlock,
      'featured': playlist.featured.unlock.map(
        (key, value) => MapEntry(key, _mapFicTrackToMap(value)),
      ),
      'notes': playlist.notes?.toList(),
    };
  }

  @override
  FicPlaylist fromMap(Map<String, dynamic> map) {
    return FicPlaylist(
      tracks: (map['tracks'] as Iterable)
          .map<FicTrack>(
            (e) => _mapMapToFicTrack(Map<String, dynamic>.from(e as Map)),
          )
          .toIList(),
      tags: List<String>.from(map['tags'] as Iterable).toISet(),
      plays: Map<String, int>.from(map['plays'] as Map).toIMap(),
      featured: (map['featured'] as Map)
          .map<String, FicTrack>(
            (key, value) => MapEntry(
              key as String,
              _mapMapToFicTrack(Map<String, dynamic>.from(value as Map)),
            ),
          )
          .toIMap(),
      notes: map['notes'] != null
          ? List<String>.from(map['notes'] as Iterable).toIList()
          : null,
    );
  }

  Map<String, dynamic> _mapFicTrackToMap(FicTrack ficTrack) {
    return {'id': ficTrack.id};
  }

  FicTrack _mapMapToFicTrack(Map<String, dynamic> map) {
    return FicTrack(id: map['id'] as String);
  }
}''',
  contains: true,
)
@Mapper()
abstract class FicMapMapper {
  Map<String, dynamic> toMap(FicPlaylist playlist);

  FicPlaylist fromMap(Map<String, dynamic> map);
}

IList<FicTrack> _toTracks(List<FicTrackDto> tracks) =>
    tracks.map((track) => FicTrack(id: track.id)).toIList();

@ShouldGenerate(
  r'''class FicCallableMapperImpl extends FicCallableMapper {
  FicCallableMapperImpl();

  @override
  FicPlaylist toPlaylist(FicPlaylistDto dto) {
    return FicPlaylist(
      tracks: _toTracks(dto.tracks),
      tags: dto.tags.toISet(),
      plays: dto.plays.toIMap(),
      featured: dto.featured
          .map((key, value) => MapEntry(key, _mapFicTrackDtoToFicTrack(value)))
          .toIMap(),
      notes: dto.notes?.toIList(),
    );
  }

  FicTrack _mapFicTrackDtoToFicTrack(FicTrackDto ficTrackDto) {
    return FicTrack(id: ficTrackDto.id);
  }
}''',
  contains: true,
)
@Mapper()
abstract class FicCallableMapper {
  @Mapping(target: 'tracks', callable: _toTracks)
  FicPlaylist toPlaylist(FicPlaylistDto dto);
}

/// Hand-written methods converting a whole collection are called as they are.
@ShouldGenerate(
  r'''class FicWholeCollectionMapperImpl extends FicWholeCollectionMapper {
  FicWholeCollectionMapperImpl();

  @override
  FicPlaylist toPlaylist(FicPlaylistDto dto) {
    return FicPlaylist(
      tracks: toTracks(dto.tracks),
      tags: dto.tags.toISet(),
      plays: dto.plays.toIMap(),
      featured: toFeatured(dto.featured),
      notes: dto.notes?.toIList(),
    );
  }
}''',
  contains: true,
)
@Mapper()
abstract class FicWholeCollectionMapper {
  FicPlaylist toPlaylist(FicPlaylistDto dto);

  IList<FicTrack> toTracks(List<FicTrackDto> tracks) =>
      tracks.map((track) => FicTrack(id: track.id)).toIList();

  IMap<String, FicTrack> toFeatured(Map<String, FicTrackDto> featured) =>
      featured
          .map((key, value) => MapEntry(key, FicTrack(id: value.id)))
          .toIMap();
}
