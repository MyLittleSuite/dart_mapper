/*
 * Copyright (c) 2025 MyLittleSuite
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

// Golden test source for ADV-01 and ADV-02: @SubclassMapping dispatch.

import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

// ---- Shared model types ----

class Animal {
  const Animal();
}

class Dog extends Animal {
  final String breed;
  const Dog({required this.breed});
}

class Cat extends Animal {
  final String color;
  const Cat({required this.color});
}

class AnimalDto {
  const AnimalDto();
}

class DogDto extends AnimalDto {
  final String breed;
  const DogDto({required this.breed});
}

class CatDto extends AnimalDto {
  final String color;
  const CatDto({required this.color});
}

// ---- Case 1: Non-sealed source — wildcard MUST be emitted ----
// Source class Animal is not sealed; any unknown subtype hits the wildcard.

@ShouldGenerate(
  r"""AnimalDto toAnimalDto(Animal source) {
    return switch (source) {
      Dog dog => toDogDto(dog),
      Cat cat => toCatDto(cat),
      _ => throw ArgumentError('Unexpected subtype: ${source.runtimeType}'),
    };
  }""",
  contains: true,
)
@Mapper()
abstract class NonSealedAnimalMapper {
  @SubclassMapping(source: Dog, target: DogDto)
  @SubclassMapping(source: Cat, target: CatDto)
  AnimalDto toAnimalDto(Animal source);
  DogDto toDogDto(Dog source);
  CatDto toCatDto(Cat source);
}

// ---- Case 2: Sealed source, ALL subtypes covered — NO wildcard ----
// Dart's exhaustiveness checker guarantees safety; wildcard omitted per D-04.

sealed class Vehicle {
  const Vehicle();
}

class Car extends Vehicle {
  final String make;
  const Car({required this.make});
}

class Truck extends Vehicle {
  final String payload;
  const Truck({required this.payload});
}

class VehicleDto {
  const VehicleDto();
}

class CarDto extends VehicleDto {
  final String make;
  const CarDto({required this.make});
}

class TruckDto extends VehicleDto {
  final String payload;
  const TruckDto({required this.payload});
}

@ShouldGenerate(
  r"""VehicleDto toVehicleDto(Vehicle source) {
    return switch (source) {
      Car car => toCarDto(car),
      Truck truck => toTruckDto(truck),
    };
  }""",
  contains: true,
)
@Mapper()
abstract class SealedVehicleMapper {
  @SubclassMapping(source: Car, target: CarDto)
  @SubclassMapping(source: Truck, target: TruckDto)
  VehicleDto toVehicleDto(Vehicle source);
  CarDto toCarDto(Car source);
  TruckDto toTruckDto(Truck source);
}

// ---- Case 3: Sealed source, PARTIAL coverage — wildcard MUST still be emitted ----
// Sealed class has subtypes Car and Truck; only Car is mapped.

class PartialVehicleDto {
  const PartialVehicleDto();
}

class PartialCarDto extends PartialVehicleDto {
  final String make;
  const PartialCarDto({required this.make});
}

@ShouldGenerate(
  r"""PartialVehicleDto toDto(Vehicle source) {
    return switch (source) {
      Car car => toPartialCarDto(car),
      _ => throw ArgumentError('Unexpected subtype: ${source.runtimeType}'),
    };
  }""",
  contains: true,
)
@Mapper()
abstract class SealedPartialMapper {
  @SubclassMapping(source: Car, target: PartialCarDto)
  PartialVehicleDto toDto(Vehicle source);
  PartialCarDto toPartialCarDto(Car source);
}

// ---- Case 4: GQL-style long type name — bound variable must be valid identifier ----
// The $ characters in the type name must not produce invalid variable names.
// The parameterName getter on DartTypeExtension converts displayString via
// toSnakeCase().toCamelCase(lower: true); $ is handled as a word boundary.

class CreateTodoBase {
  const CreateTodoBase();
}

// ignore: camel_case_types
class Mutation$CreateTodo$createTodoOfMine$data$$ProductTemplateDto
    extends CreateTodoBase {
  final String id;
  // ignore: non_constant_identifier_names
  const Mutation$CreateTodo$createTodoOfMine$data$$ProductTemplateDto({
    required this.id,
  });
}

class CreateTodoOutput {
  const CreateTodoOutput();
}

class ProductTemplateDtoOutput extends CreateTodoOutput {
  final String id;
  const ProductTemplateDtoOutput({required this.id});
}

// The exact bound variable name depends on how DartTypeExtension.parameterName
// handles $ in the type name. The test asserts only that:
// 1. The switch arm starts with the full type name
// 2. A wildcard fallthrough is present (non-sealed source)
// 3. The delegate call toProductTemplateDtoOutput(...) is present
@ShouldGenerate(
  'Mutation\$CreateTodo\$createTodoOfMine\$data\$\$ProductTemplateDto',
  contains: true,
)
@ShouldGenerate(
  'toProductTemplateDtoOutput(',
  contains: true,
)
@ShouldGenerate(
  r"throw ArgumentError('Unexpected subtype: ${source.runtimeType}')",
  contains: true,
)
@Mapper()
abstract class GqlStyleMapper {
  @SubclassMapping(
    source: Mutation$CreateTodo$createTodoOfMine$data$$ProductTemplateDto,
    target: ProductTemplateDtoOutput,
  )
  CreateTodoOutput toOutput(CreateTodoBase source);
  ProductTemplateDtoOutput toProductTemplateDtoOutput(
    // ignore: non_constant_identifier_names
    Mutation$CreateTodo$createTodoOfMine$data$$ProductTemplateDto source,
  );
}
