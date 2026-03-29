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

// Golden test source for D-06 error: missing delegate method.
// IMPORTANT: @ShouldThrow string is a placeholder — update after Plan 02
// runs the generator and the exact error message is confirmed.

import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

class Pet {}

class Dog extends Pet {}

class PetDto {}

class DogDto {}

// No toDogDto(Dog) method exists on this mapper → generator must throw.
@ShouldThrow(
  'No mapping method found for @SubclassMapping(source: Dog, target: DogDto). '
  'Add a method with signature: DogDto method(Dog source).',
)
@SubclassMapping(source: Dog, target: DogDto)
@Mapper()
abstract class MissingDelegateMapper {
  PetDto toPetDto(Pet source);
  // DogDto toDogDto(Dog source);  ← intentionally absent
}
