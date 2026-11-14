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

// Golden test source for comma-separated sources resolved through mapper
// methods (`uses` first, then the mapper's own methods).

import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

enum MsOrderField { name, date }

class MsOrdering {
  final MsOrderField field;
  final bool descending;

  const MsOrdering({required this.field, required this.descending});
}

class MsSettingsDTO {
  final String? orderField;
  final bool orderDescending;
  final String title;

  const MsSettingsDTO({
    required this.orderField,
    required this.orderDescending,
    required this.title,
  });
}

class MsSettings {
  final MsOrdering ordering;
  final String title;

  const MsSettings({required this.ordering, required this.title});
}

@ShouldGenerate(
  r'''class MsOrderFieldMapperImpl extends MsOrderFieldMapper {
  MsOrderFieldMapperImpl();

  @override
  MsOrderField from([String? value]) {
    return switch (value) {
      null => MsOrderField.name,
      '<NULL>' => MsOrderField.name,
      'date' => MsOrderField.date,
      // ignore:unreachable_switch_case
      _ => MsOrderField.name,
    };
  }

  @override
  String to(MsOrderField field) {
    return switch (field) {
      MsOrderField.name => 'name',
      MsOrderField.date => 'date',
      // ignore:unreachable_switch_case
      _ => throw ArgumentError('Unknown value for enum String: {$field}'),
    };
  }
}''',
  contains: true,
)
@Mapper()
abstract class MsOrderFieldMapper {
  @ValueMapping(source: ValueMapping.nullValue, target: 'name')
  @ValueMapping(source: ValueMapping.anyRemaining, target: 'name')
  MsOrderField from(String? value);

  String to(MsOrderField field);
}

// The parameters bind to the constructor parameters named like them; `field`
// goes through the enum mapper.
@ShouldGenerate(
  r'''class MsOrderingMapperImpl extends MsOrderingMapper {
  MsOrderingMapperImpl({required this.msOrderFieldMapper});

  final MsOrderFieldMapper msOrderFieldMapper;

  @override
  MsOrdering from(String? field, bool descending) {
    return MsOrdering(
      field: msOrderFieldMapper.from(field),
      descending: descending,
    );
  }
}''',
  contains: true,
)
@Mapper(uses: {MsOrderFieldMapper})
abstract class MsOrderingMapper {
  MsOrdering from(String? field, bool descending);
}

@ShouldGenerate(
  r'''class MsSettingsMapperImpl extends MsSettingsMapper {
  MsSettingsMapperImpl({required this.msOrderingMapper});

  final MsOrderingMapper msOrderingMapper;

  @override
  MsSettings from(MsSettingsDTO from) {
    return MsSettings(
      ordering: msOrderingMapper.from(from.orderField, from.orderDescending),
      title: from.title,
    );
  }
}''',
  contains: true,
)
@Mapper(uses: {MsOrderingMapper})
abstract class MsSettingsMapper {
  @Mapping(source: 'orderField,orderDescending', target: 'ordering')
  MsSettings from(MsSettingsDTO from);
}

// `uses` mappers are searched first: the own method is a candidate only when
// no used mapper matches.
@ShouldGenerate(
  r'''class MsUsesFirstSettingsMapperImpl extends MsUsesFirstSettingsMapper {
  MsUsesFirstSettingsMapperImpl({required this.msOrderingMapper});

  final MsOrderingMapper msOrderingMapper;

  @override
  MsSettings from(MsSettingsDTO from) {
    return MsSettings(
      ordering: msOrderingMapper.from(from.orderField, from.orderDescending),
      title: from.title,
    );
  }
}''',
  contains: true,
)
@Mapper(uses: {MsOrderingMapper})
abstract class MsUsesFirstSettingsMapper {
  @Mapping(source: 'orderField,orderDescending', target: 'ordering')
  MsSettings from(MsSettingsDTO from);

  MsOrdering ordering(String? field, bool descending) =>
      MsOrdering(field: MsOrderField.date, descending: descending);
}

// Without a used mapper, the mapper's own method is called.
@ShouldGenerate(
  r'''class MsOwnMethodSettingsMapperImpl extends MsOwnMethodSettingsMapper {
  MsOwnMethodSettingsMapperImpl();

  @override
  MsSettings from(MsSettingsDTO from) {
    return MsSettings(
      ordering: ordering(from.orderField, from.orderDescending),
      title: from.title,
    );
  }
}''',
  contains: true,
)
@Mapper()
abstract class MsOwnMethodSettingsMapper {
  @Mapping(source: 'orderField,orderDescending', target: 'ordering')
  MsSettings from(MsSettingsDTO from);

