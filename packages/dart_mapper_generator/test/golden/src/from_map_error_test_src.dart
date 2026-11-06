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

// Golden test source for the Map -> class mapping errors.

import 'package:built_value/built_value.dart';
import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

class FmPrimitiveSimple {
  final String name;
  final int count;
  final double ratio;

  const FmPrimitiveSimple({
    required this.name,
    required this.count,
    required this.ratio,
  });
}

class FmHolderNullableSource {
  final int id;
  final int? other;

  const FmHolderNullableSource({required this.id, this.other});
}

class FmStamped {
  final String name;
  final DateTime at;
  final DateTime? maybeAt;
  final List<DateTime> history;

  const FmStamped({
    required this.name,
    required this.at,
    this.maybeAt,
    required this.history,
  });
}

class FmAmbiguousConverters {
  const FmAmbiguousConverters();

  DateTime fromMillis(int milliseconds) =>
      DateTime.fromMillisecondsSinceEpoch(milliseconds);

  DateTime fromIso(String iso) => DateTime.parse(iso);
}

class FmPerson {
  final String name;
  final FmAddress address;

  const FmPerson({required this.name, required this.address});
}

class FmAddress {
  final String street;
  final String? city;

  const FmAddress({required this.street, this.city});
}

sealed class FmShape {
  const FmShape();
}

class FmCircle extends FmShape {
  const FmCircle();
}

abstract class FmAbstractThing {
  String get name;
}

abstract class FmBuiltDeckAbstract
    implements Built<FmBuiltDeckAbstract, FmBuiltDeckAbstractBuilder> {
  String get id;

  FmBuiltDeckAbstract._();

  factory FmBuiltDeckAbstract(
          [void Function(FmBuiltDeckAbstractBuilder) updates]) =
      _$FmBuiltDeckAbstract;
}

abstract class FmBuiltDeckAbstractBuilder
    implements Builder<FmBuiltDeckAbstract, FmBuiltDeckAbstractBuilder> {
  String? id;

  FmBuiltDeckAbstractBuilder._();

  factory FmBuiltDeckAbstractBuilder() = _$FmBuiltDeckAbstractBuilder;
}

class _$FmBuiltDeckAbstract extends FmBuiltDeckAbstract {
  @override
  String get id => throw UnimplementedError();

  _$FmBuiltDeckAbstract([void Function(FmBuiltDeckAbstractBuilder)? updates]) : super._();

  @override
  FmBuiltDeckAbstract rebuild(void Function(FmBuiltDeckAbstractBuilder) updates) =>
      throw UnimplementedError();

  @override
  FmBuiltDeckAbstractBuilder toBuilder() => throw UnimplementedError();
}

class _$FmBuiltDeckAbstractBuilder extends FmBuiltDeckAbstractBuilder {
  _$FmBuiltDeckAbstractBuilder() : super._();

  @override
  void replace(FmBuiltDeckAbstract other) {}

  @override
  void update(void Function(FmBuiltDeckAbstractBuilder)? updates) {}

  @override
  FmBuiltDeckAbstract build() => throw UnimplementedError();
}


@ShouldThrow(
  "No relation found for required field 'name' in 'FmObjectParamMapper.fromObject'.\n"
  "Fix: Add @Mapping(target: 'name', source: 'sourceField') to map from a differently named source field, or @Mapping(target: 'name', ignore: true) to skip it.",
)
@Mapper()
abstract class FmObjectParamMapper {
  // An Object parameter is not a map source: standard mapping is used.
  FmPrimitiveSimple fromObject(Object source);
}

@ShouldThrow(
  "Field 'count' of type 'int' is not compatible with the map value type 'String'.\n"
  "Fix: Declare the source map as Map<String, dynamic> (or Map<String, Object?>), declare a converter method from 'String' to 'int', or use callable.",
)
@Mapper()
abstract class FmTypedIncompatibleMapper {
  FmPrimitiveSimple fromStrings(Map<String, String> map);
}

@ShouldThrow(
  "Target field 'id' of 'FmHolderNullableSource' in 'FmTypedNullableMapper.fromNullable' requires a non-nullable source, but the source field is nullable.\n"
  "Fix: Add @Mapping(target: 'id', forceNonNull: true) to force-unwrap the nullable source field, or make the source field non-nullable.",
)
@Mapper()
abstract class FmTypedNullableMapper {
  FmHolderNullableSource fromNullable(Map<String, int?> map);
}

@ShouldThrow(
  "Ambiguous mapping for type 'DateTime': multiple methods are candidates (fmAmbiguousConverters.fromMillis, fmAmbiguousConverters.fromIso).\n"
  "Fix: Keep a single candidate per type, or select the one to use with @Mapping(callable: ...).",
)
@Mapper(uses: {FmAmbiguousConverters})
abstract class FmAmbiguousConverterMapper {
  FmStamped fromMap(Map<String, dynamic> map);
}

@ShouldThrow(
  "Target dot notation 'address.street' is not supported when mapping a Map to a class (tracked in issue #118).\n"
  "Fix: Map the key to a flat target field, or use callable to build the value yourself.",
)
@Mapper()
abstract class FmTargetDotNotationMapper {
  @Mapping(source: 'street', target: 'address.street')
  FmPerson fromMap(Map<String, dynamic> map);
}

@ShouldThrow(
  "Cannot map a Map to 'FmShape': the class is sealed and cannot be instantiated.\n"
  "Mapping to sealed classes or to classes selected by a discriminator key is not supported yet (tracked in issue #119).\n"
  "Fix: Map to a concrete class.",
)
@Mapper()
abstract class FmSealedTargetMapper {
  FmShape fromMap(Map<String, dynamic> map);
}

@ShouldThrow(
  "Cannot map a Map to 'FmAbstractThing': the class is abstract and cannot be instantiated.\n"
  "Mapping to sealed classes or to classes selected by a discriminator key is not supported yet (tracked in issue #119).\n"
  "Fix: Map to a concrete class.",
)
@Mapper()
abstract class FmAbstractTargetMapper {
  FmAbstractThing fromMap(Map<String, dynamic> map);
}

@ShouldThrow(
  "Target field 'id' is non-nullable but the map value for 'id' is nullable.\n"
  "Fix: Add forceNonNull: true or provide a defaultValue to handle the null case.",
)
@Mapper()
abstract class FmBuiltNullableMapper {
  FmBuiltDeckAbstract fromMap(Map<String, String?> map);
}
