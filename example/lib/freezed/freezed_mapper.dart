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

import 'package:dart_mapper/dart_mapper.dart';
import 'package:dart_mapper_example/freezed/dtos/city_dto.dart';
import 'package:dart_mapper_example/freezed/dtos/coord_dto.dart';
import 'package:dart_mapper_example/freezed/models/another_user.dart';
import 'package:dart_mapper_example/freezed/models/city.dart';
import 'package:dart_mapper_example/freezed/models/coord.dart';
import 'package:dart_mapper_example/freezed/models/credentials.dart';
import 'package:dart_mapper_example/freezed/models/user.dart';
import 'package:dart_mapper_example/freezed/models/user_jto.dart';

part 'freezed_mapper.g.dart';

CoordDTO _toCoordDTO(dynamic coord) {
  assert(coord is Coord);

  return CoordDTO(lat: coord.lat, lon: coord.lon);
}

@Mapper()
abstract class FreezedMapper {
  UserJTO toUserJTO(User user);

  User toUser(UserJTO userJTO);

  AnonCredentials toAnonCredentials(Credentials credentials);

  AnonCredentials toAnonFromUser(User user);

  UserCredentials toUserCredentials(User user);

  AnotherUser toAnotherUser(User user);

  User toUserFromAnotherOne(AnotherUser anotherUser);

  City toCity(CityDTO dto);

  CityDTO toCityDTO(City city);

  @Mapping(target: 'coord', callable: _toCoordDTO)
  CityDTO toCityDTOWithCustomCoordinates(City city);
}
