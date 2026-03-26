import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

class MixSource {
  final String name;
  final int age;
  final bool isActive;
  final DateTime? birthday;

  MixSource(
    this.name,
    this.age, {
    required this.isActive,
    this.birthday,
  });
}

class MixTarget {
  final String name;
  final int age;
  final bool active;
  final DateTime? birthday;

  MixTarget(
    this.name,
    this.age, {
    required this.active,
    this.birthday,
  });
}

@ShouldGenerate(
  r'''class MixMapperImpl extends MixMapper {
  MixMapperImpl();

  @override
  MixTarget toTarget(MixSource source) {
    return MixTarget(
      source.name,
      source.age,
      active: source.isActive,
      birthday: source.birthday,
    );
  }
}''',
  contains: true,
)
@Mapper()
abstract class MixMapper {
  @Mapping(target: 'active', source: 'isActive')
  MixTarget toTarget(MixSource source);
}
