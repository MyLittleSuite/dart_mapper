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

part 'collections.g.dart';

class CustomObjectSource {
  final String name;
  final int age;

  const CustomObjectSource(
    this.name, {
    required this.age,
  });
}

class CustomObjectTarget {
  final String name;
  final int age;

  const CustomObjectTarget(
    this.name, {
    required this.age,
  });
}

class Source {
  final List<int> integers;
  final List<String> strings;
  final Set<int> setIntegers;
  final Set<String> setStrings;
  //final Map<int, String> mapIntegersToStrings;
  final Iterable<int> iterableIntegers;

  final List<CustomObjectSource> customObjectList;
  final Set<CustomObjectSource> customObjectSet;
  //final Map<int, CustomObjectSource> customObjectMap;
  final Iterable<CustomObjectSource> customObjectIterable;

  Source({
    required this.integers,
    required this.strings,
    required this.setIntegers,
    required this.setStrings,
    //required this.mapIntegersToStrings,
    required this.customObjectList,
    required this.customObjectSet,
    //required this.customObjectMap,
    required this.iterableIntegers,
    required this.customObjectIterable,
  });
}

class Target {
  final List<int> integers;
  final List<String> strings;
  final Set<int> setIntegers;
  final Set<String> setStrings;
  //final Map<int, String> mapIntegersToStrings;
  final Iterable<int> iterableIntegers;

  final List<CustomObjectTarget> customObjectList;
  final Set<CustomObjectTarget> customObjectSet;
  //final Map<int, CustomObjectTarget> customObjectMap;
  final Iterable<CustomObjectTarget> customObjectIterable;

  Target({
    required this.integers,
    required this.strings,
    required this.setIntegers,
    required this.setStrings,
    //required this.mapIntegersToStrings,
    required this.customObjectList,
    required this.customObjectSet,
    //required this.customObjectMap,
    required this.iterableIntegers,
    required this.customObjectIterable,
  });
}

@Mapper()
abstract class ListMapper {
  Target toTarget(Source source);
}
