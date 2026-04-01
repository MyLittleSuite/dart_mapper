import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

class Wrapper<T> {
  final T value;
  final String label;

  Wrapper(this.value, this.label);
}

class TargetWrapper {
  final String value;
  final String label;

  TargetWrapper(this.value, this.label);
}

// Generic type parameter T resolves to String at the method level,
// so value: source.value should use direct assignment.
// Note: Unresolvable generic types (Wrapper<T> without concrete substitution)
// cannot occur in valid Dart code -- the compiler prevents it.
@ShouldGenerate(
  'TargetWrapper(source.value, source.label)',
  contains: true,
)
@Mapper()
abstract class GenericMapper {
  TargetWrapper convert(Wrapper<String> source);
}

// --- Generic collection mapping ---

class TodoDTO {
  final String title;
  final bool done;
  TodoDTO(this.title, this.done);
}

class Todo {
  final String title;
  final bool done;
  Todo(this.title, this.done);
}

class PaginationDTO<T> {
  final List<T> items;
  final int page;
  final int total;
  PaginationDTO(this.items, this.page, this.total);
}

class Pagination<T> {
  final List<T> items;
  final int page;
  final int total;
  Pagination(this.items, this.page, this.total);
}

// List<T> resolves to List<TodoDTO>/List<Todo> at the call site.
// items field must map each element through _mapTodoDTOToTodo, not copy as-is.
@ShouldGenerate(
  '.map((item) => _mapTodoDTOToTodo(item))',
  contains: true,
)
@Mapper()
abstract class PaginationMapper {
  Pagination<Todo> convert(PaginationDTO<TodoDTO> source);
  Todo _mapTodoDTOToTodo(TodoDTO source);
}

// --- Generic single-T field mapping ---

class BoxDTO<T> {
  final T content;
  final String tag;
  BoxDTO(this.content, this.tag);
}

class Box {
  final Todo content;
  final String tag;
  Box(this.content, this.tag);
}

// T resolves to TodoDTO at call site; content must pass through a converter.
@ShouldGenerate(
  '_mapTodoDTOToTodo2(source.content)',
  contains: true,
)
@Mapper()
abstract class BoxMapper {
  Box convert(BoxDTO<TodoDTO> source);
  Todo _mapTodoDTOToTodo2(TodoDTO source);
}
