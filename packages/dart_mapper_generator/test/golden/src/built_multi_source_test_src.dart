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

// Golden test source for comma-separated sources, `qualifiedBy` and method
// parameters used as sources on built_value targets.
//
// The `_$...` implementations are not generated here: the generator only
// needs the `Built<T, TBuilder>` shape of the classes.

// ignore_for_file: depend_on_referenced_packages

import 'package:built_value/built_value.dart';
import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

enum BmOrderField { name, date }

class BmOrdering {
  final BmOrderField? field;
  final bool descending;

  const BmOrdering({this.field, required this.descending});
}

class BmSettingsDTO {
  final String? orderField;
  final bool orderDescending;
  final BmPage? page;
  final BmPage inner;

  const BmSettingsDTO({
    this.orderField,
    required this.orderDescending,
    this.page,
    required this.inner,
  });
}

class BmPage {
  final int size;
  final String? sortedBy;

  const BmPage({required this.size, this.sortedBy});
}

class BmNameDTO {
  final String name;
  final int number;

  const BmNameDTO({required this.name, required this.number});
}

abstract class BmSettings implements Built<BmSettings, BmSettingsBuilder> {
  BmOrdering get ordering;

  BmSettings._();

  factory BmSettings([void Function(BmSettingsBuilder) updates]) = _$BmSettings;
}

abstract class BmSettingsBuilder
    implements Builder<BmSettings, BmSettingsBuilder> {
  BmOrdering? ordering;

  BmSettingsBuilder._();

  factory BmSettingsBuilder() = _$BmSettingsBuilder;
}

class _$BmSettings extends BmSettings {
  @override
  BmOrdering get ordering => throw UnimplementedError();

  _$BmSettings([void Function(BmSettingsBuilder)? updates]) : super._();

  @override
  BmSettings rebuild(void Function(BmSettingsBuilder) updates) =>
      throw UnimplementedError();

  @override
  BmSettingsBuilder toBuilder() => throw UnimplementedError();
}

class _$BmSettingsBuilder extends BmSettingsBuilder {
  _$BmSettingsBuilder() : super._();

  @override
  void replace(BmSettings other) {}

  @override
  void update(void Function(BmSettingsBuilder)? updates) {}

  @override
  BmSettings build() => throw UnimplementedError();
}

abstract class BmLabeled implements Built<BmLabeled, BmLabeledBuilder> {
  String get id;

  String get label;

  BmLabeled._();

  factory BmLabeled([void Function(BmLabeledBuilder) updates]) = _$BmLabeled;
}

abstract class BmLabeledBuilder
    implements Builder<BmLabeled, BmLabeledBuilder> {
  String? id;
  String? label;

  BmLabeledBuilder._();

  factory BmLabeledBuilder() = _$BmLabeledBuilder;
}

class _$BmLabeled extends BmLabeled {
  @override
  String get id => throw UnimplementedError();

  @override
  String get label => throw UnimplementedError();

  _$BmLabeled([void Function(BmLabeledBuilder)? updates]) : super._();

  @override
  BmLabeled rebuild(void Function(BmLabeledBuilder) updates) =>
      throw UnimplementedError();

  @override
  BmLabeledBuilder toBuilder() => throw UnimplementedError();
}

class _$BmLabeledBuilder extends BmLabeledBuilder {
  _$BmLabeledBuilder() : super._();

  @override
  void replace(BmLabeled other) {}

  @override
  void update(void Function(BmLabeledBuilder)? updates) {}

  @override
  BmLabeled build() => throw UnimplementedError();
}

BmOrdering bmOrderingOf(String? field, bool descending) => BmOrdering(
      field: field == null ? null : BmOrderField.values.byName(field),
      descending: descending,
    );

String bmJoin(String prefix, String name) => '$prefix-$name';

@Mapper()
abstract class BmOrderFieldMapper {
  @ValueMapping(source: ValueMapping.nullValue, target: 'name')
  @ValueMapping(source: ValueMapping.anyRemaining, target: 'name')
  BmOrderField from(String? value);
}

@Mapper(uses: {BmOrderFieldMapper})
abstract class BmOrderingMapper {
  BmOrdering from(String? field, bool descending);
}

@Mapper()
abstract class BmFlatOrderingMapper {
  BmOrdering fromFlat(String? field, bool descending);

  BmOrdering fromFlatReversed(String? field, bool descending);
}

@Mapper()
abstract class BmSizeOrderingMapper {
  BmOrdering fromSize(int? size, bool descending);
}

@Mapper()
abstract class BmStrictSizeOrderingMapper {
  BmOrdering fromSize(int size, bool descending);
}

@Mapper()
abstract class BmFormatMapper {
  String hex(int value);

