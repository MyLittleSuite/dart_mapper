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

// Golden test source for `qualifiedBy`: picks the mapper method by name,
// `'method'` or `'MapperClass.method'`, on single and comma-separated sources.

import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

class QbSource {
  final String? code;
  final String label;
  final String? orderField;
  final bool orderDescending;

  const QbSource({
    required this.code,
    required this.label,
    required this.orderField,
    required this.orderDescending,
  });
}

class QbTag {
  final String value;

  const QbTag(this.value);
}

class QbTarget {
  final QbTag tag;

  const QbTarget({required this.tag});
}

class QbPair {
  final String value;

  const QbPair(this.value);
}

class QbPairTarget {
  final QbPair pair;

  const QbPairTarget({required this.pair});
}

@Mapper()
abstract class QbTagMapper {
  QbTag upper(String value) => QbTag(value.toUpperCase());

  QbTag lower(String value) => QbTag(value.toLowerCase());

  QbPair join(String? first, bool second) => QbPair('$first$second');

  QbPair joinReversed(String? first, bool second) => QbPair('$second$first');
}

@Mapper()
abstract class QbOtherTagMapper {
  QbTag upper(String value) => QbTag(value);
}

// Several methods share the signature: qualifiedBy picks one.
@ShouldGenerate(
  r'''class QbMethodNameMapperImpl extends QbMethodNameMapper {
  QbMethodNameMapperImpl({required this.qbTagMapper});

  final QbTagMapper qbTagMapper;

  @override
  QbTarget from(QbSource from) {
    return QbTarget(tag: qbTagMapper.lower(from.label));
  }
}''',
  contains: true,
)
@Mapper(uses: {QbTagMapper})
abstract class QbMethodNameMapper {
  @Mapping(source: 'label', target: 'tag', qualifiedBy: 'lower')
  QbTarget from(QbSource from);
}

// `MapperClass.method` tells apart two mappers declaring the same method.
@ShouldGenerate(
  r'''class QbClassMethodMapperImpl extends QbClassMethodMapper {
  QbClassMethodMapperImpl({
    required this.qbTagMapper,
    required this.qbOtherTagMapper,
  });

  final QbTagMapper qbTagMapper;

  final QbOtherTagMapper qbOtherTagMapper;

  @override
  QbTarget from(QbSource from) {
    return QbTarget(tag: qbOtherTagMapper.upper(from.label));
  }
}''',
  contains: true,
)
@Mapper(uses: {QbTagMapper, QbOtherTagMapper})
abstract class QbClassMethodMapper {
  @Mapping(
      source: 'label', target: 'tag', qualifiedBy: 'QbOtherTagMapper.upper')
  QbTarget from(QbSource from);
}

// On a dot-notation source.
class QbWrapper {
  final QbSource inner;

  const QbWrapper(this.inner);
}

@ShouldGenerate(
  r'''class QbDotSourceMapperImpl extends QbDotSourceMapper {
  QbDotSourceMapperImpl({required this.qbTagMapper});

  final QbTagMapper qbTagMapper;

  @override
  QbTarget from(QbWrapper from) {
    return QbTarget(tag: qbTagMapper.upper(from.inner.label));
  }
}''',
  contains: true,
)
@Mapper(uses: {QbTagMapper})
abstract class QbDotSourceMapper {
  @Mapping(source: 'inner.label', target: 'tag', qualifiedBy: 'upper')
  QbTarget from(QbWrapper from);
}

@ShouldGenerate(
  r'''class QbCommaMapperImpl extends QbCommaMapper {
  QbCommaMapperImpl({required this.qbTagMapper});

  final QbTagMapper qbTagMapper;

  @override
  QbPairTarget from(QbSource from) {
    return QbPairTarget(
      pair: qbTagMapper.joinReversed(from.orderField, from.orderDescending),
    );
  }
}''',
  contains: true,
)
@Mapper(uses: {QbTagMapper})
abstract class QbCommaMapper {
  @Mapping(
    source: 'orderField,orderDescending',
    target: 'pair',
    qualifiedBy: 'joinReversed',
  )
  QbPairTarget from(QbSource from);
}

@ShouldGenerate(
  r'''class QbCommaClassMethodMapperImpl extends QbCommaClassMethodMapper {
  QbCommaClassMethodMapperImpl({required this.qbTagMapper});

  final QbTagMapper qbTagMapper;

  @override
  QbPairTarget from(QbSource from) {
    return QbPairTarget(
      pair: qbTagMapper.join(from.orderField, from.orderDescending),
    );
  }
}''',
  contains: true,
)
@Mapper(uses: {QbTagMapper})
abstract class QbCommaClassMethodMapper {
  @Mapping(
    source: 'orderField,orderDescending',
    target: 'pair',
    qualifiedBy: 'QbTagMapper.join',
  )
  QbPairTarget from(QbSource from);
}

// A nullable source, a method accepting null: called as is.
@Mapper()
abstract class QbNullableTagMapper {
  QbTag fromNullable(String? value) => QbTag(value ?? '');
}

@ShouldGenerate(
  r'''class QbNullableSourceMapperImpl extends QbNullableSourceMapper {
  QbNullableSourceMapperImpl({required this.qbNullableTagMapper});

  final QbNullableTagMapper qbNullableTagMapper;

  @override
  QbTarget from(QbSource from) {
    return QbTarget(tag: qbNullableTagMapper.fromNullable(from.code));
  }
}''',
  contains: true,
)
@Mapper(uses: {QbNullableTagMapper})
abstract class QbNullableSourceMapper {
  @Mapping(source: 'code', target: 'tag', qualifiedBy: 'fromNullable')
  QbTarget from(QbSource from);
}

@ShouldThrow(
  "qualifiedBy 'missing' in @Mapping(target: 'tag') does not match any mapper method.\n"
  "Available methods: QbTagMapper.upper, QbTagMapper.lower, QbTagMapper.join, QbTagMapper.joinReversed.\n"
  "Fix: Use 'methodName' or 'MapperClass.methodName' of a method of the mapper or of a mapper listed in uses.",
)
@Mapper(uses: {QbTagMapper})
abstract class QbUnknownMethodMapper {
  @Mapping(source: 'label', target: 'tag', qualifiedBy: 'missing')
  QbTarget from(QbSource from);
}

// The signature is still checked.
@ShouldThrow(
  "No mapper method found for @Mapping(target: 'tag') with source (String from.label) returning QbTag.\n"
  "Rejected candidates:\n"
  "  - QbTagMapper.join(String? first, bool second): takes 2 parameter(s), 1 source(s) given\n"
  "Fix: Add a mapper method (in the mapper or in a mapper listed in uses) taking these parameters in this order and returning a value assignable to the target, or use callable.",
)
@Mapper(uses: {QbTagMapper})
abstract class QbWrongSignatureMapper {
  @Mapping(source: 'label', target: 'tag', qualifiedBy: 'join')
  QbTarget from(QbSource from);
}