  MsOrdering ordering(String? field, bool descending) => MsOrdering(
        field: MsOrderField.values.asNameMap()[field] ?? MsOrderField.name,
        descending: descending,
      );
}

// A source of a multi-source method written as `param.field`, next to a bare
// parameter name.
class MsLeft {
  final String? orderField;

  const MsLeft(this.orderField);
}

class MsRight {
  final bool orderDescending;

  const MsRight(this.orderDescending);
}

@ShouldGenerate(
  r'''class MsParamFieldPartsMapperImpl extends MsParamFieldPartsMapper {
  MsParamFieldPartsMapperImpl({required this.msOrderingMapper});

  final MsOrderingMapper msOrderingMapper;

  @override
  MsSettings from(MsLeft left, MsRight right, String title) {
    return MsSettings(
      ordering: msOrderingMapper.from(left.orderField, right.orderDescending),
      title: title,
    );
  }
}''',
  contains: true,
)
@Mapper(uses: {MsOrderingMapper})
abstract class MsParamFieldPartsMapper {
  @Mapping(source: 'left.orderField,right.orderDescending', target: 'ordering')
  @Mapping(source: 'title', target: 'title')
  MsSettings from(MsLeft left, MsRight right, String title);
}

// Source dot notation: each part resolved as usual; a nullable link makes the
// argument nullable, accepted by a nullable parameter.
class MsDeepSource {
  final MsLeft? left;
  final MsRight right;
  final String title;

  const MsDeepSource(this.left, this.right, this.title);
}

@ShouldGenerate(
  r'''class MsDotPartsMapperImpl extends MsDotPartsMapper {
  MsDotPartsMapperImpl({required this.msOrderingMapper});

  final MsOrderingMapper msOrderingMapper;

  @override
  MsSettings from(MsDeepSource from) {
    return MsSettings(
      ordering: msOrderingMapper.from(
        from.left?.orderField,
        from.right.orderDescending,
      ),
      title: from.title,
    );
  }
}''',
  contains: true,
)
@Mapper(uses: {MsOrderingMapper})
abstract class MsDotPartsMapper {
  @Mapping(
    source: 'left.orderField,right.orderDescending',
    target: 'ordering',
  )
  MsSettings from(MsDeepSource from);
}

// A nullable link into a non-nullable parameter fails and names the argument.
@Mapper()
abstract class MsStrictOrderingConverter {
  MsOrdering from(String field, bool descending) =>
      MsOrdering(field: MsOrderField.name, descending: descending);
}

@ShouldThrow(
  "No mapper method found for @Mapping(target: 'ordering') with source (String? from.left?.orderField, bool from.right.orderDescending) returning MsOrdering.\n"
  "Rejected candidates:\n"
  "  - MsStrictOrderingConverter.from(String field, bool descending): argument 1 (`from.left?.orderField`) may be null (String?) but parameter 1 is String\n"
  "Fix: Add a mapper method (in the mapper or in a mapper listed in uses) taking these parameters in this order and returning a value assignable to the target, or use callable.",
)
@Mapper(uses: {MsStrictOrderingConverter})
abstract class MsNullableChainMapper {
  @Mapping(source: 'left.orderField,right.orderDescending', target: 'ordering')
  MsSettings from(MsDeepSource from);
}

// Nested (dotted) target built by the call, `defaultValue` after the call and
// `conditionExpression` around it.
class MsOrderingHolder {
  final MsOrdering? ordering;

  const MsOrderingHolder(this.ordering);
}

class MsNestedSettings {
  final MsOrderingHolder holder;

  const MsNestedSettings({required this.holder});
}

@ShouldGenerate(
  r'''class MsNestedTargetMapperImpl extends MsNestedTargetMapper {
  MsNestedTargetMapperImpl({required this.msOrderingMapper});

  final MsOrderingMapper msOrderingMapper;

  @override
  MsNestedSettings from(MsSettingsDTO from) {
    return MsNestedSettings(
      holder: MsOrderingHolder(
        msOrderingMapper.from(from.orderField, from.orderDescending),
      ),
    );
  }
}''',
  contains: true,
)
@Mapper(uses: {MsOrderingMapper})
abstract class MsNestedTargetMapper {
  @Mapping(source: 'orderField,orderDescending', target: 'holder.ordering')
  MsNestedSettings from(MsSettingsDTO from);
}

