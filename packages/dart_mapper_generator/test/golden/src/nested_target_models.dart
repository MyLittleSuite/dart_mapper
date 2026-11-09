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

const _ntvDefaultCity = 'n/a';

/// An optional positional parameter whose default is a private constant.
class NtvSlotAddress {
  final String street;
  final String city;
  final String? zip;

  const NtvSlotAddress(this.street, [this.city = _ntvDefaultCity, this.zip]);
}

class NtvSlotContact {
  final String name;
  final NtvSlotAddress address;

  const NtvSlotContact({required this.name, required this.address});
}

/// Optional positional parameters whose defaults are non-finite doubles.
class NtvNonFiniteAddress {
  final String street;
  final double max;
  final double min;
  final double none;
  final String? zip;

  const NtvNonFiniteAddress(
    this.street, [
    this.max = double.infinity,
    this.min = double.negativeInfinity,
    this.none = double.nan,
    this.zip,
  ]);
}

class NtvNonFiniteContact {
  final String name;
  final NtvNonFiniteAddress address;

  const NtvNonFiniteContact({required this.name, required this.address});
}

class NtvTag {
  const NtvTag();
}

/// An optional positional parameter whose default is not a literal.
class NtvObjectSlotAddress {
  final String street;
  final NtvTag tag;
  final String? zip;

  const NtvObjectSlotAddress(this.street,
      [this.tag = const NtvTag(), this.zip]);
}

class NtvObjectSlotContact {
  final String name;
  final NtvObjectSlotAddress address;

  const NtvObjectSlotContact({required this.name, required this.address});
}
