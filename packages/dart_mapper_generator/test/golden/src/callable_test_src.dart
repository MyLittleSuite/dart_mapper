import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

class CallSource {
  final String name;
  final int price;

  const CallSource(this.name, this.price);
}

class CallTarget {
  final String name;
  final int price;

  const CallTarget(this.name, this.price);
}

int _doublePrice(dynamic price) {
  return price * 2;
}

@ShouldGenerate(
  r'''class CallMapperImpl extends CallMapper {
  const CallMapperImpl();

  @override
  CallTarget toTarget(CallSource source) {
    return CallTarget(source.name, _doublePrice(source.price));
  }
}''',
  contains: true,
)
@Mapper()
abstract class CallMapper {
  const CallMapper();

  @Mapping(target: 'price', callable: _doublePrice)
  CallTarget toTarget(CallSource source);
}
