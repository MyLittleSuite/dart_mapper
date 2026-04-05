import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

class FnnSource {
  final String? name;
  final int? age;

  FnnSource(this.name, this.age);
}

class FnnTarget {
  final String name;
  final int age;

  FnnTarget(this.name, this.age);
}

@ShouldGenerate(
  r'''class FnnMapperImpl extends FnnMapper {
  FnnMapperImpl();

  @override
  FnnTarget toTarget(FnnSource source) {
    return FnnTarget(source.name!, source.age!);
  }
}''',
  contains: true,
)
@Mapper()
abstract class FnnMapper {
  @Mapping(target: 'name', forceNonNull: true)
  @Mapping(target: 'age', forceNonNull: true)
  FnnTarget toTarget(FnnSource source);
}

// forceNonNull with external mapper: nullable nested field must not generate
// a ternary null-guard when forceNonNull: true is set.
// Expected: fnnNestedMapper.toNested(source.nested!)
// NOT:      source.nested != null ? fnnNestedMapper.toNested(source.nested!) : null
class FnnNestedSource {
  final String value;

  FnnNestedSource(this.value);
}

class FnnNestedTarget {
  final String value;

  FnnNestedTarget(this.value);
}

class FnnOuterSource {
  final FnnNestedSource? nested;

  FnnOuterSource(this.nested);
}

class FnnOuterTarget {
  final FnnNestedTarget nested;

  FnnOuterTarget(this.nested);
}

@Mapper()
abstract class FnnNestedMapper {
  FnnNestedTarget toNested(FnnNestedSource source);
}

@ShouldGenerate(
  r'fnnNestedMapper.toNested(source.nested!)',
  contains: true,
)
@Mapper(uses: {FnnNestedMapper})
abstract class FnnOuterMapper {
  @Mapping(target: 'nested', forceNonNull: true)
  FnnOuterTarget toTarget(FnnOuterSource source);
}
