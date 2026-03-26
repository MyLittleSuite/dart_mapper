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
