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
import 'package:dart_mapper_example/built_value/models/alert_info.dart'
    as models;
import 'package:dart_mapper_example/built_value/models/built_enum.dart';
import 'package:dart_mapper_example/built_value/models/review.dart';
import 'package:dart_mapper_example/built_value/models/review_dto.dart';
import 'package:dart_mapper_example/built_value/models/user.dart';
import 'package:dart_mapper_example/built_value/models/user_dto.dart';
import 'package:dart_mapper_example/built_value/models/vanilla_enum.dart';

part 'built_value_mapper.g.dart';

@Mapper()
abstract class AlertTypeMapper {
  const AlertTypeMapper();

  @ValueMapping(target: 'missingPhoneNumber', source: '1')
  @ValueMapping(target: 'missingEmail', source: '2')
  @ValueMapping(target: 'goToAppointment', source: '3')
  @ValueMapping(target: 'goToAppointment', source: '4')
  @ValueMapping(target: 'goToAppointment', source: '5')
  AlertType? fromRaw(int? raw);

  @ValueMapping(target: '1', source: 'missingPhoneNumber')
  @ValueMapping(target: '2', source: 'missingEmail')
  int? toRaw(AlertType? raw);
}

@Mapper()
abstract class BuiltEnumMapper {
  const BuiltEnumMapper();

  VanillaEnum toVanillaEnum(BuiltEnum value);

  VanillaEnum? toNullableVanillaEnum(BuiltEnum value);

  BuiltEnum toBuiltEnum(VanillaEnum value);

  BuiltEnum? toNullableBuiltEnum(VanillaEnum value);

  BuiltEnum toBuiltEnumFromString(String value);

  BuiltEnum? toNullableBuiltEnumFromString(String value);

  String toStringFromBuiltEnum(BuiltEnum value);

  String? toNullableStringFromBuiltEnum(BuiltEnum value);
}

@Mapper(uses: {AlertTypeMapper})
abstract class BuiltValueMapper {
  const BuiltValueMapper();

  Review toReview(ReviewDTO reviewDto);

  ReviewDTO toReviewDTO(Review review);

  @Mapping(target: 'type', source: 'actionType')
  Alert toAlert(models.AlertInfo alertInfo);

  @InheritConfiguration()
  Alert toAlertDirect(models.AlertInfo alertInfo);

  @InheritInverseConfiguration()
  models.AlertInfo toAlertInfo(Alert alert);
}

@Mapper()
abstract class UserMapper {
  const UserMapper();

  UserDTO toUserDTO(User user);
}

@Mapper(uses: {UserMapper})
abstract class BuiltValueMapperWithUses {
  const BuiltValueMapperWithUses();

  ReviewDTO toReviewDTO(Review review);
}

UserDTOBuilder? _mapUserManually(dynamic user) {
  return UserDTOBuilder()..replace(UserDTO((b) => b..id = user.id));
}

ListBuilder<UserDTO>? _mapUserManuallyList(dynamic user) {
  return ListBuilder([UserDTO((b) => b..id = user.id)]);
}

SetBuilder<UserDTO>? _mapUserManuallySet(dynamic user) {
  return SetBuilder([UserDTO((b) => b..id = user.id)]);
}

@Mapper()
abstract class BuiltValueMapperWithCallable {
  const BuiltValueMapperWithCallable();

  @Mapping(target: 'user', callable: _mapUserManually)
  @Mapping(target: 'thumbsUp', callable: _mapUserManuallyList)
  @Mapping(target: 'thumbsDown', callable: _mapUserManuallySet)
  ReviewDTO toReviewDTO(Review review);
}
