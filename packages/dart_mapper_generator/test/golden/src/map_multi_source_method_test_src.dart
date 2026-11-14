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

// Golden test source for comma-separated sources resolved by a mapper method
// (no `callable`) and for `qualifiedBy` on single sources, in Map -> class
// and class -> Map mappings.

import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

// ----- Shared models -----

enum MmField { name, date }

class MmOrdering {
  final MmField? field;
  final bool descending;

  const MmOrdering({this.field, required this.descending});
}

class MmSettings {
  final String title;
  final MmOrdering ordering;

  const MmSettings({required this.title, required this.ordering});
}

class MmMeta {
  final String? field;

  const MmMeta({this.field});
}

class MmRange {
  final String? from;
  final String? to;

  const MmRange({this.from, this.to});
}

class MmRanged {
  final MmRange range;

  const MmRanged({required this.range});
}

class MmNestedOrdering {
  final String label;

  const MmNestedOrdering({required this.label});
}

class MmNested {
  final String title;
  final MmNestedOrdering ordering;

  const MmNested({required this.title, required this.ordering});
}

class MmStamped {
  final String name;
  final DateTime at;

  const MmStamped({required this.name, required this.at});
}

class MmStampedDto {
  final String name;
  final DateTime at;

  const MmStampedDto({required this.name, required this.at});
}

class MmSettingsDto {
  final String title;
  final String? orderField;
  final bool orderDescending;

  const MmSettingsDto({
    required this.title,
    this.orderField,
    required this.orderDescending,
  });
}

// ----- Mappers used through `uses` -----

class MmOrderingConverter {
  const MmOrderingConverter();

  MmOrdering from(String? field, bool descending) => MmOrdering(
        field: field == null ? null : MmField.values.byName(field),
        descending: descending,
      );
}

class MmLabelConverter {
  const MmLabelConverter();

  String label(String? field, bool descending) =>
      '${field ?? 'none'} ${descending ? 'desc' : 'asc'}';
}

class MmStrictConverter {
  const MmStrictConverter();

  MmOrdering of(String field, bool descending) => MmOrdering(
        field: MmField.values.byName(field),
        descending: descending,
      );
}

class MmRangeConverter {
  const MmRangeConverter();

  MmRange of(String? from, String? to) => MmRange(from: from, to: to);
}

class MmAmbiguousConverters {
  const MmAmbiguousConverters();

  DateTime fromMillis(int milliseconds) =>
      DateTime.fromMillisecondsSinceEpoch(milliseconds);

  DateTime fromIso(String iso) => DateTime.parse(iso);

  String toMillis(DateTime date) => '${date.millisecondsSinceEpoch}';

  String toIso(DateTime date) => date.toIso8601String();
}

class MmDuplicatedConverters {
  const MmDuplicatedConverters();

  MmOrdering first(String? field, bool descending) =>
      MmOrdering(descending: descending);

  MmOrdering second(String? field, bool descending) =>
      MmOrdering(descending: !descending);
}

// ----- Map -> class -----

@ShouldGenerate(
  r'''class MmFromMapUntypedMapperImpl extends MmFromMapUntypedMapper {
  MmFromMapUntypedMapperImpl({required this.mmOrderingConverter});

  final MmOrderingConverter mmOrderingConverter;

  @override
  MmSettings fromMap(Map<String, dynamic> map) {
    return MmSettings(
      title: map['title'] as String,
      ordering: mmOrderingConverter.from(
        map['orderField'],
        map['orderDescending'],
      ),
    );
  }
}''',
  contains: true,
)
@Mapper(uses: {MmOrderingConverter})
abstract class MmFromMapUntypedMapper {
  @Mapping(target: 'ordering', source: 'orderField,orderDescending')
  MmSettings fromMap(Map<String, dynamic> map);
}

@ShouldGenerate(
  r'''class MmFromMapObjectMapperImpl extends MmFromMapObjectMapper {
  MmFromMapObjectMapperImpl({required this.mmOrderingConverter});

  final MmOrderingConverter mmOrderingConverter;

  @override
  MmSettings fromMap(Map<String, Object?> map) {
    return MmSettings(
      title: map['title'] as String,
      ordering: mmOrderingConverter.from(
        map['orderField'] as String?,
        map['orderDescending'] as bool,
      ),
    );
  }
}''',
  contains: true,
)
@Mapper(uses: {MmOrderingConverter})
abstract class MmFromMapObjectMapper {
  @Mapping(target: 'ordering', source: 'orderField,orderDescending')
  MmSettings fromMap(Map<String, Object?> map);
}

