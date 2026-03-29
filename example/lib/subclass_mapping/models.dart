/*
 * Copyright (c) 2025 MyLittleSuite
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

// Example models for @SubclassMapping demonstration.
//
// Scenario: A media content union — Article and Video are two concrete types
// that share a common base. The mapper dispatches to the correct sub-mapper
// based on runtime type.

/// Base type — NOT sealed (represents a GQL union or open hierarchy).
/// A wildcard fallthrough will be emitted in the dispatch method.
class MediaContent {
  const MediaContent();
}

class Article extends MediaContent {
  final String title;
  final String body;
  const Article({required this.title, required this.body});
}

class Video extends MediaContent {
  final String title;
  final int durationSeconds;
  const Video({required this.title, required this.durationSeconds});
}

/// Target DTOs.
class MediaContentDto {
  const MediaContentDto();
}

class ArticleDto extends MediaContentDto {
  final String title;
  final String body;
  const ArticleDto({required this.title, required this.body});
}

class VideoDto extends MediaContentDto {
  final String title;
  final int durationSeconds;
  const VideoDto({required this.title, required this.durationSeconds});
}
