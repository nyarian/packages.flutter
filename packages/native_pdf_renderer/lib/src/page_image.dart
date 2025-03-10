import 'dart:async';
import 'dart:io';
import 'dart:typed_data' show Uint8List;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';
import 'page.dart';

/// Object containing a rendered image
/// in a pre-selected format in [render] method
/// of [PDFPage]
class PDFPageImage {
  const PDFPageImage._({
    @required this.id,
    @required this.pageNumber,
    @required this.width,
    @required this.height,
    @required this.bytes,
    @required this.format,
  });

  static const MethodChannel _channel = MethodChannel('io.scer.pdf.renderer');

  /// Page unique id. Needed for rendering and closing page.
  /// Generated when opening page.
  final String id;

  /// Page number. The first page is 1.
  final int pageNumber;

  /// Width of the rendered area in pixels.
  final int width;

  /// Height of the rendered area in pixels.
  final int height;

  /// Image bytes
  final Uint8List bytes;

  /// Target compression format
  final PDFPageFormat format;

  /// Render a full image of specified PDF file.
  ///
  /// [width], [height] specify resolution to render in pixels.
  /// As default PNG uses transparent background. For change it you can set
  /// [backgroundColor] property like a hex string ('#000000')
  /// [format] - image type, all types can be seen here [PDFPageFormat]
  /// [crop] - render only the necessary part of the image
  static Future<PDFPageImage> render({
    @required String pageId,
    @required int pageNumber,
    @required int width,
    @required int height,
    @required PDFPageFormat format,
    @required String backgroundColor,
    @required Rect crop,
  }) async {
    if (format == PDFPageFormat.WEBP && Platform.isIOS) {
      throw PdfNotSupportException(
        'PDF Renderer on IOS platform does not support WEBP format',
      );
    }

    final obj = await _channel.invokeMethod('render', {
      'pageId': pageId,
      'width': width,
      'height': height,
      'format': format.value,
      'backgroundColor': backgroundColor,
      'crop': crop != null,
      'crop_x': crop?.left?.toInt(),
      'crop_y': crop?.top?.toInt(),
      'crop_height': crop?.height?.toInt(),
      'crop_width': crop?.width?.toInt(),
    });

    if (!(obj is Map<dynamic, dynamic>)) {
      return null;
    }

    final retWidth = obj['width'] as int, retHeight = obj['height'] as int;
    final pixels = obj['data'] as Uint8List;

    return PDFPageImage._(
      id: pageId,
      pageNumber: pageNumber,
      width: retWidth,
      height: retHeight,
      bytes: pixels,
      format: format,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PDFPageImage && other.bytes.lengthInBytes == bytes.lengthInBytes;

  @override
  int get hashCode => identityHashCode(id) ^ pageNumber;

  @override
  String toString() => '$runtimeType{'
      'id: $id, '
      'page: $pageNumber,  '
      'width: $width, '
      'height: $height, '
      'bytesLength: ${bytes.lengthInBytes}}';
}

class PdfNotSupportException implements Exception {
  PdfNotSupportException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}
