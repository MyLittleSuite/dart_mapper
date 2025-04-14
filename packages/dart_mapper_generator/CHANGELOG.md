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
