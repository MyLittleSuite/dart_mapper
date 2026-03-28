import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

class MultiArgSource {
  final String firstName;
  final String lastName;

  const MultiArgSource(this.firstName, this.lastName);
}

class MultiArgTarget {
  final String fullName;

  const MultiArgTarget(this.fullName);
}

String _merge(dynamic first, dynamic last) => '$first $last';

@ShouldGenerate(
  r'''class MultiArgCallableMapperImpl extends MultiArgCallableMapper {
  const MultiArgCallableMapperImpl();

  @override
  MultiArgTarget toTarget(MultiArgSource source) {
    return MultiArgTarget(_merge(source.firstName, source.lastName));
  }
}''',
  contains: true,
)
@Mapper()
abstract class MultiArgCallableMapper {
  const MultiArgCallableMapper();

  @Mapping(target: 'fullName', source: 'firstName,lastName', callable: _merge)
  MultiArgTarget toTarget(MultiArgSource source);
}

@ShouldThrow(
  "Comma-separated source part 'nonExistent' in @Mapping(target: 'fullName') "
  "could not be resolved on any source parameter.\n"
  "Fix: Check that each comma-separated part refers to a valid field or "
  "qualified dot-path (paramName.fieldName).",
)
@Mapper()
abstract class MultiArgCallableErrorMapper {
  @Mapping(
    target: 'fullName',
    source: 'firstName,nonExistent',
    callable: _merge,
  )
  MultiArgTarget toTarget(MultiArgSource source);
}
