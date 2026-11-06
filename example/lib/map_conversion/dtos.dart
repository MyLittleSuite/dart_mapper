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

import 'package:freezed_annotation/freezed_annotation.dart';

part 'dtos.freezed.dart';

/// The lifecycle of a [SessionDTO], stored by name in the map.
enum SessionStatus { open, revealed, closed }

/// A user document, e.g. stored in Cloud Firestore.
@freezed
abstract class UserDTO with _$UserDTO {
  const factory UserDTO({
    required String id,
    String? email,
    String? displayName,
    String? phoneNumber,
    String? photoURL,
    bool? verified,
  }) = _UserDTO;
}

/// A card, nested inside a session as a map of maps.
@freezed
abstract class CardDTO with _$CardDTO {
  const factory CardDTO({
    required String id,
    required String label,
    // Stored as `num` in the map, converted with `toDouble()` when read.
    required double value,
  }) = _CardDTO;
}

/// A session, e.g. stored in Firebase Realtime Database.
@freezed
abstract class SessionDTO with _$SessionDTO {
  const factory SessionDTO({
    required String id,
    required SessionStatus status,
    // Converted through `DateTimeMillisConverter` (declared in `uses`).
    required DateTime createdAt,
    required Map<String, CardDTO> votes,
    required List<String> tags,
  }) = _SessionDTO;
}

/// A room, whose `id` is the key of the node and not part of its value.
@freezed
abstract class RoomDTO with _$RoomDTO {
  const RoomDTO._();

  const factory RoomDTO({
    required String id,
    required String name,
    String? owner,
    SessionDTO? session,
  }) = _RoomDTO;

  /// Computed getter: it is not a constructor parameter, so it never
  /// becomes a key of the generated map.
  bool get hasSession => session != null;
}