@ShouldGenerate(
  r'''class MmFromMapTypedMapperImpl extends MmFromMapTypedMapper {
  MmFromMapTypedMapperImpl({required this.mmRangeConverter});

  final MmRangeConverter mmRangeConverter;

  @override
  MmRanged fromMap(Map<String, String?> map) {
    return MmRanged(range: mmRangeConverter.of(map['from'], map['to']));
  }
}''',
  contains: true,
)
@Mapper(uses: {MmRangeConverter})
abstract class MmFromMapTypedMapper {
  @Mapping(target: 'range', source: 'from,to')
  MmRanged fromMap(Map<String, String?> map);
}

@ShouldGenerate(
  r'''class MmFromMapMixedMapperImpl extends MmFromMapMixedMapper {
  MmFromMapMixedMapperImpl({required this.mmOrderingConverter});

  final MmOrderingConverter mmOrderingConverter;

  @override
  MmSettings fromMap(MmMeta meta, Map<String, dynamic> map) {
    return MmSettings(
      title: map['title'] as String,
      ordering: mmOrderingConverter.from(meta.field, map['orderDescending']),
    );
  }
}''',
  contains: true,
)
@Mapper(uses: {MmOrderingConverter})
abstract class MmFromMapMixedMapper {
  @Mapping(target: 'ordering', source: 'meta.field,map.orderDescending')
  @Mapping(target: 'title', source: 'map.title')
  MmSettings fromMap(MmMeta meta, Map<String, dynamic> map);
}

@ShouldGenerate(
  r'''class MmFromMapOwnMethodMapperImpl extends MmFromMapOwnMethodMapper {
  MmFromMapOwnMethodMapperImpl();

  @override
  MmSettings fromMap(Map<String, dynamic> map) {
    return MmSettings(
      title: map['title'] as String,
      ordering: order(map['orderField'], map['orderDescending']),
    );
  }
}''',
  contains: true,
)
@Mapper()
abstract class MmFromMapOwnMethodMapper {
  @Mapping(target: 'ordering', source: 'orderField,orderDescending')
  MmSettings fromMap(Map<String, dynamic> map);

  MmOrdering order(String? field, bool descending) => MmOrdering(
        field: field == null ? null : MmField.values.byName(field),
        descending: descending,
      );
}

@ShouldGenerate(
  r'''class MmFromMapQualifiedMapperImpl extends MmFromMapQualifiedMapper {
  MmFromMapQualifiedMapperImpl({required this.mmOrderingConverter});

  final MmOrderingConverter mmOrderingConverter;

  @override
  MmSettings fromMap(Map<String, dynamic> map) {
    return MmSettings(
      title: map['title'] as String,
      ordering: mmOrderingConverter.from(
        map['orderField'],
        map['orderDescending'],
      ),
    );
  }
}''',
  contains: true,
)
@Mapper(uses: {MmOrderingConverter})
abstract class MmFromMapQualifiedMapper {
  @Mapping(
    target: 'ordering',
    source: 'orderField,orderDescending',
    qualifiedBy: 'MmOrderingConverter.from',
  )
  MmSettings fromMap(Map<String, dynamic> map);
}

@ShouldGenerate(
  r'''class MmFromMapDefaultMapperImpl extends MmFromMapDefaultMapper {
  MmFromMapDefaultMapperImpl({required this.mmOrderingConverter});

  final MmOrderingConverter mmOrderingConverter;

  @override
  MmSettings fromMap(Map<String, dynamic> map) {
    return MmSettings(
      title: map['title'] as String,
      ordering:
          mmOrderingConverter.from(map['orderField'], map['orderDescending']) ??
          MmOrdering(descending: false),
    );
  }
}''',
  contains: true,
)
@Mapper(uses: {MmOrderingConverter})
abstract class MmFromMapDefaultMapper {
  @Mapping(
    target: 'ordering',
    source: 'orderField,orderDescending',
    defaultValue: 'MmOrdering(descending: false)',
  )
  MmSettings fromMap(Map<String, dynamic> map);
}

