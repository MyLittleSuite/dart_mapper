/*
 * Copyright (c) 2024 MyLittleSuite
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

part 'map_item.freezed.dart';

@freezed
abstract class FreezedMapItem with _$FreezedMapItem {
  const FreezedMapItem._();

  const factory FreezedMapItem({
    required String label,
    required int value,
  }) = _FreezedMapItem;
}

@freezed
abstract class FreezedMappedItem with _$FreezedMappedItem {
  const FreezedMappedItem._();

  const factory FreezedMappedItem({
    required String label,
    required int value,
  }) = _FreezedMappedItem;
}

@freezed
abstract class FreezedMapSource with _$FreezedMapSource {
  const FreezedMapSource._();

  const factory FreezedMapSource({
    required Map<String, int> scores,
    required Map<String, FreezedMapItem> details,
  }) = _FreezedMapSource;
}

@freezed
abstract class FreezedMapTarget with _$FreezedMapTarget {
  const FreezedMapTarget._();

  const factory FreezedMapTarget({
    required Map<String, int> scores,
    required Map<String, FreezedMappedItem> details,
  }) = _FreezedMapTarget;
}
