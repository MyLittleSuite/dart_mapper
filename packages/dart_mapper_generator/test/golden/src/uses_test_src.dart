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

// Golden test source for @Mapper(uses: {...}) external mapper injection.
//
// Validates that when a mapper declares `uses: {OtherMapper}`, the generated
// implementation receives the external mapper as a constructor parameter and
// delegates nested object conversion to it.

import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

class UsesInnerSource {
  final String value;

  UsesInnerSource(this.value);
}

class UsesInnerTarget {
  final String value;

  UsesInnerTarget(this.value);
}

class UsesOuterSource {
  final String label;
  final UsesInnerSource item;

  UsesOuterSource(this.label, this.item);
}

class UsesOuterTarget {
  final String label;
  final UsesInnerTarget item;

  UsesOuterTarget(this.label, this.item);
}

// The inner mapper has no `uses` — standard standalone implementation.
@ShouldGenerate(
  r'''class UsesInnerMapperImpl extends UsesInnerMapper''',
  contains: true,
)
@Mapper()
abstract class UsesInnerMapper {
  UsesInnerTarget convert(UsesInnerSource source);
}

// The outer mapper uses UsesInnerMapper for nested field conversion.
// The generated class must accept UsesInnerMapper as a required constructor param
// and delegate inner object conversion to it.
@ShouldGenerate(
  r'''class UsesOuterMapperImpl extends UsesOuterMapper''',
  contains: true,
)
@ShouldGenerate(
  // External mapper injected as a constructor parameter
  r'''UsesOuterMapperImpl({required this.usesInnerMapper})''',
  contains: true,
)
@ShouldGenerate(
  // Field declaration for the injected mapper
  r'''final UsesInnerMapper usesInnerMapper''',
  contains: true,
)
@ShouldGenerate(
  // Delegation to the injected mapper for nested object
  r'''usesInnerMapper.convert(source.item)''',
  contains: true,
)
@Mapper(uses: {UsesInnerMapper})
abstract class UsesOuterMapper {
  UsesOuterTarget convert(UsesOuterSource source);
}

enum TaskStatus { active, inactive, unknown }

class TaskStatusMapper {
  const TaskStatusMapper();

  TaskStatus? fromInt(int? value) => switch (value) {
        1 => TaskStatus.active,
        2 => TaskStatus.inactive,
        _ => null,
      };
}

class TaskDTO {
  final int status;

  const TaskDTO({required this.status});
}

class Task {
  final TaskStatus status;

  const Task({required this.status});
}

@ShouldGenerate(
  // defaultValue must wrap the submapper call, NOT the source field.
  r'''taskStatusMapper.fromInt(dto.status) ?? TaskStatus.unknown''',
  contains: true,
)
@Mapper(uses: {TaskStatusMapper})
abstract class TaskMapper {
  @Mapping(target: 'status', defaultValue: 'TaskStatus.unknown')
  Task fromDTO(TaskDTO dto);
}

// Nullable source variant: source is int?, submapper returns TaskStatus?,
// defaultValue still applies to submapper result.
class TaskDTONullable {
  final int? status;

  const TaskDTONullable({this.status});
}

@ShouldGenerate(
  // Both branches carry the default: source!=null applies it to submapper
  // result; source==null falls through to the default directly.
  r'''dto.status != null
          ? taskStatusMapper.fromInt(dto.status!) ?? TaskStatus.unknown
          : TaskStatus.unknown''',
  contains: true,
)
@Mapper(uses: {TaskStatusMapper})
abstract class TaskNullableSourceMapper {
  @Mapping(target: 'status', defaultValue: 'TaskStatus.unknown')
  Task? fromDTO(TaskDTONullable dto);
}