@ShouldGenerate(
  r'''class MmFromMapNestedTargetMapperImpl extends MmFromMapNestedTargetMapper {
  MmFromMapNestedTargetMapperImpl({required this.mmLabelConverter});

  final MmLabelConverter mmLabelConverter;

  @override
  MmNested fromMap(Map<String, dynamic> map) {
    return MmNested(
      title: map['title'] as String,
      ordering: MmNestedOrdering(
        label: mmLabelConverter.label(
          map['orderField'],
          map['orderDescending'],
        ),
      ),
    );
  }
}''',
  contains: true,
)
@Mapper(uses: {MmLabelConverter})
abstract class MmFromMapNestedTargetMapper {
  @Mapping(target: 'ordering.label', source: 'orderField,orderDescending')
  MmNested fromMap(Map<String, dynamic> map);
}

@ShouldGenerate(
  r'''class MmFromMapQualifiedSingleMapperImpl
    extends MmFromMapQualifiedSingleMapper {
  MmFromMapQualifiedSingleMapperImpl({required this.mmAmbiguousConverters});

  final MmAmbiguousConverters mmAmbiguousConverters;

  @override
  MmStamped fromMap(Map<String, dynamic> map) {
    return MmStamped(
      name: map['name'] as String,
      at: mmAmbiguousConverters.fromIso(map['at'] as String),
    );
  }
}''',
  contains: true,
)
@Mapper(uses: {MmAmbiguousConverters})
abstract class MmFromMapQualifiedSingleMapper {
  @Mapping(target: 'at', source: 'at', qualifiedBy: 'fromIso')
  MmStamped fromMap(Map<String, dynamic> map);
}

@ShouldThrow(
  "Ambiguous mapper method for @Mapping(target: 'ordering'): multiple methods match (MmDuplicatedConverters.first(String? field, bool descending), MmDuplicatedConverters.second(String? field, bool descending)).\n"
  "Fix: Select the one to use with @Mapping(target: 'ordering', qualifiedBy: 'methodName') or qualifiedBy: 'MapperClass.methodName'.",
)
@Mapper(uses: {MmDuplicatedConverters})
abstract class MmFromMapAmbiguousMapper {
  @Mapping(target: 'ordering', source: 'orderField,orderDescending')
  MmSettings fromMap(Map<String, dynamic> map);
}

@ShouldThrow(
  "No mapper method found for @Mapping(target: 'ordering') with source (dynamic orderField, dynamic orderDescending) returning MmOrdering.\n"
  "Rejected candidates:\n"
  "  - MmRangeConverter.of(String? from, String? to): returns MmRange, not assignable to the target MmOrdering\n"
  "Fix: Add a mapper method (in the mapper or in a mapper listed in uses) taking these parameters in this order and returning a value assignable to the target, or use callable.",
)
@Mapper(uses: {MmRangeConverter})
abstract class MmFromMapNoMatchMapper {
  @Mapping(target: 'ordering', source: 'orderField,orderDescending')
  MmSettings fromMap(Map<String, dynamic> map);
}

@ShouldThrow(
  "No mapper method found for @Mapping(target: 'ordering') with source (String? meta.field, dynamic map.orderDescending) returning MmOrdering.\n"
  "Rejected candidates:\n"
  "  - MmStrictConverter.of(String field, bool descending): argument 1 (`meta.field`) may be null (String?) but parameter 1 is String\n"
  "Fix: Add a mapper method (in the mapper or in a mapper listed in uses) taking these parameters in this order and returning a value assignable to the target, or use callable.",
)
@Mapper(uses: {MmStrictConverter})
abstract class MmFromMapNullabilityMapper {
  @Mapping(target: 'ordering', source: 'meta.field,map.orderDescending')
  @Mapping(target: 'title', source: 'map.title')
  MmSettings fromMap(MmMeta meta, Map<String, dynamic> map);
}