  String decimal(int value);
}

// ----- comma-separated source + callable -----

@ShouldGenerate(
  r'''class BmCallableMapperImpl extends BmCallableMapper {
  BmCallableMapperImpl();

  @override
  BmSettings from(BmSettingsDTO dto) {
    return BmSettings(
      (b) => b..ordering = bmOrderingOf(dto.orderField, dto.orderDescending),
    );
  }
}''',
  contains: true,
)
@Mapper()
abstract class BmCallableMapper {
  @Mapping(
    source: 'orderField,orderDescending',
    target: 'ordering',
    callable: bmOrderingOf,
  )
  BmSettings from(BmSettingsDTO dto);
}

// ----- comma-separated source + mapper method -----

@ShouldGenerate(
  r'''class BmUsesMapperImpl extends BmUsesMapper {
  BmUsesMapperImpl({required this.bmOrderingMapper});

  final BmOrderingMapper bmOrderingMapper;

  @override
  BmSettings from(BmSettingsDTO dto) {
    return BmSettings(
      (b) => b
        ..ordering = bmOrderingMapper.from(dto.orderField, dto.orderDescending),
    );
  }
}''',
  contains: true,
)
@Mapper(uses: {BmOrderingMapper})
abstract class BmUsesMapper {
  @Mapping(source: 'orderField,orderDescending', target: 'ordering')
  BmSettings from(BmSettingsDTO dto);
}

// Dot notation and a nullable link: the parameter must be nullable.
@ShouldGenerate(
  r'''class BmDotUsesMapperImpl extends BmDotUsesMapper {
  BmDotUsesMapperImpl({required this.bmSizeOrderingMapper});

  final BmSizeOrderingMapper bmSizeOrderingMapper;

  @override
  BmSettings from(BmSettingsDTO dto) {
    return BmSettings(
      (b) => b
        ..ordering = bmSizeOrderingMapper.fromSize(
          dto.page?.size,
          dto.orderDescending,
        ),
    );
  }
}''',
  contains: true,
)
@Mapper(uses: {BmSizeOrderingMapper})
abstract class BmDotUsesMapper {
  @Mapping(source: 'page.size,orderDescending', target: 'ordering')
  BmSettings from(BmSettingsDTO dto);
}

@ShouldGenerate(
  r'''class BmDotStrictMapperImpl extends BmDotStrictMapper {
  BmDotStrictMapperImpl({required this.bmStrictSizeOrderingMapper});

  final BmStrictSizeOrderingMapper bmStrictSizeOrderingMapper;

  @override
  BmSettings from(BmSettingsDTO dto) {
    return BmSettings(
      (b) => b
        ..ordering = bmStrictSizeOrderingMapper.fromSize(
          dto.inner.size,
          dto.orderDescending,
        ),
    );
  }
}''',
  contains: true,
)
@Mapper(uses: {BmStrictSizeOrderingMapper})
abstract class BmDotStrictMapper {
  @Mapping(source: 'inner.size,orderDescending', target: 'ordering')
  BmSettings from(BmSettingsDTO dto);
}

// A method of the mapper itself is a candidate; the one being generated is not.
@ShouldGenerate(
  r'''class BmOwnMethodMapperImpl extends BmOwnMethodMapper {
  BmOwnMethodMapperImpl();

  @override
  BmSettings from(BmSettingsDTO dto) {
    return BmSettings(
      (b) => b..ordering = order(dto.orderField, dto.orderDescending),
    );
  }

  @override
  BmOrdering order(String? field, bool descending) {
    return BmOrdering(field: field, descending: descending);
  }
}''',
  contains: true,
)
@Mapper()
abstract class BmOwnMethodMapper {
  @Mapping(source: 'orderField,orderDescending', target: 'ordering')
  BmSettings from(BmSettingsDTO dto);

  BmOrdering order(String? field, bool descending);
}

// ----- qualifiedBy -----

@ShouldGenerate(
  r'''class BmQualifiedMapperImpl extends BmQualifiedMapper {
  BmQualifiedMapperImpl({required this.bmFlatOrderingMapper});

  final BmFlatOrderingMapper bmFlatOrderingMapper;

  @override
  BmSettings from(BmSettingsDTO dto) {
    return BmSettings(
      (b) => b
        ..ordering = bmFlatOrderingMapper.fromFlatReversed(
          dto.orderField,
          dto.orderDescending,
        ),
    );
  }
}''',
  contains: true,
)
@Mapper(uses: {BmFlatOrderingMapper})
abstract class BmQualifiedMapper {
  @Mapping(
    source: 'orderField,orderDescending',
    target: 'ordering',
    qualifiedBy: 'BmFlatOrderingMapper.fromFlatReversed',
  )
  BmSettings from(BmSettingsDTO dto);
}

