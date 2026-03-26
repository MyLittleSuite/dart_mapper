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

part 'dynamic_item.freezed.dart';

@freezed
abstract class FreezedDynamicSource with _$FreezedDynamicSource {
  const FreezedDynamicSource._();

  const factory FreezedDynamicSource({
    required String id,
    required dynamic payload,
  }) = _FreezedDynamicSource;
}

@freezed
abstract class FreezedDynamicTarget with _$FreezedDynamicTarget {
  const FreezedDynamicTarget._();

  const factory FreezedDynamicTarget({
    required String id,
    required dynamic payload,
  }) = _FreezedDynamicTarget;
}
