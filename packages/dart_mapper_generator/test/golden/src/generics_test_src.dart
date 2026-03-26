import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

class Wrapper<T> {
  final T value;
  final String label;

  Wrapper(this.value, this.label);
}

class TargetWrapper {
  final String value;
  final String label;

  TargetWrapper(this.value, this.label);
}

// Generic type parameter T resolves to String at the method level,
// so value: source.value should use direct assignment.
// Note: Unresolvable generic types (Wrapper<T> without concrete substitution)
// cannot occur in valid Dart code -- the compiler prevents it.
@ShouldGenerate(
  'TargetWrapper(source.value, source.label)',
  contains: true,
)
@Mapper()
abstract class GenericMapper {
  TargetWrapper convert(Wrapper<String> source);
}