@ShouldGenerate(
  r'''class BmQualifiedSingleMapperImpl extends BmQualifiedSingleMapper {
  BmQualifiedSingleMapperImpl({required this.bmFormatMapper});

  final BmFormatMapper bmFormatMapper;

  @override
  BmLabeled from(BmNameDTO dto, String id) {
    return BmLabeled(
      (b) => b
        ..label = bmFormatMapper.hex(dto.number)
        ..id = id,
    );
  }
}''',
  contains: true,
)
@Mapper(uses: {BmFormatMapper})
abstract class BmQualifiedSingleMapper {
  @Mapping(source: 'number', target: 'label', qualifiedBy: 'hex')
  BmLabeled from(BmNameDTO dto, String id);
}

// ----- method parameters as sources -----

@ShouldGenerate(
  r'''class BmParameterMapperImpl extends BmParameterMapper {
  BmParameterMapperImpl();

  @override
  BmLabeled from(BmNameDTO dto, String id) {
    return BmLabeled(
      (b) => b
        ..label = bmJoin(id, dto.name)
        ..id = id,
    );
  }
}''',
  contains: true,
)
@Mapper()
abstract class BmParameterMapper {
  @Mapping(
    source: 'id,name',
    target: 'label',
    callable: bmJoin,
  )
  BmLabeled from(BmNameDTO dto, String id);
}

// ----- errors -----

@ShouldThrow(
  r'''Ambiguous mapper method for @Mapping(target: 'ordering'): multiple methods match (BmFlatOrderingMapper.fromFlat(String? field, bool descending), BmFlatOrderingMapper.fromFlatReversed(String? field, bool descending)).
Fix: Select the one to use with @Mapping(target: 'ordering', qualifiedBy: 'methodName') or qualifiedBy: 'MapperClass.methodName'.''',
)
@Mapper(uses: {BmFlatOrderingMapper})
abstract class BmAmbiguousMapper {
  @Mapping(source: 'orderField,orderDescending', target: 'ordering')
  BmSettings from(BmSettingsDTO dto);
}

@ShouldThrow(
  r'''No mapper method found for @Mapping(target: 'ordering') with source (String? dto.orderField, bool dto.orderDescending, int dto.inner.size) returning BmOrdering.
Rejected candidates:
  - BmOrderingMapper.from(String? field, bool descending): takes 2 parameter(s), 3 source(s) given
Fix: Add a mapper method (in the mapper or in a mapper listed in uses) taking these parameters in this order and returning a value assignable to the target, or use callable.''',
)
@Mapper(uses: {BmOrderingMapper})
abstract class BmNoMatchMapper {
  @Mapping(source: 'orderField,orderDescending,inner.size', target: 'ordering')
  BmSettings from(BmSettingsDTO dto);
}

@ShouldThrow(
  r'''No mapper method found for @Mapping(target: 'ordering') with source (int? dto.page.size, bool dto.orderDescending) returning BmOrdering.
Rejected candidates:
  - BmStrictSizeOrderingMapper.fromSize(int size, bool descending): argument 1 (`dto.page.size`) may be null (int?) but parameter 1 is int
Fix: Add a mapper method (in the mapper or in a mapper listed in uses) taking these parameters in this order and returning a value assignable to the target, or use callable.''',
)
@Mapper(uses: {BmStrictSizeOrderingMapper})
abstract class BmNullableChainMapper {
  @Mapping(source: 'page.size,orderDescending', target: 'ordering')
  BmSettings from(BmSettingsDTO dto);
}

@ShouldThrow(
  r'''qualifiedBy 'missing' in @Mapping(target: 'ordering') does not match any mapper method.
Available methods: BmOrderingMapper.from.
Fix: Use 'methodName' or 'MapperClass.methodName' of a method of the mapper or of a mapper listed in uses.''',
)
@Mapper(uses: {BmOrderingMapper})
abstract class BmUnknownQualifiedMapper {
  @Mapping(
    source: 'orderField,orderDescending',
    target: 'ordering',
    qualifiedBy: 'missing',
  )
  BmSettings from(BmSettingsDTO dto);
}

@ShouldThrow(
  r'''Comma-separated source part 'nothing' in @Mapping(target: 'ordering') could not be resolved on any source parameter.
Fix: Check that each comma-separated part refers to a valid field or qualified dot-path (paramName.fieldName).''',
)
@Mapper()
abstract class BmUnresolvedPartMapper {
  @Mapping(
    source: 'orderField,nothing',
    target: 'ordering',
    callable: bmOrderingOf,
  )
  BmSettings from(BmSettingsDTO dto);
}