@ShouldThrow(
  "qualifiedBy 'nope' in @Mapping(target: 'ordering') does not match any mapper method.\n"
  "Available methods: MmOrderingConverter.from.\n"
  "Fix: Use 'methodName' or 'MapperClass.methodName' of a method of the mapper or of a mapper listed in uses.",
)
@Mapper(uses: {MmOrderingConverter})
abstract class MmFromMapUnknownQualifiedMapper {
  @Mapping(
    target: 'ordering',
    source: 'orderField,orderDescending',
    qualifiedBy: 'nope',
  )
  MmSettings fromMap(Map<String, dynamic> map);
}

// ----- class -> Map -----

@ShouldGenerate(
  r'''class MmToMapMapperImpl extends MmToMapMapper {
  MmToMapMapperImpl({required this.mmLabelConverter});

  final MmLabelConverter mmLabelConverter;

  @override
  Map<String, dynamic> toMap(MmSettingsDto dto) {
    return {
      'title': dto.title,
      'ordering': mmLabelConverter.label(dto.orderField, dto.orderDescending),
    };
  }
}''',
  contains: true,
)
@Mapper(uses: {MmLabelConverter})
abstract class MmToMapMapper {
  @Mapping(target: 'ordering', source: 'orderField,orderDescending')
  @Mapping(target: 'orderField', ignore: true)
  @Mapping(target: 'orderDescending', ignore: true)
  Map<String, dynamic> toMap(MmSettingsDto dto);
}

@ShouldGenerate(
  r'''class MmToMapTypedMapperImpl extends MmToMapTypedMapper {
  MmToMapTypedMapperImpl({required this.mmLabelConverter});

  final MmLabelConverter mmLabelConverter;

  @override
  Map<String, String> toMap(MmSettingsDto dto) {
    return {
      'ordering': mmLabelConverter.label(dto.orderField, dto.orderDescending),
    };
  }
}''',
  contains: true,
)
@Mapper(uses: {MmLabelConverter})
abstract class MmToMapTypedMapper {
  @Mapping(target: 'ordering', source: 'orderField,orderDescending')
  @Mapping(target: 'title', ignore: true)
  @Mapping(target: 'orderField', ignore: true)
  @Mapping(target: 'orderDescending', ignore: true)
  Map<String, String> toMap(MmSettingsDto dto);
}

@ShouldGenerate(
  r'''class MmToMapOwnMethodMapperImpl extends MmToMapOwnMethodMapper {
  MmToMapOwnMethodMapperImpl();

  @override
  Map<String, dynamic> toMap(MmSettingsDto dto) {
    return {
      'title': dto.title,
      'ordering': describe(dto.orderField, dto.orderDescending),
    };
  }
}''',
  contains: true,
)
@Mapper()
abstract class MmToMapOwnMethodMapper {
  @Mapping(target: 'ordering', source: 'orderField,orderDescending')
  @Mapping(target: 'orderField', ignore: true)
  @Mapping(target: 'orderDescending', ignore: true)
  Map<String, dynamic> toMap(MmSettingsDto dto);

  String describe(String? field, bool descending) =>
      '${field ?? 'none'} ${descending ? 'desc' : 'asc'}';
}

@ShouldGenerate(
  r'''class MmToMapDefaultMapperImpl extends MmToMapDefaultMapper {
  MmToMapDefaultMapperImpl({required this.mmLabelConverter});

  final MmLabelConverter mmLabelConverter;

  @override
  Map<String, dynamic> toMap(MmSettingsDto dto) {
    return {
      'title': dto.title,
      'ordering':
          mmLabelConverter.label(dto.orderField, dto.orderDescending) ??
          '\'none\'',
    };
  }
}''',
  contains: true,
)
@Mapper(uses: {MmLabelConverter})
abstract class MmToMapDefaultMapper {
  @Mapping(
    target: 'ordering',
    source: 'orderField,orderDescending',
    defaultValue: "'none'",
  )
  @Mapping(target: 'orderField', ignore: true)
  @Mapping(target: 'orderDescending', ignore: true)
  Map<String, dynamic> toMap(MmSettingsDto dto);
}

