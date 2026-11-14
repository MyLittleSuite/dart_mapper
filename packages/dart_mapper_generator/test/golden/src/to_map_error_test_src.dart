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

// Golden test source for the compile-time errors of class -> Map mapping
// (MappingBehavior.toMap).

import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

enum ErrorKind { first, second }

class ErrorAddress {
  final String street;
  final String city;

  const ErrorAddress({required this.street, required this.city});
}

class ErrorUser {
  final String id;
  final String? nickname;
  final double score;
  final DateTime createdAt;
  final ErrorKind kind;

  const ErrorUser({
    required this.id,
    this.nickname,
    required this.score,
    required this.createdAt,
    required this.kind,
  });
}

class ErrorOther {
  final String id;

  const ErrorOther({required this.id});
}

// A Map -> Map method is not supported.
@ShouldThrow(
    "Method 'toMap' maps a Map to a Map, which is not supported.\n"
    "Fix: Implement the conversion by hand and reference it with 'callable' in @Mapping, or map through a class (Map -> class -> Map).",
)
@Mapper()
abstract class MapToMapMapper {
  Map<String, dynamic> toMap(Map<String, dynamic> source);
}

// The source parameter of a class -> Map method must be a class.
@ShouldThrow(
    "Parameter 'source' of type 'String' in method 'toMap' cannot be mapped to a Map<String, ...>.\n"
    "Fix: Use a class as source parameter when the method returns a Map<String, ...>.",
)
@Mapper()
abstract class StringSourceMapper {
  Map<String, dynamic> toMap(String source);
}

// Typed values: the double score is not a String.
@ShouldThrow(
    "Field 'nickname' of type 'String?' is not compatible with the value type 'String' of 'Map<String, String>'.\n"
    "Fix: Change the map value type (for instance to Object? or dynamic), provide a converter method, use a 'callable', or ignore the field with @Mapping(target: 'nickname', ignore: true).",
)
@Mapper()
abstract class IncompatibleValueMapper {
  Map<String, String> toMap(ErrorUser user);
}

// Typed values: the double score is not a String either.
@ShouldThrow(
    "Field 'score' of type 'double' is not compatible with the value type 'String' of 'Map<String, String>'.\n"
    "Fix: Change the map value type (for instance to Object? or dynamic), provide a converter method, use a 'callable', or ignore the field with @Mapping(target: 'score', ignore: true).",
)
@Mapper()
abstract class IncompatibleTypeMapper {
  @Mapping(target: 'nickname', ignore: true)
  Map<String, String> toMap(ErrorUser user);
}

// Typed values: a nullable field cannot be stored in a non-null value.
@ShouldThrow(
    "Field 'nickname' of type 'String?' is not compatible with the value type 'Object' of 'Map<String, Object>'.\n"
    "Fix: Change the map value type (for instance to Object? or dynamic), provide a converter method, use a 'callable', or ignore the field with @Mapping(target: 'nickname', ignore: true).",
)
@Mapper()
abstract class NullableToNonNullValueMapper {
  @Mapping(target: 'score', ignore: true)
  @Mapping(target: 'createdAt', ignore: true)
  @Mapping(target: 'kind', ignore: true)
  Map<String, Object> toMap(ErrorUser user);
}

// A whole key and one of its sub-keys cannot be both mapped.
@ShouldThrow(
    "Invalid @Mapping target 'address.nickname': 'address' is already mapped as a whole value.\n"
    "Fix: A map key cannot be mapped both as a whole value and as a container of nested keys, and every segment of a dotted target must be non-empty.",
)
@Mapper()
abstract class KeyAndSubKeyMapper {
  @Mapping(source: 'id', target: 'address')
  @Mapping(source: 'nickname', target: 'address.nickname')
  Map<String, dynamic> toMap(ErrorUser user);
}

