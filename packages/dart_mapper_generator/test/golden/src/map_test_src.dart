import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

class SourceWithMap {
  final Map<String, int> metadata;

  SourceWithMap(this.metadata);
}

class TargetWithMap {
  final Map<String, int> metadata;

  TargetWithMap(this.metadata);
}

@ShouldGenerate(
  'MapEntry(key, value)',
  contains: true,
)
@Mapper()
abstract class MapFieldMapper {
  TargetWithMap toTarget(SourceWithMap source);
}

class MapInnerSource {
  final String name;

  MapInnerSource(this.name);
}

class MapInnerTarget {
  final String name;

  MapInnerTarget(this.name);
}

class SourceWithNestedMap {
  final Map<String, MapInnerSource> items;

  SourceWithNestedMap(this.items);
}

class TargetWithNestedMap {
  final Map<String, MapInnerTarget> items;

  TargetWithNestedMap(this.items);
}

@ShouldGenerate(
  'MapEntry(',
  contains: true,
)
@Mapper()
abstract class NestedMapMapper {
  // ignore: unused_element
  MapInnerTarget _mapInner(MapInnerSource source);
  TargetWithNestedMap toTarget(SourceWithNestedMap source);
}
