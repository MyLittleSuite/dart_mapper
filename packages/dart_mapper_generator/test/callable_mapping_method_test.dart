/*
 * Copyright (c) 2025 MyLittleSuite
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

import 'package:analyzer/dart/element/element.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/callable_mapping_method.dart';
import 'package:test/fake.dart';
import 'package:test/test.dart';

// Minimal fake ExecutableElement that satisfies only what CallableMappingMethod.from() accesses.
// Unimplemented members throw UnimplementedError — this is intentional for a focused unit test.
class _FakeExecutableElement extends Fake implements ExecutableElement {
  final String? _name;
  final List<FormalParameterElement> _formalParameters;

  _FakeExecutableElement({
    required String? name,
    required List<FormalParameterElement> formalParameters,
  })  : _name = name,
        _formalParameters = formalParameters;

  @override
  String? get name => _name;

  @override
  List<FormalParameterElement> get formalParameters => _formalParameters;
}

void main() {
  group('CallableMappingMethod.from()', () {
    test('throws ArgumentError when formalParameters is empty', () {
      final element = _FakeExecutableElement(
        name: 'myCallable',
        formalParameters: [],
      );

      expect(
        () => CallableMappingMethod.from(element),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('myCallable'),
          ),
        ),
      );
    });
  });
}
