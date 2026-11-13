## 1.3.0

- Feature: support for the collections of [fast_immutable_collections](https://pub.dev/packages/fast_immutable_collections): `IList`, `ISet`, `IMap`, `IMapOfSets`, `ListSet` and `ListMap` fields are mapped to and from `dart:core` and built collections, in standard, Freezed and Built Value classes, and in class ↔ `Map` mappings (`IList`, `ISet`, `IMap`). Immutable collections of the same type are shared instead of being copied (#93)
- Feature: a hand-written method converting a whole map (`IMap<K, B> convert(Map<K, A> map)`) is called as it is, as for iterables
- Fix: `BuiltList`, `BuiltSet` and `BuiltMap` targets whose items are converted by a generated method received the builders of the items instead of the items
- Fix: a `BuiltMap` source mapped to a `Map` target is converted with `toMap()`
- Fix: a `BuiltList` / `BuiltSet` target is built according to its own type, not the one of the source (`List` → `BuiltSet`), and the dead `?? []` fallback is no longer generated for non-nullable sources
- Fix: import prefixes are applied in the mappings of Built Value targets
- Fix: `BuiltList`, `BuiltSet` and `BuiltMap` fields of standard and Freezed classes are built (`BuiltList.of(...)`) instead of receiving a `List` or a `Map`
- Fix: the items of the sets of an `IMapOfSets` are converted from and to `Map<K, Set<V>>`, `IMap<K, ISet<V>>`, `ListMap` and `BuiltMap` too, and these targets are constructed instead of receiving the `IMapOfSets`
- Fix: the sets of an `IMapOfSets` are converted to the set type of the target map (`IMap<K, Set<V>>`, `Map<K, ISet<V>>`) and left as they are for an `Iterable` one
- Fix: the default of an `IMap` field read from a `Map` is applied after the conversion of the source map

## 1.2.1

- Fix: the constructor that builds the target no longer depends on the order of declaration. Public constructors are preferred over private ones (a Freezed class without fields, with `const Foo._()` next to `const factory Foo()`, is built with `Foo()`), factories over generative constructors of abstract classes, then the most parameters and the unnamed constructor. A target whose only constructors are private to another library raises `InaccessibleConstructorError` instead of generating code that does not compile (#117)

## 1.2.0

- Feature: target dot notation builds nested target objects in class → class and Map → class mappings (`@Mapping(source: 'street', target: 'address.street')` generates `address: Address(street: ...)`), at any depth and with every `@Mapping` option. `@InheritInverseConfiguration` of a class → Map method flattening a nested source now builds the nested object (#118)
- Breaking (build error only): `MapTargetDotNotationUnsupportedError` is removed; invalid dotted targets of a class target raise `InvalidNestedTargetError`. Dotted targets on class → class methods, previously ignored, now build nested objects

## 1.1.0

- Feature: class ↔ `Map<String, dynamic>` mapping, detected automatically from the method signature (class → Map when the return type is a `Map<String, ...>`, Map → class when a source parameter is a `Map`). Works with standard classes, Freezed and Built Value
- Feature: raw `Map`, `Map<Object?, Object?>` and `Map<dynamic, dynamic>` sources (Firebase Realtime Database)
- Feature: nested classes, collections of classes, `Map<K, X>` fields, enums (by name) and `double` (read via `num`) in map conversions
- Feature: converters via `@Mapper(uses: ...)` and declared methods (e.g. `DateTime` ↔ epoch milliseconds)
- Feature: dot notation on map sources, and target dot notation building nested maps (class → Map)
- Feature: multi-source Map → class methods (e.g. `fromRealtime(Map map, String id)`)
- Feature: `@InheritConfiguration` / `@InheritInverseConfiguration` across mapping directions
- Known limitations: sealed/discriminator targets (#119), collection-level mapping methods (#120)

## 1.0.10

- Fix: skip nested converter synthesis for ignored targets — `@Mapping(target: '...', ignore: true)` no longer triggers `NoRelationFoundError` for code that is never emitted (#110)
- Fix: resolve `<NULL>` sentinel and non-enum return types in enum value mapping (#110)
- Fix: render `<ANY_REMAINING>` / `<ANY_UNMAPPED>` fallbacks through the expression factory instead of assuming an enum return type (#110)
- chore: update dependency flutter to v3.44.8 (#108)

## 1.0.9

- chore: widen analyzer constraint to >=10.0.0 <14.0.0
- chore: widen build constraint to >=3.1.0 <5.0.0

## 1.0.8

- chore: bump analyzer version to >=12.0.0 <14.0.0 and refactor default expression method (#106)

## 1.0.7

- Fix: update source expression handling and default value logic in mapping (#105)
- Fix: improve regex for interpolation detection and add support for dollar signs in property expressions (#104)
- Add coercions between list-to-set and set-to-list (#95)
- chore: update dependency flutter to v3.44.5 (#100)
- chore: update dependency melos to v8 (#101)

## 1.0.6

- chore: update dependency analyzer to v12
- chore: update dependency dart_style to v3.1.0

## 1.0.5

- Fix: `@ValueMapping` now correctly applies `anyRemaining` and `anyUnmapped` strategies (#86)
- Fix: `forceNonNull` is no longer incorrectly applied during nested object mapping (#86)

## 1.0.4

- Fix: handle null value mapping in enum-to-raw conversion (#85)

## 1.0.3

- Fix: resolve import alias for types re-exported via barrel files (#67)

## 1.0.2

- Fix: preserve import alias in null-source and ANY_REMAINING enum mapping (#80)
- Fix: skip nullability guard when callable handles the conversion (#44)
- Fix: resolve generic field types using InterfaceType substitution for generic classes like `Pagination<T>` (#81)

## 1.0.1

- Add support for nullValue-as-source in enum mapping
- Fix inherit-config ignore behavior

## 1.0.0

- Implement @SubclassMapping support for runtime-type dispatch in mappers (#76)
- Add support for conditional field mapping with expressions and default values (#75)
- Add support for default, constant values, dot notation and multiple params access (#74)
- Add dynamic and generic field support with corresponding mappers (#73)
- Add golden tests for mapping validation (#72)

## 0.9.0

- Escape ArgumentError for enum by sanitizing display name (#64)
- Add support for multiple value mapping in enums (#65)
- Update dependency analyzer to v8.
- Update dependency build to v4.
- Update dependency lints to v6 (#42)
- Update dependency strings to v4 (#48)
- Update dependency source_gen to v4 (#55)
- Update dependency flutter to v3.38.5 (#58)

## 0.8.0

- Checking ExternalMappingMethods when field is NestedField for BuiltExpressionFactory (#38)
- Add support for callable function in @Mapping annotation. (#39)

## 0.7.0

- Add support for force non null flag in Mapping annotation.

## 0.6.0

- Add support for InheritConfiguration and InheritInverseConfiguration annotations.
- Update dependency analyzer to v7.
- Update dependency dart_style to v3.
- Update dependency freezed to v3.
- Update dependency freezed_annotation to v3.
- Update dependency lints to v5.
- Update dependency source_gen to v2.
- Update dependency flutter to v3.29.2.

## 0.5.0

- Add support for import aliases during the generation of mapping methods.
- Add support for circular object mapping, via lazy analysis.
- Introduce reusing of user-defined method during the generation of mapping methods.
 
## 0.4.0

- Enhance error handling.
- Add support for built enum mapping.
- Enhance transformation from num to double and int.

## 0.3.0

- Add support for automatic transformation mapping if two fields are primitive. DateTime included.
- Improve find nullability in external mapping method.

## 0.2.2

- Auto skipping copyWith, toString, hashCode, runtimeType from getters.
- Fix support for first level ignoring mapping.

## 0.2.1

- Enhance enum mapping function reusing from other mappers.
- Remove meta dependency.

## 0.2.0

- Add support to freezed classes.
- Add support to built classes.
- Add support to enums.
- Add support to uses external mappers.

## 0.1.0

- Initial version.
