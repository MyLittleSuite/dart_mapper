/*
 * Copyright (c) 2026 MyLittleSuite
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

// Golden test source for class -> Map mapping (MappingBehavior.toMap) of
// built_value sources: the keys are the abstract getters, built collections
// are emitted as plain collections.
//
// The `_$...` implementations are not generated here: the generator only
// needs the `Built<T, TBuilder>` shape of the classes.

// ignore_for_file: depend_on_referenced_packages

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

enum BuiltPriority { low, high }

abstract class BuiltStep implements Built<BuiltStep, BuiltStepBuilder> {
  String get label;
}

abstract class BuiltStepBuilder
    implements Builder<BuiltStep, BuiltStepBuilder> {
  String? label;
}

abstract class BuiltTask implements Built<BuiltTask, BuiltTaskBuilder> {
  String get title;

  int? get estimate;

  BuiltPriority get priority;

  BuiltList<String> get tags;

  BuiltSet<BuiltPriority> get priorities;

  BuiltList<BuiltStep> get steps;

  BuiltMap<String, BuiltStep> get stepsByName;

  BuiltStep? get firstStep;

  // Computed getters are not keys unless they are explicitly mapped.
  String get summary => title.toUpperCase();
}

abstract class BuiltTaskBuilder
    implements Builder<BuiltTask, BuiltTaskBuilder> {
  String? title;
}

@ShouldGenerate(
  r'''Map<String, dynamic> toMap(BuiltTask task) {
    return {
      'title': task.title,
      'estimate': task.estimate,
      'priority': task.priority.name,
      'tags': task.tags.toList(),
      'priorities': task.priorities.map((item) => item.name).toList(),
      'steps': task.steps
          .map((item) => _mapBuiltStepToMapOfStringAnddynamic(item))
          .toList(),
      'stepsByName': task.stepsByName.toMap().map(
        (key, value) =>
            MapEntry(key, _mapBuiltStepToMapOfStringAnddynamic(value)),
      ),
      'firstStep': task.firstStep != null
          ? _mapBuiltStepToMapOfStringAnddynamic(task.firstStep!)
          : null,
    };
  }''',
  contains: true,
)
@ShouldGenerate(
  r'''Map<String, dynamic> _mapBuiltStepToMapOfStringAnddynamic(
    BuiltStep builtStep,
  ) {
    return {'label': builtStep.label};
  }''',
  contains: true,
)
@Mapper()
abstract class BuiltToMapMapper {
  Map<String, dynamic> toMap(BuiltTask task);
}

@ShouldGenerate(
  r'''return {'title': task.title, 'summary': task.summary};''',
  contains: true,
)
@Mapper()
abstract class BuiltToMapComputedMapper {
  @Mapping(source: 'summary', target: 'summary')
  @Mapping(target: 'estimate', ignore: true)
  @Mapping(target: 'priority', ignore: true)
  @Mapping(target: 'tags', ignore: true)
  @Mapping(target: 'priorities', ignore: true)
  @Mapping(target: 'steps', ignore: true)
  @Mapping(target: 'stepsByName', ignore: true)
  @Mapping(target: 'firstStep', ignore: true)
  Map<String, dynamic> toMap(BuiltTask task);
}
