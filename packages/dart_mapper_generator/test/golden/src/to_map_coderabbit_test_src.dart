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

// Golden test source for the review findings of the class -> Map mapping.

import 'package:built_value/built_value.dart';
import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

// ----- 1. Inherit configuration: exact signature first -----

class CrDoc {
  final String name;
  final int age;

  const CrDoc({required this.name, required this.age});
}

@ShouldGenerate(r'''  @override
  CrDoc fromRealtime(Map<String, Object?> map) {
    return CrDoc(name: map['n'] as String, age: map['age'] as int);
  }''', contains: true)
@Mapper()
abstract class CrExactInheritMapper {
  @Mapping(target: 'full_name', source: 'name')
  Map<String, dynamic> toFirestore(CrDoc dto);

  @Mapping(target: 'n', source: 'name')
  Map<String, Object?> toRealtime(CrDoc dto);

  @InheritInverseConfiguration()
  CrDoc fromRealtime(Map<String, Object?> map);
}

// ----- 2. Generic arguments keep their nullability -----

class CrBox<T> {
  final T value;

  const CrBox({required this.value});
}

class CrBoxes {
  final CrBox<String> plain;
  final CrBox<String?> maybe;

  const CrBoxes({required this.plain, required this.maybe});
}

@ShouldGenerate(r'''    return {
      'plain': _mapCrBoxOfStringToMap(dto.plain),
      'maybe': _mapCrBoxOfNullableStringToMap(dto.maybe),
    };
  }

  Map<String, dynamic> _mapCrBoxOfStringToMap(CrBox<String> crBoxString) {
    return {'value': crBoxString.value};
  }

  Map<String, dynamic> _mapCrBoxOfNullableStringToMap(
    CrBox<String?> crBoxString,
  ) {
    return {'value': crBoxString.value};
  }''', contains: true)
@Mapper()
abstract class CrBoxesMapper {
  Map<String, dynamic> toMap(CrBoxes dto);
}

// ----- 3. Not readable constructor parameter -----

class CrSecret {
  final String name;

  CrSecret({required this.name, required String secret});
}

@ShouldGenerate(r'''return {'name': dto.name};''', contains: true)
@Mapper()
abstract class CrSecretIgnoredMapper {
  @Mapping(target: 'secret', ignore: true)
  Map<String, dynamic> toMap(CrSecret dto);
}

@ShouldGenerate(r'''return {'name': dto.name, 'secret': 'hidden'};''',
    contains: true)
@Mapper()
abstract class CrSecretConstantMapper {
  @Mapping(target: 'secret', constant: "'hidden'")
  Map<String, dynamic> toMap(CrSecret dto);
}

// ----- 6. Built value detection -----

class CrNotBuilt extends BuiltValueNullFieldError {
  final String title;

  CrNotBuilt(this.title) : super('a', 'b');
}

@ShouldGenerate(r'''return {'title': dto.title};''', contains: true)
@Mapper()
abstract class CrNotBuiltMapper {
  Map<String, dynamic> toMap(CrNotBuilt dto);
}
