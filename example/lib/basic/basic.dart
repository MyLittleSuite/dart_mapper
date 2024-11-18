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

part 'basic.g.dart';

enum BasicEnum { first, second, third, fifth }

enum AnotherBasicEnum { first, second, third, fourth }

class BasicObject {
  final String name;
  final int age;
  final BasicEnum type;
  final List<BasicEnum> types;
  final DateTime dateTime;

  BasicObject(
    this.name,
    this.age,
    this.type,
    this.types,
    this.dateTime,
  );
}

class AnotherBasicObject {
  final String name;
  final int age;
  final AnotherBasicEnum type;
  final List<AnotherBasicEnum> types;
  final DateTime dateTime;

  const AnotherBasicObject(
    this.name,
    this.age,
    this.type,
    this.types,
    this.dateTime,
  );
}

@Mapper()
abstract class BasicMapper {
  AnotherBasicObject toAnotherBasicObject(BasicObject basicObject);

  BasicObject toBasicObject(AnotherBasicObject anotherBasicObject);
}
