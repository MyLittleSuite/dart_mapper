import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

class CollSource {
  final List<int> numbers;
  final Set<String> tags;

  CollSource({required this.numbers, required this.tags});
}

class CollTarget {
  final List<int> numbers;
  final Set<String> tags;

  CollTarget({required this.numbers, required this.tags});
}

@ShouldGenerate(
  r'''class CollMapperImpl extends CollMapper {
  CollMapperImpl();

  @override
  CollTarget toTarget(CollSource source) {
    return CollTarget(
      numbers: source.numbers.map((item) => item).toList(growable: true),
      tags: source.tags.map((item) => item).toSet(),
    );
  }
}''',
  contains: true,
)
@Mapper()
abstract class CollMapper {
  CollTarget toTarget(CollSource source);
}
