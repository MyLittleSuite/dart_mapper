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
