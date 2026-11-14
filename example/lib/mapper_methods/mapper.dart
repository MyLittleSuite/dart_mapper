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

import 'package:dart_mapper/dart_mapper.dart';
import 'package:dart_mapper_example/mapper_methods/models.dart';

part 'mapper.g.dart';

@Mapper()
abstract class OrderFieldMapper {
  @ValueMapping(source: ValueMapping.nullValue, target: 'name')
  @ValueMapping(source: ValueMapping.anyRemaining, target: 'name')
  OrderField from(String? value);

  String to(OrderField field);
}

/// The parameters are the sources: `field` goes through [OrderFieldMapper],
/// `descending` is copied as it is.
@Mapper(uses: {OrderFieldMapper})
abstract class OrderingMapper {
  Ordering from(String? field, bool descending);

  @Mapping(target: 'descending', expression: '!descending')
  Ordering fromReversed(String? field, bool descending);
}

/// `source: 'orderField,orderDescending'` is resolved to a method of
/// [OrderingMapper]. Both of its methods fit, so `qualifiedBy` picks one.
@Mapper(uses: {OrderingMapper})
abstract class SettingsMapper {
  @Mapping(
    source: 'orderField,orderDescending',
    target: 'ordering',
    qualifiedBy: 'OrderingMapper.from',
  )
  Settings from(SettingsDTO from);

  @Mapping(
    source: 'orderField,orderDescending',
    target: 'ordering',
    qualifiedBy: 'fromReversed',
  )
  Settings fromReversed(SettingsDTO from);

  /// `id` is a parameter: it binds to the target property with the same name.
  SettingsDTO fromCreate(CreateSettings from, String id);
}
