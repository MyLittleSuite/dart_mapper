import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

class SourceWithDynamic {
  final String name;
  final dynamic extra;

  SourceWithDynamic(this.name, this.extra);
}

class TargetWithDynamic {
  final String name;
  final dynamic extra;

  TargetWithDynamic(this.name, this.extra);
}

@ShouldGenerate(
  'TargetWithDynamic(source.name, source.extra)',
  contains: true,
)
@Mapper()
abstract class DynamicFieldMapper {
  TargetWithDynamic toTarget(SourceWithDynamic source);
}
