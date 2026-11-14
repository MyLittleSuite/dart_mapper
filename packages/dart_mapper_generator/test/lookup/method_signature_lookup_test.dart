import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:dart_mapper/dart_mapper.dart';
import 'package:dart_mapper_generator/src/analyzers/contexts/analyzer_context.dart';
import 'package:dart_mapper_generator/src/analyzers/contexts/method_analyzer_context.dart';
import 'package:dart_mapper_generator/src/analyzers/internal_uses_analyzer.dart';
import 'package:dart_mapper_generator/src/analyzers/mapping_method/method_signature_lookup.dart';
import 'package:dart_mapper_generator/src/exceptions/ambiguous_mapping_method_error.dart';
import 'package:dart_mapper_generator/src/exceptions/no_matching_mapping_method_error.dart';
import 'package:dart_mapper_generator/src/exceptions/unknown_qualified_method_error.dart';
import 'package:dart_mapper_generator/src/extensions/mapping_method.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/external_mapping_method.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/internal_mapping_method.dart';
import 'package:dart_mapper_generator/src/models/mapper_usage.dart';
import 'package:source_gen_test/source_gen_test.dart';
import 'package:test/test.dart';

void main() async {
  final reader = await initializeLibraryReaderForDirectory(
    'test/lookup',
    'method_signature_lookup_src.dart',
  );
  final library = reader.allElements.first.library!;
  ClassElement classOf(String name) =>
      library.classes.firstWhere((element) => element.name == name);
  final typeProvider = library.typeProvider;
  final system = library.typeSystem;

  DartType type(String name, {bool nullable = false}) {
    final base = switch (name) {
      'String' => typeProvider.stringType,
      'bool' => typeProvider.boolType,
      'int' => typeProvider.intType,
      'Object' => typeProvider.objectType,
      _ => classOf(name).thisType,
    };

    return nullable
        ? system.leastUpperBound(base, typeProvider.nullType)
        : base;
  }

  /// The methods of [className] as the usages of a used mapper.
  Set<MapperUsage> used(String className, String name) => InternalUsesAnalyzer()
      .analyze(
        AnalyzerContext(
          mapperAnnotation: const Mapper(),
          mapperClass: classOf(className),
        ),
      )
      .map(
        (usage) => MapperUsage(
          mapperName: name,
          mapperType: usage.mapperType,
          returnType: usage.returnType,
          functionName: usage.functionName,
          parameters: usage.parameters,
          isAbstract: usage.isAbstract,
        ),
      )
      .toSet();

  MethodSignatureLookup lookup({
    Set<MapperUsage>? uses,
    String method = 'toHolder',
  }) {
    final own = classOf('OwnMapper');

    return MethodSignatureLookup(
      MethodAnalyzerContext(
        mapperAnnotation: const Mapper(),
        mapperClass: own,
        mapperUsages: uses ?? used('UsedMapper', 'usedMapper'),
        internalMapperUsages: InternalUsesAnalyzer().analyze(
          AnalyzerContext(mapperAnnotation: const Mapper(), mapperClass: own),
        ),
        importAliases: const {},
        method: own.methods.firstWhere((m) => m.name == method),
      ),
    );
  }

  SourceArgument arg(
    String name, {
    bool nullable = false,
    bool chain = false,
    bool untyped = false,
  }) =>
      SourceArgument(
        type: type(name, nullable: nullable),
        description: 'from.$name',
        nullableChain: chain,
        untyped: untyped,
      );

  final nullableString = arg('String', nullable: true);
  final flag = arg('bool');

  String nameOf(dynamic method) => method.name as String;

  test('finds a method of a used mapper, positional and in order', () {
    final method = lookup().find(
      target: 'ordering',
      arguments: [nullableString, flag],
      targetType: type('Ordering'),
      qualifiedBy: 'UsedMapper.from',
    );

    expect(method, isA<ExternalMappingMethod>());
    expect(nameOf(method), 'usedMapper.from');
    expect(method.parameterTypeAt(0), type('String', nullable: true));
    expect(method.parameterTypeAt(1), type('bool'));
    expect(method.parameterTypeAt(2), isNull);
  });

  test('prefers the used mappers over the own methods', () {
    final method = lookup().find(
      target: 'ordering',
      arguments: [nullableString, flag],
      targetType: type('Ordering'),
      qualifiedBy: 'from',
    );

    expect(nameOf(method), 'usedMapper.from');
  });

  test('falls back to the own methods', () {
    final method = lookup(uses: const {}).find(
      target: 'ordering',
      arguments: [nullableString, flag],
      targetType: type('Ordering'),
    );

    expect(method, isA<InternalMappingMethod>());
    expect(nameOf(method), 'fromOwn');
  });

  test('never picks the method being generated', () {
    // toHolder(String?, bool) would match, but it is the generated method.
    expect(
      () => lookup(uses: const {}).find(
        target: 'holder',
        arguments: [nullableString, flag],
        targetType: type('Holder'),
      ),
      throwsA(isA<NoMatchingMappingMethodError>()),
    );
  });

  test('a null or dynamic target type accepts any return type', () {
    final ambiguous = throwsA(isA<AmbiguousMappingMethodError>());
    expect(
      () => lookup().find(
        target: 'x',
        arguments: [nullableString, flag],
      ),
      ambiguous,
    );
    expect(
      () => lookup().find(
        target: 'x',
        arguments: [nullableString, flag],
        targetType: typeProvider.dynamicType,
      ),
      ambiguous,
    );
  });

  test('ambiguity between used mappers is reported with qualifiedBy hint', () {
    final uses = {
      ...used('UsedMapper', 'usedMapper'),
      ...used('DuplicateMapper', 'duplicateMapper')
    };

    expect(
      () => lookup(uses: uses).find(
        target: 'ordering',
        arguments: [nullableString, flag],
        targetType: type('Ordering'),
        qualifiedBy: 'from',
      ),
      throwsA(
        isA<AmbiguousMappingMethodError>().having(
          (e) => e.message,
          'message',
          allOf(
            contains('UsedMapper.from'),
            contains('DuplicateMapper.from'),
            contains("qualifiedBy: 'methodName'"),
          ),
        ),
      ),
    );

    final method = lookup(uses: uses).find(
      target: 'ordering',
      arguments: [nullableString, flag],
      targetType: type('Ordering'),
      qualifiedBy: 'DuplicateMapper.from',
    );
    expect(nameOf(method), 'duplicateMapper.from');
  });

  test('nullability is strict and names the argument', () {
    expect(
      () => lookup().find(
        target: 'ordering',
        arguments: [nullableString, flag],
        targetType: type('Ordering'),
        qualifiedBy: 'strict',
      ),
      throwsA(
        isA<NoMatchingMappingMethodError>().having(
          (e) => e.message,
          'message',
          contains('argument 1 (`from.String`) may be null'),
        ),
      ),
    );
  });

  test('a nullable link of the access chain makes the argument nullable', () {
    expect(
      () => lookup().find(
        target: 'ordering',
        arguments: [arg('String', chain: true), flag],
        targetType: type('Ordering'),
        qualifiedBy: 'strict',
      ),
      throwsA(isA<NoMatchingMappingMethodError>()),
    );
    expect(
      nameOf(
        lookup().find(
          target: 'ordering',
          arguments: [arg('String', chain: true), flag],
          targetType: type('Ordering'),
          qualifiedBy: 'UsedMapper.from',
        ),
      ),
      'usedMapper.from',
    );
  });

  test('a non-nullable argument flows into a nullable parameter', () {
    final method = lookup().find(
      target: 'ordering',
      arguments: [arg('String'), flag],
      targetType: type('Ordering'),
      qualifiedBy: 'UsedMapper.from',
    );
    expect(nameOf(method), 'usedMapper.from');
  });

  test('arguments are assignable, not only equal', () {
    final method = lookup().find(
      target: 'ordering',
      arguments: [arg('int'), flag],
      targetType: type('Ordering'),
    );
    expect(nameOf(method), 'usedMapper.fromNum');
  });

  test('untyped arguments match by arity only', () {
    final method = lookup().find(
      target: 'ordering',
      arguments: [
        arg('Object', nullable: true, untyped: true),
        arg('Object', nullable: true, untyped: true),
      ],
      targetType: type('Ordering'),
      qualifiedBy: 'strict',
    );
    expect(nameOf(method), 'usedMapper.strict');
  });

  test('typed Object? arguments are rejected', () {
    expect(
      () => lookup().find(
        target: 'ordering',
        arguments: [
          arg('Object', nullable: true),
          arg('Object', nullable: true),
        ],
        targetType: type('Ordering'),
        qualifiedBy: 'strict',
      ),
      throwsA(isA<NoMatchingMappingMethodError>()),
    );
  });

  test('the return type must be assignable to the target', () {
    expect(
      () => lookup().find(
        target: 'ordering',
        arguments: [nullableString, flag],
        targetType: type('String'),
        qualifiedBy: 'UsedMapper.other',
      ),
      throwsA(
        isA<NoMatchingMappingMethodError>().having(
          (e) => e.message,
          'message',
          allOf(
            contains('returns Other'),
            contains('Rejected candidates'),
            contains('Fix:'),
          ),
        ),
      ),
    );
  });

  test('arity mismatches list every rejected candidate with the reason', () {
    expect(
      () => lookup().find(
        target: 'ordering',
        arguments: [arg('String'), flag, flag],
        targetType: type('Ordering'),
      ),
      throwsA(
        isA<NoMatchingMappingMethodError>().having(
          (e) => e.message,
          'message',
          allOf(
            contains('UsedMapper.from(String? field, bool descending)'),
            contains('takes 2 parameter(s), 3 source(s) given'),
          ),
        ),
      ),
    );
  });

  test('qualifiedBy works on a single source', () {
    final method = lookup().find(
      target: 'ordering',
      arguments: [arg('String')],
      targetType: type('Ordering'),
      qualifiedBy: 'UsedMapper.singleAlt',
    );
    expect(nameOf(method), 'usedMapper.singleAlt');

    expect(
      () => lookup().find(
        target: 'ordering',
        arguments: [arg('String')],
        targetType: type('Ordering'),
      ),
      throwsA(isA<AmbiguousMappingMethodError>()),
    );
  });

  test('an unknown qualifiedBy lists the available methods', () {
    expect(
      () => lookup().find(
        target: 'ordering',
        arguments: [arg('String')],
        targetType: type('Ordering'),
        qualifiedBy: 'Nope.single',
      ),
      throwsA(
        isA<UnknownQualifiedMethodError>().having(
          (e) => e.message,
          'message',
          allOf(contains("'Nope.single'"), contains('UsedMapper.single')),
        ),
      ),
    );
  });
}