class MsOptionalSettings {
  final MsOrdering? ordering;

  const MsOptionalSettings({this.ordering});
}

@ShouldGenerate(
  r'''class MsConditionSettingsMapperImpl extends MsConditionSettingsMapper {
  MsConditionSettingsMapperImpl({required this.msOrderingMapper});

  final MsOrderingMapper msOrderingMapper;

  @override
  MsOptionalSettings from(MsSettingsDTO from) {
    return MsOptionalSettings(
      ordering: from.orderDescending
          ? msOrderingMapper.from(from.orderField, from.orderDescending)
          : null,
    );
  }
}''',
  contains: true,
)
@Mapper(uses: {MsOrderingMapper})
abstract class MsConditionSettingsMapper {
  @Mapping(
    source: 'orderField,orderDescending',
    target: 'ordering',
    conditionExpression: 'from.orderDescending',
  )
  MsOptionalSettings from(MsSettingsDTO from);
}

@ShouldGenerate(
  r'''class MsDefaultValueSettingsMapperImpl extends MsDefaultValueSettingsMapper {
  MsDefaultValueSettingsMapperImpl({required this.msOrderingMapper});

  final MsOrderingMapper msOrderingMapper;

  @override
  MsOptionalSettings from(MsSettingsDTO from) {
    return MsOptionalSettings(
      ordering:
          msOrderingMapper.from(from.orderField, from.orderDescending) ??
          const MsOrdering(field: MsOrderField.name, descending: false),
    );
  }
}''',
  contains: true,
)
@Mapper(uses: {MsOrderingMapper})
abstract class MsDefaultValueSettingsMapper {
  @Mapping(
    source: 'orderField,orderDescending',
    target: 'ordering',
    defaultValue:
        'const MsOrdering(field: MsOrderField.name, descending: false)',
  )
  MsOptionalSettings from(MsSettingsDTO from);
}

// More than one match: the build fails and suggests qualifiedBy.
@Mapper()
abstract class MsAmbiguousOrderings {
  MsOrdering first(String? field, bool descending) =>
      MsOrdering(field: MsOrderField.name, descending: descending);

  MsOrdering second(String? field, bool descending) =>
      MsOrdering(field: MsOrderField.date, descending: descending);
}

@ShouldThrow(
  "Ambiguous mapper method for @Mapping(target: 'ordering'): multiple methods match (MsAmbiguousOrderings.first(String? field, bool descending), MsAmbiguousOrderings.second(String? field, bool descending)).\n"
  "Fix: Select the one to use with @Mapping(target: 'ordering', qualifiedBy: 'methodName') or qualifiedBy: 'MapperClass.methodName'.",
)
@Mapper(uses: {MsAmbiguousOrderings})
abstract class MsAmbiguousMapper {
  @Mapping(source: 'orderField,orderDescending', target: 'ordering')
  MsSettings from(MsSettingsDTO from);
}

// No candidate fits: the build lists the rejected ones with the reason.
@Mapper()
abstract class MsEnumOrderingConverter {
  MsOrdering from(MsOrderField field, bool descending) =>
      MsOrdering(field: field, descending: descending);

  MsOrdering fromName(String field) =>
      MsOrdering(field: MsOrderField.name, descending: false);
}

@ShouldThrow(
  "No mapper method found for @Mapping(target: 'ordering') with source (String? from.orderField, bool from.orderDescending) returning MsOrdering.\n"
  "Rejected candidates:\n"
  "  - MsEnumOrderingConverter.from(MsOrderField field, bool descending): argument 1 (`from.orderField`) is String?, not assignable to parameter 1 (MsOrderField)\n"
  "  - MsEnumOrderingConverter.fromName(String field): takes 1 parameter(s), 2 source(s) given\n"
  "Fix: Add a mapper method (in the mapper or in a mapper listed in uses) taking these parameters in this order and returning a value assignable to the target, or use callable.",
)
@Mapper(uses: {MsEnumOrderingConverter})
abstract class MsNoMatchMapper {
  @Mapping(source: 'orderField,orderDescending', target: 'ordering')
  MsSettings from(MsSettingsDTO from);
}
