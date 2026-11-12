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

/// Instructs the generator to produce a dispatch body for the annotated
/// method. Stacked on the method (not the mapper class).
///
/// For each [SubclassMapping] annotation, the generator locates the existing
/// mapping method on the mapper whose signature is `target method(source)` and
/// emits a switch arm delegating to it.
///
/// ## Class → class
///
/// Dispatches on the runtime type of the source:
///
/// ```dart
/// @Mapper()
/// abstract class AnimalMapper {
///   @SubclassMapping(source: Dog, target: DogDto)
///   @SubclassMapping(source: Cat, target: CatDto)
///   AnimalDto toAnimalDto(Animal source);
///   DogDto toDogDto(Dog source);
///   CatDto toCatDto(Cat source);
/// }
/// ```
///
/// ## Map ↔ class hierarchy
///
/// When one side of the method is a `Map`, the concrete subclass is selected
/// by a discriminator: the key is declared once on the method with
/// [DiscriminatorKey], the value per subclass with [discriminatorValue].
/// The side that is a `Map` is omitted: it is the `Map` type of the method.
///
/// ```dart
/// @Mapper()
/// abstract class ShapeMapper {
///   @DiscriminatorKey('type')
///   @SubclassMapping(target: Circle, discriminatorValue: 'circle')
///   @SubclassMapping(target: Rect, discriminatorValue: 'rect')
///   Shape fromMap(Map<String, dynamic> map);
///
///   @DiscriminatorKey('type')
///   @SubclassMapping(source: Circle, discriminatorValue: 'circle')
///   @SubclassMapping(source: Rect, discriminatorValue: 'rect')
///   Map<String, dynamic> toMap(Shape shape);
///
///   Circle toCircle(Map<String, dynamic> map);
///   Rect toRect(Map<String, dynamic> map);
///   Map<String, dynamic> fromCircle(Circle circle);
///   Map<String, dynamic> fromRect(Rect rect);
/// }
/// ```
class SubclassMapping {
  /// The source subtype to match at runtime.
  ///
  /// Omitted when the source of the method is a `Map`.
  final Type? source;

  /// The target type to produce for this subtype.
  ///
  /// Omitted when the target of the method is a `Map`.
  final Type? target;

  /// The value of the [DiscriminatorKey] entry identifying this subclass in
  /// the `Map`. Required when one side of the method is a `Map`, forbidden
  /// otherwise.
  ///
  /// Supported values: `String`, `int`, `double`, `num`, `bool` and Dart
  /// enum constants (stored by name). All the [SubclassMapping]s of a method
  /// must use values of the same type.
  final Object? discriminatorValue;

  const SubclassMapping({
    this.source,
    this.target,
    this.discriminatorValue,
  });
}
