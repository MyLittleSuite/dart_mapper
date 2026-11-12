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

// Models of another library than the mapper's, used to check that the
// generator never calls a constructor that is private to them (issue #117).

/// A private constructor declared before a public factory with the same
/// number of parameters.
class CsvPlainTarget {
  const CsvPlainTarget._();

  factory CsvPlainTarget() => const CsvPlainTarget._();
}

/// A Freezed class without fields: `Foo._()` is required to add members, and
/// it has as many parameters as the factory.
abstract class CsvFreezedTarget {
  const CsvFreezedTarget._();

  const factory CsvFreezedTarget() = _CsvFreezedTarget;
}

class _CsvFreezedTarget extends CsvFreezedTarget {
  const _CsvFreezedTarget() : super._();
}

/// A private constructor with fields, declared before a public factory with
/// the same number of parameters.
class CsvFieldTarget {
  final String name;

  const CsvFieldTarget._(this.name);

  factory CsvFieldTarget({required String name}) => CsvFieldTarget._(name);
}

/// A named constructor declared before the unnamed one, with the same number
/// of parameters.
class CsvNamedFirstTarget {
  final String name;

  const CsvNamedFirstTarget.copy(this.name);

  const CsvNamedFirstTarget(this.name);
}

/// A nested class whose private constructor comes first.
class CsvAddress {
  final String street;

  const CsvAddress._(this.street);

  factory CsvAddress({required String street}) => CsvAddress._(street);
}

class CsvContact {
  final String name;
  final CsvAddress address;

  const CsvContact({required this.name, required this.address});
}

/// A class whose only constructor is private to this library.
class CsvPrivateOnlyTarget {
  final String name;

  const CsvPrivateOnlyTarget._(this.name);
}
