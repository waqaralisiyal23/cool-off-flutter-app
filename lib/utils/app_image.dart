import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vector_graphics/vector_graphics.dart';

import '../inheritance/asset_bundle.dart';

/// Shared asset-bundle instance used for compiled SVG vector loading.
final _assetBundle = ByteDataAssetBundle();

/// A universal image widget that handles all image source types in the app.
class AppImage extends StatelessWidget {
  final dynamic image;
  final double? width;
  final double? height;
  final double? size;
  final Color? color;
  final bool isIcon;
  final Widget? placeholder;

  /// Shown in place of a network image that fails to load. Null leaves the
  /// space empty.
  final Widget? errorWidget;

  final BoxFit? fit;

  const AppImage(
    this.image, {
    super.key,
    this.width,
    this.height,
    this.size,
    this.color,
    this.isIcon = false,
    this.placeholder,
    this.errorWidget,
    this.fit,
  });

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final resolvedColor = color ?? (isIcon ? iconTheme.color : null);
    final resolvedWidth = size ?? width ?? (isIcon ? iconTheme.size : null);
    final resolvedHeight = size ?? height ?? (isIcon ? iconTheme.size : null);

    Widget child = _buildImage(
      resolvedColor,
      resolvedWidth,
      resolvedHeight,
      MediaQuery.maybeDevicePixelRatioOf(context) ?? 1,
    );

    if (context.findAncestorWidgetOfExactType<TextFormField>() != null) {
      child = Center(child: child);
    }

    return SizedBox(width: resolvedWidth, height: resolvedHeight, child: child);
  }

  Widget _buildImage(
    Color? resolvedColor,
    double? resolvedWidth,
    double? resolvedHeight,
    double devicePixelRatio,
  ) {
    if (image is Uint8List) {
      return Image.memory(image, fit: fit);
    }

    final String source = image as String;

    if (source.startsWith('https://') || source.startsWith('http://')) {
      // Backends serve brand and product artwork as SVG as often as bitmap, so
      // the source type is decided per URL rather than per call site.
      if (_isSvg(source)) {
        return SvgPicture(
          _CachedNetworkSvgLoader(source),
          fit: fit ?? BoxFit.contain,
          width: resolvedWidth,
          height: resolvedHeight,
          colorFilter: resolvedColor == null
              ? null
              : ColorFilter.mode(resolvedColor, BlendMode.srcIn),
          placeholderBuilder: placeholder == null ? null : (_) => placeholder!,
          errorBuilder: errorWidget == null ? null : (_, _, _) => errorWidget!,
        );
      }
      return CachedNetworkImage(
        imageUrl: source,
        fit: fit,
        placeholder: placeholder == null ? null : (context, _) => placeholder!,
        errorWidget: errorWidget == null ? null : (_, _, _) => errorWidget!,
      );
    }

    if (source.startsWith('/')) {
      if (_isSvg(source)) {
        return SvgPicture.file(
          File(source),
          fit: fit ?? BoxFit.contain,
          colorFilter: resolvedColor != null
              ? ColorFilter.mode(resolvedColor, BlendMode.srcIn)
              : null,
        );
      }
      return Image.file(File(source), fit: fit, color: color);
    }

    if (source.endsWith('.svg')) {
      return VectorGraphic(
        loader: AssetBytesLoader('$source.vec', assetBundle: _assetBundle),
        colorFilter: resolvedColor == null
            ? null
            : ColorFilter.mode(resolvedColor, BlendMode.srcIn),
        fit: fit ?? BoxFit.contain,
        width: resolvedWidth,
        height: resolvedHeight,
      );
    }

    // Decoded at the size it is drawn rather than the file's own: artwork
    // exported from the design can be far larger than it is shown (a 1704px
    // logo drawn at 46pt), and every decoded pixel stays in the image cache.
    // The longer side, so a cover fit into a non-square box is never
    // upscaled from too small a decode.
    final drawnSize = resolvedWidth == null || resolvedHeight == null
        ? resolvedWidth ?? resolvedHeight
        : math.max(resolvedWidth, resolvedHeight);
    return Image.asset(
      source,
      color: resolvedColor,
      fit: fit,
      cacheWidth: drawnSize == null
          ? null
          : (drawnSize * devicePixelRatio).round(),
    );
  }

  /// Whether [source] points at an SVG.
  ///
  /// Matches on the path only: network SVGs routinely carry a query string
  /// (`.../nike.svg?color=%23111111`), which a plain `endsWith` would miss.
  static bool _isSvg(String source) =>
      Uri.tryParse(source)?.path.toLowerCase().endsWith('.svg') ?? false;
}

/// Loads a network SVG through [DefaultCacheManager], so it survives app
/// restarts instead of being refetched like `SvgPicture.network` does.
///
/// This is the same on-disk cache [CachedNetworkImage] uses, which keeps
/// eviction and sizing policy in one place for every remote image in the app.
class _CachedNetworkSvgLoader extends SvgLoader<Uint8List> {
  final String url;

  const _CachedNetworkSvgLoader(this.url);

  @override
  Future<Uint8List?> prepareMessage(BuildContext? context) async {
    final file = await DefaultCacheManager().getSingleFile(url);
    return file.readAsBytes();
  }

  @override
  String provideSvg(Uint8List? message) =>
      utf8.decode(message!, allowMalformed: true);

  // Identity is the URL: SvgLoader hands the loader itself to flutter_svg's
  // in-memory picture cache as the key, so two loaders for the same URL must
  // compare equal or the SVG is re-parsed on every rebuild.
  @override
  int get hashCode => Object.hash(url, theme, colorMapper);

  @override
  bool operator ==(Object other) =>
      other is _CachedNetworkSvgLoader &&
      other.url == url &&
      other.theme == theme &&
      other.colorMapper == colorMapper;
}
