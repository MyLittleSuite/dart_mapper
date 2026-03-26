import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

class RenameSource {
  final String firstName;
  final int years;

  RenameSource(this.firstName, this.years);
}

class RenameTarget {
  final String name;
  final int age;

  RenameTarget(this.name, this.age);
}

@ShouldGenerate(
  r'''class RenameMapperImpl extends RenameMapper {
  RenameMapperImpl();

  @override
  RenameTarget toTarget(RenameSource source) {
    return RenameTarget(source.firstName, source.years);
  }
}''',
  contains: true,
)
@Mapper()
abstract class RenameMapper {
  @Mapping(target: 'name', source: 'firstName')
  @Mapping(target: 'age', source: 'years')
  RenameTarget toTarget(RenameSource source);
}
