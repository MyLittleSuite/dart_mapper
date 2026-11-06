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

// Golden test source for class <-> Map mapping combined in one mapper:
// cross-direction inherited configuration and shared private helpers.

import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

// ----- Shared models -----

enum RtRole { admin, member }

class RtAddress {
  final String street;
  final String? city;

  const RtAddress({required this.street, this.city});
}

class RtItem {
  final String id;
  final String title;

  const RtItem({required this.id, required this.title});
}

class RtProfile {
  final String id;
  final String fullName;
  final RtRole role;
  final RtAddress address;
  final Map<String, RtAddress> addressesByLabel;

  const RtProfile({
    required this.id,
    required this.fullName,
    required this.role,
    required this.address,
    required this.addressesByLabel,
  });
}

class RtOrder {
  final String id;
  final RtAddress shipping;
  final List<RtAddress> history;

  const RtOrder({
    required this.id,
    required this.shipping,
    required this.history,
  });
}

// ----- (a) toMap inherits the inverse of fromMap -----

@ShouldGenerate(
  r'''class RtInverseFromMapMapperImpl extends RtInverseFromMapMapper {
  RtInverseFromMapMapperImpl();

  @override
  RtItem fromMap(Map<String, dynamic> map) {
    return RtItem(id: map['uid'] as String, title: map['heading'] as String);
  }

  @override
  Map<String, dynamic> toMap(RtItem item) {
    return {'uid': item.id, 'heading': item.title};
  }
}''',
  contains: true,
)
@Mapper()
abstract class RtInverseFromMapMapper {
  @Mapping(source: 'uid', target: 'id')
  @Mapping(source: 'heading', target: 'title')
  RtItem fromMap(Map<String, dynamic> map);

  @InheritInverseConfiguration()
  Map<String, dynamic> toMap(RtItem item);
}

// ----- (b) round trip: nested class, Map<String, Nested>, enum, renamed keys -----

@ShouldGenerate(
  r'''class RtRoundTripMapperImpl extends RtRoundTripMapper {
  RtRoundTripMapperImpl();

  @override
  Map<String, dynamic> toMap(RtProfile profile) {
    return {
      'uid': profile.id,
      'name': profile.fullName,
      'role': profile.role.name,
      'address': _mapRtAddressToMap(profile.address),
      'addresses': profile.addressesByLabel.map(
        (key, value) => MapEntry(key, _mapRtAddressToMap(value)),
      ),
    };
  }

  @override
  RtProfile fromMap(Map<String, dynamic> map) {
    return RtProfile(
      id: map['uid'] as String,
      fullName: map['name'] as String,
      role: RtRole.values.byName(map['role'] as String),
      address: _mapMapToRtAddress(
        Map<String, dynamic>.from(map['address'] as Map),
      ),
      addressesByLabel: (map['addresses'] as Map).map<String, RtAddress>(
        (key, value) => MapEntry(
          key as String,
          _mapMapToRtAddress(Map<String, dynamic>.from(value as Map)),
        ),
      ),
    );
  }

  Map<String, dynamic> _mapRtAddressToMap(RtAddress rtAddress) {
    return {'street': rtAddress.street, 'city': rtAddress.city};
  }

  RtAddress _mapMapToRtAddress(Map<String, dynamic> map) {
    return RtAddress(
      street: map['street'] as String,
      city: map['city'] as String?,
    );
  }
}''',
  contains: true,
)
@Mapper()
abstract class RtRoundTripMapper {
  @Mapping(source: 'id', target: 'uid')
  @Mapping(source: 'fullName', target: 'name')
  @Mapping(source: 'addressesByLabel', target: 'addresses')
  Map<String, dynamic> toMap(RtProfile profile);

  @InheritInverseConfiguration()
  RtProfile fromMap(Map<String, dynamic> map);
}

// ----- (c) both directions, several methods sharing nested helpers -----

@ShouldGenerate(
  r'''class RtSharedHelpersMapperImpl extends RtSharedHelpersMapper {
  RtSharedHelpersMapperImpl();

  @override
  Map<String, dynamic> orderToMap(RtOrder order) {
    return {
      'id': order.id,
      'shipping': _mapRtAddressToMap(order.shipping),
      'history': order.history.map((item) => _mapRtAddressToMap(item)).toList(),
    };
  }

  @override
  Map<String, dynamic> profileToMap(RtProfile profile) {
    return {
      'id': profile.id,
      'fullName': profile.fullName,
      'role': profile.role.name,
      'address': _mapRtAddressToMap(profile.address),
      'addressesByLabel': profile.addressesByLabel.map(
        (key, value) => MapEntry(key, _mapRtAddressToMap(value)),
      ),
    };
  }

  @override
  RtOrder orderFromMap(Map<String, dynamic> map) {
    return RtOrder(
      id: map['id'] as String,
      shipping: _mapMapToRtAddress(
        Map<String, dynamic>.from(map['shipping'] as Map),
      ),
      history: (map['history'] as Iterable)
          .map<RtAddress>(
            (e) => _mapMapToRtAddress(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
    );
  }

  @override
  RtProfile profileFromMap(Map<String, dynamic> map) {
    return RtProfile(
      id: map['id'] as String,
      fullName: map['fullName'] as String,
      role: RtRole.values.byName(map['role'] as String),
      address: _mapMapToRtAddress(
        Map<String, dynamic>.from(map['address'] as Map),
      ),
      addressesByLabel: (map['addressesByLabel'] as Map).map<String, RtAddress>(
        (key, value) => MapEntry(
          key as String,
          _mapMapToRtAddress(Map<String, dynamic>.from(value as Map)),
        ),
      ),
    );
  }

  Map<String, dynamic> _mapRtAddressToMap(RtAddress rtAddress) {
    return {'street': rtAddress.street, 'city': rtAddress.city};
  }

  RtAddress _mapMapToRtAddress(Map<String, dynamic> map) {
    return RtAddress(
      street: map['street'] as String,
      city: map['city'] as String?,
    );
  }
}''',
  contains: true,
)
@Mapper()
abstract class RtSharedHelpersMapper {
  Map<String, dynamic> orderToMap(RtOrder order);

  Map<String, dynamic> profileToMap(RtProfile profile);

  RtOrder orderFromMap(Map<String, dynamic> map);

  RtProfile profileFromMap(Map<String, dynamic> map);
}
