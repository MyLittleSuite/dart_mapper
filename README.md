# dart_mapper

MapStruct-style object mapping for Dart. Define type-safe mappings declaratively with annotations and get generated implementations at compile time via `build_runner`.

[![pub.dev](https://img.shields.io/pub/v/dart_mapper.svg)](https://pub.dev/packages/dart_mapper)
[![Docs](https://img.shields.io/badge/docs-docs.page-blue)](https://docs.page/MyLittleSuite/dart_mapper)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Features

- Standard class mapping with field renaming and ignores
- [Freezed](https://pub.dev/packages/freezed) and [Built Value](https://pub.dev/packages/built_value) support
- Enum mapping with default and fallback values
- Multi-source mapping (multiple input parameters per method)
- Dot notation for nested property access
- Expression-based computed fields
- Conditional mapping with fallback values
- Subclass mapping with Dart 3 pattern matching
- Default values and constants
- Callable functions for custom mapping logic
- Collection support (`List`, `Set`, `Map`, `BuiltList`, `BuiltSet`, `BuiltMap`)
- Configuration inheritance (`@InheritConfiguration`, `@InheritInverseConfiguration`)
- External mapper injection via `uses`

## Quick Start

```yaml
dependencies:
  dart_mapper: ^1.0.0

dev_dependencies:
  build_runner: ^2.4.8
  dart_mapper_generator: ^1.0.0
```

## Documentation

Full documentation, feature guides, and API reference:

**https://docs.page/MyLittleSuite/dart_mapper**

## License

MIT — see [LICENSE](LICENSE).
