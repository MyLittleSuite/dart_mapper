# dart_mapper

A simple library to map Dart objects.

## Getting started

Add the following dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  dart_mapper: latest

dev_dependencies:
  build_runner: ^2.4.13
  dart_mapper_generator: latest
```

Create an abstract mapper class with the Mapper and Mapping annotation:

```dart

import 'package:dart_mapper/dart_mapper.dart';

part 'mixed.g.dart';

class MixedObject {
  final String name;
  final int age;
  final bool isAdult;
  final DateTime? birthday;

  MixedObject(this.name,
      this.age, {
        required this.isAdult,
        this.birthday,
      },);
}

class AnotherMixedObject {
  final String name;
  final int age;
  final bool adult;
  final DateTime? birthday;

  AnotherMixedObject(this.name,
      this.age, {
        required this.adult,
        this.birthday,
      },);
}

@Mapper()
abstract class MixedMapper {
  @Mapping(target: 'adult', source: 'isAdult')
  AnotherMixedObject toAnotherMixedObject(MixedObject mixedObject);

  @Mapping(target: 'isAdult', source: 'adult')
  MixedObject toMixedObject(AnotherMixedObject anotherMixedObject);
}
```

Run the following command to generate the barrel files:

```shell
dart run build_runner build --delete-conflicting-outputs
```

### Code generations

If you objects depend on other generators, you need to specify the build order in your `build.yaml`
file.
Below an example using `freezed` and/or `built_value`:

```yaml
global_options:
  freezed:
    runs_before:
      - dart_mapper_generator
  built_value_generator:built_value:
    runs_before:
      - dart_mapper_generator
```
