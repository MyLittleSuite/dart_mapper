// Golden test source for timestamp doc comments.
//
// The per-annotation timestamp option is intentionally unsupported. Timestamp
// doc comments are controlled by the builder-level `timestamp_doc` option.

import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

class TimestampSource {
  final String value;

  TimestampSource(this.value);
}

class TimestampTarget {
  final String value;

  TimestampTarget(this.value);
}

@ShouldGenerate(
  r'''class TimestampDefaultMapperImpl extends TimestampDefaultMapper {''',
  contains: true,
)
@Mapper()
abstract class TimestampDefaultMapper {
  TimestampTarget toTarget(TimestampSource source);
}
