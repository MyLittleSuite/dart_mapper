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

/// A function that takes a source object and returns a mapped value.
typedef MappingCallable = Function;

class Mapping {
  final String? source;
  final String target;
  final bool ignore;

  /// When true, forces the target field to be non-null during mapping,
  /// even if the source field is nullable.
  final bool forceNonNull;

  /// A function that takes the source object and returns a mapped value.
  /// This parameter delegates you to write the mapping logic manually.
  final MappingCallable? callable;

  /// A default value to use when the source field is null or absent.
  /// Must be a valid Dart expression string (e.g., "'default'", "0", "false").
  final String? defaultValue;

  /// A constant expression to use as the target field value.
  /// Must be a valid Dart constant expression string (e.g., "'constant'", "42").
  /// Cannot be combined with source, defaultValue, or callable.
  final String? constant;

  /// A raw Dart expression emitted verbatim as the target field value.
  /// The expression has access to source method parameters by their declared names.
  /// Single-source: use `source`. Multi-source: use parameter names as declared.
  /// Cannot be combined with source, defaultValue, constant, or callable.
  final String? expression;

  /// A raw Dart boolean expression. When true, the field is mapped normally.
  /// When false, falls back to defaultValue (if set) or null (if target is nullable).
  /// Cannot be combined with constant or callable.
  final String? conditionExpression;

  const Mapping({
    required this.target,
    this.source,
    this.ignore = false,
    this.forceNonNull = false,
    this.callable,
    this.defaultValue,
    this.constant,
    this.expression,
    this.conditionExpression,
  });
}
