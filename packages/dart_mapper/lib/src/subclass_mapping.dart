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

/// Instructs the generator to produce a runtime-type dispatch body for the
/// annotated dispatch method. Stacked on the method (not the mapper class).
///
/// For each [SubclassMapping] annotation, the generator locates the existing
/// mapping method on the mapper whose signature is `target method(source)` and
/// emits a switch arm `SourceType var => delegateMethod(var)`.
///
/// Example:
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
class SubclassMapping {
  /// The source subtype to match at runtime.
  final Type source;

  /// The target type to produce for this subtype.
  final Type target;

  const SubclassMapping({required this.source, required this.target});
}
