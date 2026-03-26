import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

class MultiSource {
  String? name;
  int? age;

  MultiSource.none();

  MultiSource.complete(this.name, this.age);
}

class MultiTarget {
  String? name;
  int? age;

  MultiTarget(this.name, this.age);
}

@ShouldGenerate(
  r'''class MultiMapperImpl extends MultiMapper {
  MultiMapperImpl();

  @override
  MultiSource toSource(MultiTarget target) {
    return MultiSource.complete(target.name, target.age);
  }

  @override
  MultiTarget toTarget(MultiSource source) {
    return MultiTarget(source.name, source.age);
  }
}''',
  contains: true,
)
@Mapper()
abstract class MultiMapper {
  MultiSource toSource(MultiTarget target);

  MultiTarget toTarget(MultiSource source);
}
