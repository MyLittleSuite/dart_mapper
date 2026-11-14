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

// Library resolved by method_signature_lookup_test.dart.

class Ordering {
  const Ordering();
}

class Other {
  const Other();
}

class Holder {
  const Holder();
}

/// A used mapper.
abstract class UsedMapper {
  Ordering from(String? field, bool descending);
  Ordering strict(String field, bool descending);
  Ordering fromNum(num value, bool descending);
  Other other(String? field, bool descending);
  Ordering single(String field);
  Ordering singleAlt(String field);
}

/// A second used mapper with the same signature as [UsedMapper.from].
abstract class DuplicateMapper {
  Ordering from(String? field, bool descending);
}

/// The mapper being generated.
abstract class OwnMapper {
  Ordering fromOwn(String? field, bool descending);
  Holder toHolder(String? field, bool descending);
}
