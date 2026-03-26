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

// Golden test source for import alias edge cases (QA-05).
//
// Validates that the generator correctly handles aliased import types
// in mapper parameters and return types. Mirrors the pattern from
// example/lib/alias/ where types are imported with a prefix.

import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

import 'alias_models.dart' as models;

// Local types (non-aliased counterparts)
enum AliasEnum {
  element,
}

class AliasObject {
  final String name;
  final AliasEnum alias;

  const AliasObject(this.name, this.alias);
}

@ShouldGenerate(
  r'''class AliasMapperImpl extends AliasMapper''',
  contains: true,
)
@ShouldGenerate(
  r'''models.AliasObject reverseMap(AliasObject target)''',
  contains: true,
)
@ShouldGenerate(
  r'''AliasEnum mapEnum(models.AliasEnum source)''',
  contains: true,
)
@ShouldGenerate(
  r'''models.AliasEnum reverseMapEnum(AliasEnum target)''',
  contains: true,
)
@Mapper()
abstract class AliasMapper {
  @Mapping(target: 'name', source: 'description')
  AliasObject map(models.AliasObject source);

  AliasEnum mapEnum(models.AliasEnum source);

  @InheritInverseConfiguration()
  models.AliasObject reverseMap(AliasObject target);

  @InheritInverseConfiguration()
  models.AliasEnum reverseMapEnum(AliasEnum target);
}
