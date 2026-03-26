import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

class BasicSource {
  final String name;
  final int age;

  BasicSource(this.name, this.age);
}

class BasicTarget {
  final String name;
  final int age;

  const BasicTarget(this.name, this.age);
}

@ShouldGenerate(
  r'''class BasicMapperImpl extends BasicMapper {
  BasicMapperImpl();

  @override
  BasicTarget toTarget(BasicSource source) {
    return BasicTarget(source.name, source.age);
  }
}''',
  contains: true,
)
@Mapper()
abstract class BasicMapper {
  BasicTarget toTarget(BasicSource source);
}