// Every segment of a dotted target must be non-empty.
@ShouldThrow(
    "Invalid @Mapping target 'address..id': it contains an empty segment.\n"
    "Fix: A map key cannot be mapped both as a whole value and as a container of nested keys, and every segment of a dotted target must be non-empty.",
)
@Mapper()
abstract class EmptySegmentMapper {
  @Mapping(source: 'id', target: 'address..id')
  Map<String, dynamic> toMap(ErrorUser user);
}

// More than one converter for the same type.
@ShouldThrow(
    "Ambiguous mapping for type 'DateTime': multiple methods are candidates (this.toMillis, this.toIso).\n"
    "Fix: Keep a single candidate per type, or select the one to use with @Mapping(target: '...', qualifiedBy: 'methodName') or @Mapping(target: '...', callable: yourFunction).",
)
@Mapper()
abstract class AmbiguousConverterMapper {
  Map<String, dynamic> toMap(ErrorUser user);

  int toMillis(DateTime date) => date.millisecondsSinceEpoch;

  String toIso(DateTime date) => date.toIso8601String();
}

// The same field in multiple source parameters needs a qualified source.
@ShouldThrow(
    "Ambiguous source field 'id' found in multiple parameters: user, other.\n"
    "When multiple source parameters share a field name, you must qualify the source explicitly.\n"
    "Fix: Add @Mapping(target: 'id', source: 'user.id') to specify which parameter to use.",
)
@Mapper()
abstract class AmbiguousSourceMapper {
  Map<String, dynamic> toMap(ErrorUser user, ErrorOther other);
}

// conditionExpression needs a nullable value type or a defaultValue.
@ShouldThrow(
    "conditionExpression on non-nullable map value 'id': requires a defaultValue or a nullable map value type.\n"
    "Fix: Add defaultValue: '...' to the @Mapping annotation, or make the map value type nullable.",
)
@Mapper()
abstract class ConditionNonNullValueMapper {
  @Mapping(target: 'id', conditionExpression: 'user.id.isNotEmpty')
  @Mapping(target: 'nickname', ignore: true)
  @Mapping(target: 'score', ignore: true)
  @Mapping(target: 'createdAt', ignore: true)
  @Mapping(target: 'kind', ignore: true)
  Map<String, Object> toMap(ErrorUser user);
}

// A self-referencing class needs a declared method.
class ErrorNode {
  final String name;
  final ErrorNode? parent;

  const ErrorNode({required this.name, this.parent});
}

class ErrorWrapper {
  final ErrorNode node;

  const ErrorWrapper({required this.node});
}

@ShouldThrow(
    "Type 'ErrorNode' references itself and cannot be converted to a nested map automatically.\n"
    "Fix: Declare a method 'Map<String, dynamic> toMap(ErrorNode value)' in the mapper (or in a mapper listed in 'uses') to handle it.",
)
@Mapper()
abstract class RecursiveMapper {
  Map<String, dynamic> toMap(ErrorWrapper wrapper);
}

// The source property does not exist.
@ShouldThrow(
    "Property 'missing' not found on type 'ErrorUser' while resolving dot notation path.\n"
    "Available properties: id, nickname, score, createdAt, kind.\n"
    "Fix: Check the dot notation path for typos.",
)
@Mapper()
abstract class UnknownSourceMapper {
  @Mapping(source: 'missing.value', target: 'value')
  Map<String, dynamic> toMap(ErrorUser user);
}

// The callable returns a value the typed map cannot hold.
int toInt(String value) => value.length;

@ShouldThrow(
    "Field 'id' of type 'int' is not compatible with the value type 'String' of 'Map<String, String>'.\n"
    "Fix: Change the map value type (for instance to Object? or dynamic), provide a converter method, use a 'callable', or ignore the field with @Mapping(target: 'id', ignore: true).",
)
@Mapper()
abstract class IncompatibleCallableMapper {
  @Mapping(target: 'id', callable: toInt)
  @Mapping(target: 'nickname', ignore: true)
  @Mapping(target: 'score', ignore: true)
  @Mapping(target: 'createdAt', ignore: true)
  @Mapping(target: 'kind', ignore: true)
  Map<String, String> toMap(ErrorUser user);
}
