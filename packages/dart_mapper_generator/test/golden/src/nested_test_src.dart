import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

class InnerSource {
  final String value;

  InnerSource(this.value);
}

class InnerTarget {
  final String value;

  InnerTarget(this.value);
}

class OuterSource {
  final String name;
  final InnerSource inner;

  OuterSource(this.name, this.inner);
}

class OuterTarget {
  final String name;
  final InnerTarget inner;

  OuterTarget(this.name, this.inner);
}

@ShouldGenerate(
  r'''class InnerMapperImpl extends InnerMapper {
  InnerMapperImpl();

  @override
  InnerTarget toTarget(InnerSource source) {
    return InnerTarget(source.value);
  }
}''',
  contains: true,
)
@Mapper()
abstract class InnerMapper {
  InnerTarget toTarget(InnerSource source);
}

@ShouldGenerate(
  r'''class OuterMapperImpl extends OuterMapper {
  OuterMapperImpl({required this.innerMapper});

  final InnerMapper innerMapper;

  @override
  OuterTarget toTarget(OuterSource source) {
    return OuterTarget(source.name, innerMapper.toTarget(source.inner));
  }
}''',
  contains: true,
)
@Mapper(uses: {InnerMapper})
abstract class OuterMapper {
  OuterTarget toTarget(OuterSource source);
}

// Regression: `ignore: true` on a nested field must suppress synthesis of the
// nested converter. The extra mapping method used to be analyzed anyway,
// throwing NoRelationFoundError for a mapping that is never emitted.

class IgnoredInnerSource {
  final String code;

  IgnoredInnerSource(this.code);
}

class IgnoredInnerTarget {
  final String code;
  final String direction;

  IgnoredInnerTarget({required this.code, required this.direction});
}

class IgnoredNestedSource {
  final String id;
  final IgnoredInnerSource? inner;

  IgnoredNestedSource(this.id, this.inner);
}

class IgnoredNestedTarget {
  final String id;
  final IgnoredInnerTarget? inner;

  IgnoredNestedTarget({required this.id, this.inner});
}

@ShouldGenerate(
  r'''class IgnoredNestedMapperImpl extends IgnoredNestedMapper {
  IgnoredNestedMapperImpl();

  @override
  IgnoredNestedTarget toTarget(IgnoredNestedSource source) {
    return IgnoredNestedTarget(id: source.id, inner: null);
  }
}''',
  contains: true,
)
@Mapper()
abstract class IgnoredNestedMapper {
  @Mapping(target: 'inner', ignore: true)
  IgnoredNestedTarget toTarget(IgnoredNestedSource source);
}
