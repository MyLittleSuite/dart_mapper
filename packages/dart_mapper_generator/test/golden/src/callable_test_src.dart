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

class NullableCallSource {
  final String name;
  final int? price;

  const NullableCallSource(this.name, this.price);
}

int _priceOrZero(dynamic price) {
  return price ?? 0;
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

@ShouldGenerate(
  r'''_priceOrZero(source.price)''',
  contains: true,
)
@Mapper()
abstract class NullableCallMapper {
  const NullableCallMapper();

  @Mapping(target: 'price', callable: _priceOrZero)
  CallTarget toTarget(NullableCallSource source);
}
