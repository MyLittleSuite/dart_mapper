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

// Models of other libraries, used to check that the classes a nested target
// builds can be reached by the mapper.

/// A nested class whose only constructor is private to this library.
class NtvPrivateAddress {
  final String street;

  NtvPrivateAddress._(this.street);
}

class NtvPrivateContact {
  final String name;
  final NtvPrivateAddress address;

  const NtvPrivateContact({required this.name, required this.address});
}

/// A nested class the mapper does not import (it hides it).
class NtvHiddenAddress {
  final String street;

  const NtvHiddenAddress({required this.street});
}

class NtvHiddenContact {
  final String name;
  final NtvHiddenAddress address;

  const NtvHiddenContact({required this.name, required this.address});
}