@ShouldGenerate(
  r'''class MmToMapQualifiedSingleMapperImpl extends MmToMapQualifiedSingleMapper {
  MmToMapQualifiedSingleMapperImpl({required this.mmAmbiguousConverters});

  final MmAmbiguousConverters mmAmbiguousConverters;

  @override
  Map<String, dynamic> toMap(MmStampedDto dto) {
    return {'name': dto.name, 'at': mmAmbiguousConverters.toIso(dto.at)};
  }
}''',
  contains: true,
)
@Mapper(uses: {MmAmbiguousConverters})
abstract class MmToMapQualifiedSingleMapper {
  @Mapping(target: 'at', source: 'at', qualifiedBy: 'toIso')
  Map<String, dynamic> toMap(MmStampedDto dto);
}

@ShouldThrow(
  "Ambiguous mapping for type 'DateTime': multiple methods are candidates (mmAmbiguousConverters.toMillis, mmAmbiguousConverters.toIso).\n"
  "Fix: Keep a single candidate per type, or select the one to use with @Mapping(target: '...', qualifiedBy: 'methodName') or @Mapping(target: '...', callable: yourFunction).",
)
@Mapper(uses: {MmAmbiguousConverters})
abstract class MmToMapAmbiguousMapper {
  Map<String, dynamic> toMap(MmStampedDto dto);
}

@ShouldGenerate(
  r'''class MmToMapQualifiedMapperImpl extends MmToMapQualifiedMapper {
  MmToMapQualifiedMapperImpl({
    required this.mmOrderingConverter,
    required this.mmLabelConverter,
  });

  final MmOrderingConverter mmOrderingConverter;

  final MmLabelConverter mmLabelConverter;

  @override
  Map<String, dynamic> toMap(MmSettingsDto dto) {
    return {
      'title': dto.title,
      'ordering': mmLabelConverter.label(dto.orderField, dto.orderDescending),
    };
  }
}''',
  contains: true,
)
@Mapper(uses: {MmOrderingConverter, MmLabelConverter})
abstract class MmToMapQualifiedMapper {
  @Mapping(
    target: 'ordering',
    source: 'orderField,orderDescending',
    qualifiedBy: 'MmLabelConverter.label',
  )
  @Mapping(target: 'orderField', ignore: true)
  @Mapping(target: 'orderDescending', ignore: true)
  Map<String, dynamic> toMap(MmSettingsDto dto);
}

@ShouldThrow(
  "Ambiguous mapper method for @Mapping(target: 'ordering'): multiple methods match (MmOrderingConverter.from(String? field, bool descending), MmLabelConverter.label(String? field, bool descending)).\n"
  "Fix: Select the one to use with @Mapping(target: 'ordering', qualifiedBy: 'methodName') or qualifiedBy: 'MapperClass.methodName'.",
)
@Mapper(uses: {MmOrderingConverter, MmLabelConverter})
abstract class MmToMapAmbiguousMethodMapper {
  @Mapping(target: 'ordering', source: 'orderField,orderDescending')
  @Mapping(target: 'orderField', ignore: true)
  @Mapping(target: 'orderDescending', ignore: true)
  Map<String, dynamic> toMap(MmSettingsDto dto);
}

@ShouldThrow(
  "No mapper method found for @Mapping(target: 'ordering') with source (String? orderField, bool orderDescending).\n"
  "Rejected candidates:\n"
  "  - MmRangeConverter.of(String? from, String? to): argument 2 (`orderDescending`) is bool, not assignable to parameter 2 (String?)\n"
  "Fix: Add a mapper method (in the mapper or in a mapper listed in uses) taking these parameters in this order and returning a value assignable to the target, or use callable.",
)
@Mapper(uses: {MmRangeConverter})
abstract class MmToMapNoMatchMapper {
  @Mapping(target: 'ordering', source: 'orderField,orderDescending')
  Map<String, dynamic> toMap(MmSettingsDto dto);
}

@ShouldThrow(
  "qualifiedBy 'nope' in @Mapping(target: 'ordering') does not match any mapper method.\n"
  "Available methods: MmOrderingConverter.from.\n"
  "Fix: Use 'methodName' or 'MapperClass.methodName' of a method of the mapper or of a mapper listed in uses.",
)
@Mapper(uses: {MmOrderingConverter})
abstract class MmToMapUnknownQualifiedMapper {
  @Mapping(
    target: 'ordering',
    source: 'orderField,orderDescending',
    qualifiedBy: 'nope',
  )
  Map<String, dynamic> toMap(MmSettingsDto dto);
}
