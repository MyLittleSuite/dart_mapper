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

// Golden test source for method parameters used as sources: a parameter binds
// to the target property named like it, and can be named in `source`.
// Precedence: explicit @Mapping > getter of a source parameter > parameter name.

import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

enum PsKind { alpha, beta }

class PsCreate {
  final String name;

  const PsCreate(this.name);
}

class PsEntity {
  final String id;
  final String name;

  const PsEntity({required this.id, required this.name});
}

// The parameter `id` feeds the property `id` without an expression.
@ShouldGenerate(
  r'''class PsFromCreateMapperImpl extends PsFromCreateMapper {
  PsFromCreateMapperImpl();

  @override
  PsEntity fromCreate(PsCreate from, String id) {
    return PsEntity(id: id, name: from.name);
  }
}''',
  contains: true,
)
@Mapper()
abstract class PsFromCreateMapper {
  PsEntity fromCreate(PsCreate from, String id);
}

// A getter of a source parameter wins over a parameter named like it.
@ShouldGenerate(
  r'''class PsGetterWinsMapperImpl extends PsGetterWinsMapper {
  PsGetterWinsMapperImpl();

  @override
  PsEntity fromCreate(PsEntity from, String name, String id) {
    return PsEntity(id: from.id, name: from.name);
  }
}''',
  contains: true,
)
@Mapper()
abstract class PsGetterWinsMapper {
  PsEntity fromCreate(PsEntity from, String name, String id);
}

// An explicit @Mapping wins over the parameter named like the target.
@ShouldGenerate(
  r'''class PsExplicitWinsMapperImpl extends PsExplicitWinsMapper {
  PsExplicitWinsMapperImpl();

  @override
  PsEntity fromCreate(PsCreate from, String id) {
    return PsEntity(id: 'fixed', name: from.name);
  }
}''',
  contains: true,
)
@Mapper()
abstract class PsExplicitWinsMapper {
  @Mapping(target: 'id', constant: 'fixed')
  PsEntity fromCreate(PsCreate from, String id);
}

// A parameter can be named explicitly in `source`.
@ShouldGenerate(
  r'''class PsExplicitSourceMapperImpl extends PsExplicitSourceMapper {
  PsExplicitSourceMapperImpl();

  @override
  PsEntity fromCreate(PsCreate from, String rawId) {
    return PsEntity(id: rawId, name: from.name);
  }
}''',
  contains: true,
)
@Mapper()
abstract class PsExplicitSourceMapper {
  @Mapping(source: 'rawId', target: 'id')
  PsEntity fromCreate(PsCreate from, String rawId);
}

@Mapper()
abstract class PsKindMapper {
  PsKind from(String? value) =>
      PsKind.values.asNameMap()[value] ?? PsKind.alpha;
}

class PsFilter {
  final PsKind kind;

  const PsFilter({required this.kind});
}

// A single primitive parameter targets a class; `String?` goes through the
// enum mapper of `uses`.
@ShouldGenerate(
  r'''class PsSingleParameterMapperImpl extends PsSingleParameterMapper {
  PsSingleParameterMapperImpl({required this.psKindMapper});

  final PsKindMapper psKindMapper;

  @override
  PsFilter from([String? kind]) {
    return PsFilter(kind: psKindMapper.from(kind));
  }
}''',
  contains: true,
)
@Mapper(uses: {PsKindMapper})
abstract class PsSingleParameterMapper {
  PsFilter from(String? kind);
}

// A parameter named as a part of a comma-separated source.
class PsRow {
  final String? kind;

  const PsRow(this.kind);
}

class PsKindFlag {
  final PsKind kind;
  final bool descending;

  const PsKindFlag(this.kind, this.descending);
}

class PsHolder {
  final PsKindFlag flag;

  const PsHolder({required this.flag});
}

@Mapper()
abstract class PsFlagMapper {
  PsKindFlag from(String? kind, bool descending) =>
      PsKindFlag(PsKind.alpha, descending);
}

@ShouldGenerate(
  r'''class PsCommaParameterMapperImpl extends PsCommaParameterMapper {
  PsCommaParameterMapperImpl({required this.psFlagMapper});

  final PsFlagMapper psFlagMapper;

  @override
  PsHolder from(PsRow from, bool descending) {
    return PsHolder(flag: psFlagMapper.from(from.kind, descending));
  }
}''',
  contains: true,
)
@Mapper(uses: {PsFlagMapper})
abstract class PsCommaParameterMapper {
  @Mapping(source: 'kind,descending', target: 'flag')
  PsHolder from(PsRow from, bool descending);
}

// A bare `source` naming both a parameter and a getter of a parameter is
// ambiguous.
@ShouldThrow(
  "Ambiguous source field 'name' found in multiple parameters: from, name.\n"
  "When multiple source parameters share a field name, you must qualify the source explicitly.\n"
  "Fix: Add @Mapping(target: 'name', source: 'from.name') to specify which parameter to use.",
)
@Mapper()
abstract class PsAmbiguousNameMapper {
  @Mapping(source: 'name', target: 'id')
  PsEntity from(PsCreate from, String name);
}
