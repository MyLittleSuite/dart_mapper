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
import 'package:source_gen_test/source_gen_test.dart';

import '../helpers/generator_factory.dart';

void main() async {
  final generator = createTestGenerator();
  initializeBuildLogTracking();

  // Group: Basic mapping
  final basicReader = await initializeLibraryReaderForDirectory(
    'test/golden/src',
    'basic_test_src.dart',
  );
  testAnnotatedElements<Mapper>(basicReader, generator);

  // Group: Collections
  final collectionsReader = await initializeLibraryReaderForDirectory(
    'test/golden/src',
    'collections_test_src.dart',
  );
  testAnnotatedElements<Mapper>(collectionsReader, generator);

  // Group: Nested object mapping
  final nestedReader = await initializeLibraryReaderForDirectory(
    'test/golden/src',
    'nested_test_src.dart',
  );
  testAnnotatedElements<Mapper>(nestedReader, generator);

  // Group: Nullability
  final nullabilityReader = await initializeLibraryReaderForDirectory(
    'test/golden/src',
    'nullability_test_src.dart',
  );
  testAnnotatedElements<Mapper>(nullabilityReader, generator);

  // Group: Force non-null
  final forceNonNullReader = await initializeLibraryReaderForDirectory(
    'test/golden/src',
    'force_non_null_test_src.dart',
  );
  testAnnotatedElements<Mapper>(forceNonNullReader, generator);

  // Group: Callable
  final callableReader = await initializeLibraryReaderForDirectory(
    'test/golden/src',
    'callable_test_src.dart',
  );
  testAnnotatedElements<Mapper>(callableReader, generator);

  // Group: Transformation (field renaming)
  final transformationReader = await initializeLibraryReaderForDirectory(
    'test/golden/src',
    'transformation_test_src.dart',
  );
  testAnnotatedElements<Mapper>(transformationReader, generator);

  // Group: Recursion
  final recursionReader = await initializeLibraryReaderForDirectory(
    'test/golden/src',
    'recursion_test_src.dart',
  );
  testAnnotatedElements<Mapper>(recursionReader, generator);

  // Group: Multiple init
  final multipleInitReader = await initializeLibraryReaderForDirectory(
    'test/golden/src',
    'multiple_init_test_src.dart',
  );
  testAnnotatedElements<Mapper>(multipleInitReader, generator);

  // Group: Mixed
  final mixedReader = await initializeLibraryReaderForDirectory(
    'test/golden/src',
    'mixed_test_src.dart',
  );
  testAnnotatedElements<Mapper>(mixedReader, generator);

  // Group: Import aliases (QA-05)
  final aliasReader = await initializeLibraryReaderForDirectory(
    'test/golden/src',
    'alias_test_src.dart',
  );
  testAnnotatedElements<Mapper>(aliasReader, generator);

  // Group: Enum mapping
  final enumsReader = await initializeLibraryReaderForDirectory(
    'test/golden/src',
    'enums_test_src.dart',
  );
  testAnnotatedElements<Mapper>(enumsReader, generator);

  // Group: Freezed-like mapping
  final freezedReader = await initializeLibraryReaderForDirectory(
    'test/golden/src',
    'freezed_test_src.dart',
  );
  testAnnotatedElements<Mapper>(freezedReader, generator);

  // Group: BuiltValue-like mapping
  final builtValueReader = await initializeLibraryReaderForDirectory(
    'test/golden/src',
    'built_value_test_src.dart',
  );
  testAnnotatedElements<Mapper>(builtValueReader, generator);

  // Group: Enum error (ENUM-03)
  final enumErrorReader = await initializeLibraryReaderForDirectory(
    'test/golden/src',
    'enum_error_test_src.dart',
  );
  testAnnotatedElements<Mapper>(enumErrorReader, generator);

  // Group: Enum defaults (ENUM-01, ENUM-02)
  final enumDefaultsReader = await initializeLibraryReaderForDirectory(
    'test/golden/src',
    'enum_defaults_test_src.dart',
  );
  testAnnotatedElements<Mapper>(enumDefaultsReader, generator);

  // Group: Map field mapping (COLL-01)
  final mapReader = await initializeLibraryReaderForDirectory(
    'test/golden/src',
    'map_test_src.dart',
  );
  testAnnotatedElements<Mapper>(mapReader, generator);

  // Group: Dynamic field mapping (COLL-03)
  final dynamicReader = await initializeLibraryReaderForDirectory(
    'test/golden/src',
    'dynamic_test_src.dart',
  );
  testAnnotatedElements<Mapper>(dynamicReader, generator);

  // Group: Generic type resolution (COLL-04)
  final genericsReader = await initializeLibraryReaderForDirectory(
    'test/golden/src',
    'generics_test_src.dart',
  );
  testAnnotatedElements<Mapper>(genericsReader, generator);

  // Group: Multi-source mapping (SRC-01, SRC-02)
  final multiSourceReader = await initializeLibraryReaderForDirectory(
    'test/golden/src',
    'multi_source_test_src.dart',
  );
  testAnnotatedElements<Mapper>(multiSourceReader, generator);

  // Group: Dot notation (SRC-03, SRC-04)
  final dotNotationReader = await initializeLibraryReaderForDirectory(
    'test/golden/src',
    'dot_notation_test_src.dart',
  );
  testAnnotatedElements<Mapper>(dotNotationReader, generator);

  // Group: Default/constant values (DEF-01, DEF-02)
  final defaultsReader = await initializeLibraryReaderForDirectory(
    'test/golden/src',
    'defaults_test_src.dart',
  );
  testAnnotatedElements<Mapper>(defaultsReader, generator);

  // Group: Multi-source error (D-02)
  final multiSourceErrorReader = await initializeLibraryReaderForDirectory(
    'test/golden/src',
    'multi_source_error_test_src.dart',
  );
  testAnnotatedElements<Mapper>(multiSourceErrorReader, generator);

  // Group: Defaults error (D-13)
  final defaultsErrorReader = await initializeLibraryReaderForDirectory(
    'test/golden/src',
    'defaults_error_test_src.dart',
  );
  testAnnotatedElements<Mapper>(defaultsErrorReader, generator);
}
