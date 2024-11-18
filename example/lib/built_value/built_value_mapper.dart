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

import 'package:built_collection/built_collection.dart';
import 'package:dart_mapper/dart_mapper.dart';
import 'package:dart_mapper_example/built_value/models/alert.dart';
import 'package:dart_mapper_example/built_value/models/alert_info.dart';
import 'package:dart_mapper_example/built_value/models/review.dart';
import 'package:dart_mapper_example/built_value/models/review_dto.dart';
import 'package:dart_mapper_example/built_value/models/user.dart';
import 'package:dart_mapper_example/built_value/models/user_dto.dart';

part 'built_value_mapper.g.dart';

@Mapper()
abstract class BuiltValueMapper {
  Review toReview(ReviewDTO reviewDto);

  ReviewDTO toReviewDTO(Review review);

  Alert toAlert(AlertInfo alertInfo);

  AlertInfo toAlertInfo(Alert alert);
}
