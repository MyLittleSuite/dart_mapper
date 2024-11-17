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

part 'nested.g.dart';

class SourceA {
  final String property;
  final SourceB b;

  SourceA(this.property, this.b);
}

class SourceB {
  final String property;
  final SourceC c;

  SourceB(this.property, this.c);
}

class SourceC {
  final String property;

  SourceC(this.property);
}

class TargetA {
  final String property;
  final TargetB b;

  TargetA(this.property, this.b);
}

class TargetB {
  final String property;
  final TargetC c;

  TargetB(this.property, this.c);
}

class TargetC {
  final String property;

  TargetC(this.property);
}

@Mapper(uses: {CMapper})
abstract class AMapper {
  TargetA toTargetA(SourceA model);

  SourceA toSourceA(TargetA model);
}

@Mapper()
abstract class CMapper {
  TargetC toTargetC(SourceC model);

  SourceC toSourceC(TargetC model);
}
