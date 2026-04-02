/*
 *
 *  Copyright (c) 2026 MyLittleSuite
 *
 *  Permission is hereby granted, free of charge, to any person
 *  obtaining a copy of this software and associated documentation
 *  files (the "Software"), to deal in the Software without
 *  restriction, including without limitation the rights to use,
 *  copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the
 *  Software is furnished to do so, subject to the following
 *  conditions:
 *
 *  The above copyright notice and this permission notice shall be
 *  included in all copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 *  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 *  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 *  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 *  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 *  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 *  OTHER DEALINGS IN THE SOFTWARE.
 *
 */

import 'package:analyzer/dart/element/element.dart';
import 'package:dart_mapper_generator/src/analyzers/analyzer.dart';
import 'package:dart_mapper_generator/src/analyzers/contexts/analyzer_context.dart';
import 'package:source_gen/source_gen.dart' show InvalidGenerationSourceError;

class ImportAliasesAnalyzer extends Analyzer<Map<Uri, String>> {
  const ImportAliasesAnalyzer();

  @override
  Map<Uri, String> analyze(AnalyzerContext context) =>
      context.mapperClass.library.firstFragment.libraryImports
          .where((import) =>
              import.prefix?.element.name != null &&
              import.uri is DirectiveUriWithSource)
          .fold(<Uri, String>{}, (acc, import) {
            final alias = import.prefix!.element.name!;
            final directUri =
                (import.uri as DirectiveUriWithSource).source.uri;
            return _allUris(import.importedLibrary, {directUri})
                .fold(acc, (innerAcc, uri) {
              final existing = innerAcc[uri];
              if (existing != null && existing != alias) {
                throw InvalidGenerationSourceError(
                  'Library "$uri" is reachable via two different import '
                  'aliases: "$existing" and "$alias". '
                  'Each library must be imported under a single alias.',
                );
              }
              return innerAcc..[uri] = alias;
            });
          });

  /// Returns all URIs reachable from [library] via re-exports, seeded with
  /// [visited] (which already contains the direct import URI).
  Set<Uri> _allUris(LibraryElement? library, Set<Uri> visited) =>
      library == null
          ? visited
          : library.exportedLibraries.fold(visited, (acc, exported) {
              final uri = exported.firstFragment.source.uri;
              return acc.contains(uri)
                  ? acc
                  : _allUris(exported, {...acc, uri});
            });
}
