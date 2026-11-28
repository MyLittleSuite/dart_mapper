## 1.1.1

- Bump version to keep in sync with dart_mapper_generator 1.1.1

## 1.1.0

- Feature: new `Mapping.qualifiedBy` selects the mapper method that converts the source(s), as `'methodName'` or `'MapperClass.methodName'`. Cannot be combined with `callable`, `expression`, `constant` or `ignore` (#126)
- Feature: new `@DiscriminatorKey` annotation declaring the `Map` key that holds the discriminator of a `@SubclassMapping` dispatch method (#119)
- `SubclassMapping.source` and `SubclassMapping.target` are now optional: the side that is a `Map` is omitted in Map ↔ class hierarchy mappings (#119)
- `SubclassMapping` has a new `discriminatorValue` parameter identifying the subclass in the `Map` (`String`, `int`, `double`, `num`, `bool` or enum constants) (#119)
- Docs: class ↔ `Map` mapping, target dot notation for nested target objects, and a comma-separated `source` resolved by a mapper method (see dart_mapper_generator)
- Docs: callable examples declare typed parameters instead of `dynamic`

## 1.0.10

- Bump version to keep in sync with dart_mapper_generator 1.0.10

## 1.0.9

- Bump version to keep in sync with dart_mapper_generator 1.0.9

## 1.0.8

- Bump version to keep in sync with dart_mapper_generator 1.0.8

## 1.0.7

- Bump version to keep in sync with dart_mapper_generator 1.0.7

## 1.0.6

- Bump version to keep in sync with dart_mapper_generator 1.0.6

## 1.0.5

- Bump version to keep in sync with dart_mapper_generator 1.0.5

## 1.0.4

- Bump version to keep in sync with dart_mapper_generator 1.0.4

## 1.0.3

- Bump version to keep in sync with dart_mapper_generator 1.0.3

## 1.0.2

- Bump version to keep in sync with dart_mapper_generator 1.0.2

## 1.0.1

- Add support for nullValue-as-source in enum mapping
- Fix inherit-config ignore behavior

## 1.0.0

- Implement @SubclassMapping support for runtime-type dispatch in mappers (#76)
- Add support for default, constant values, dot notation and multiple params access (#74)

## 0.9.0

- Update dependency lints to v6 (#42)

## 0.8.0

- Checking ExternalMappingMethods when field is NestedField for BuiltExpressionFactory (#38)
- Add support for callable function in @Mapping annotation. (#39)

## 0.7.0

- Add support for force non null flag in Mapping annotation.

## 0.6.0

- Add support for InheritConfiguration and InheritInverseConfiguration annotations.

## 0.5.0

Nothing new.

## 0.4.0

Nothing new.

## 0.3.0

Nothing new.

## 0.2.2

Nothing new.

## 0.2.1

Nothing new.

## 0.2.0

- Add support to enums.
- Add support to uses external mappers.

## 0.1.0

- Initial version.
