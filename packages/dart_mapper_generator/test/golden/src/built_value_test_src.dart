/*
 * Copyright (c) 2024 MyLittleSuite
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

// Golden test source for built_value-like class mapping.
//
// Since source_gen_test cannot run built_value_generator first, and
// MappingBehaviorAnalyzer detects built_value classes by checking for
// `Built<T, TBuilder>` supertypes (which cannot be simulated without
// the real package infrastructure), these classes test the generator's
// standard mapping behavior for builder-pattern class shapes.
//
// The generator will treat these as MappingBehavior.standard because
// they lack the `Built<T, TBuilder>` supertype. This test verifies the
// generator does not crash on classes with builder-pattern constructors
// and correctly maps their fields.
//
// Limitation: Real built_value detection cannot be triggered in
// source_gen_test without the built_value package as a dependency.
// The example .g.dart files serve as the ultimate golden reference
// for built_value-specific behavior.

import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

// Tests mapper behavior with built_value-like class shapes.
// These classes use positional and named constructor parameters with
// builder-like patterns, similar to what built_value produces.

class BuiltLikeReview {
  final int id;
  final String body;
  final int rating;

  const BuiltLikeReview({
    required this.id,
    required this.body,
    required this.rating,
  });
}

class BuiltLikeReviewDTO {
  final int id;
  final String body;
  final int rating;

  const BuiltLikeReviewDTO({
    required this.id,
    required this.body,
    required this.rating,
  });
}

class BuiltLikeAlert {
  final int id;
  final String type;

  const BuiltLikeAlert({
    required this.id,
    required this.type,
  });
}

class BuiltLikeAlertInfo {
  final int id;
  final String actionType;

  const BuiltLikeAlertInfo({
    required this.id,
    required this.actionType,
  });
}

@ShouldGenerate(
  r'''id: review.id,''',
  contains: true,
)
@ShouldGenerate(
  r'''body: review.body,''',
  contains: true,
)
@ShouldGenerate(
  r'''rating: review.rating,''',
  contains: true,
)
@ShouldGenerate(
  r'''return BuiltLikeAlert(id: alertInfo.id, type: alertInfo.actionType);''',
  contains: true,
)
@Mapper()
abstract class BuiltLikeMapper {
  BuiltLikeReviewDTO toReviewDTO(BuiltLikeReview review);

  BuiltLikeReview toReview(BuiltLikeReviewDTO reviewDTO);

  @Mapping(target: 'type', source: 'actionType')
  BuiltLikeAlert toAlert(BuiltLikeAlertInfo alertInfo);
}
