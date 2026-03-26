import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

class NullableSource {
  final String value;

  const NullableSource(this.value);
}

class NullableTarget {
  final String? value;

  const NullableTarget(this.value);
}

@ShouldGenerate(
  r'''class NullMapperImpl extends NullMapper {
  NullMapperImpl();

  @override
  NullableTarget toTarget(NullableSource source) {
    return NullableTarget(source.value);
  }
}''',
  contains: true,
)
@Mapper()
abstract class NullMapper {
  NullableTarget toTarget(NullableSource source);
}
