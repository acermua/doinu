import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/datamodel.dart';
import 'theme.dart';

Future<Uint8List?> generateCustomShareImage(SongMediaItem item) async {
  try {
    final imageUrl = item.images.isNotEmpty ? item.images.last.url : null;
    if (imageUrl == null || imageUrl.isEmpty) return null;

    final provider = CachedNetworkImageProvider(imageUrl);
    final stream = provider.resolve(const ImageConfiguration());
    final completer = Completer<ImageInfo>();

    void listener(ImageInfo info, bool _) => completer.complete(info);
    stream.addListener(ImageStreamListener(listener));

    final info = await completer.future;
    final ui.Image albumArt = info.image;

    final ByteData logoData = await rootBundle.load(
      'assets/icons/doinulight.png',
    );
    final ui.Codec logoCodec = await ui.instantiateImageCodec(
      logoData.buffer.asUint8List(),
    );
    final ui.FrameInfo logoFrame = await logoCodec.getNextFrame();
    final ui.Image logoImage = logoFrame.image;

    final dominantColor = await getDominantColorFromImage(imageUrl);

    const double width = 1080;
    const double height = 1920; // Instagram story size
    const double artSize = 530; // smaller art, was full width
    const double padding = (width - artSize) / 2;

    String title = item.title;
    String artist = '';

    if (item is SongDetail) {
      final Set<String> artistsSet = item.contributors.all
          .map((a) => a.title)
          .toSet();
      if (item.primaryArtists.isNotEmpty) {
        artistsSet.addAll(item.primaryArtists.split(',').map((e) => e.trim()));
      }
      artist = artistsSet.join(', ');
    } else if (item is Album) {
      artist = item.artist;
    } else if (item is Playlist) {
      artist = item.artists.map((a) => a.title).toSet().join(', ');
    }

    final titleSpan = TextSpan(
      text: title,
      style: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 42, // Scaled down from 72
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
      ),
    );
    final titlePainter = TextPainter(
      text: titleSpan,
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '...',
    );
    titlePainter.layout(maxWidth: artSize);

    final artistSpan = TextSpan(
      text: artist,
      style: GoogleFonts.poppins(
        color: Colors.white70,
        fontSize: 32, // Scaled down from 44
        fontWeight: FontWeight.w600,
      ),
    );
    final artistPainter = TextPainter(
      text: artistSpan,
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '...',
    );
    artistPainter.layout(maxWidth: artSize);

    const double logoHeight = 70; // Scaled down from 90
    final double logoAspect = logoImage.width / logoImage.height;
    final double logoWidth = logoHeight * logoAspect;

    bool needLogoText = logoAspect < 1.5;
    TextPainter? brandPainter;
    if (needLogoText) {
      brandPainter = TextPainter(
        text: TextSpan(
          text: 'Doinu',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 42, // Scaled down from 64
            fontWeight: FontWeight.w700,
            letterSpacing: -1.0,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      brandPainter.layout();
    }

    // Spacers for balanced aesthetics
    const double spacingArtToTitle = 60;
    const double spacingTitleToArtist = 20;
    const double spacingArtistToLogo = 70;

    // Calculate total height of the content block
    final double contentHeight =
        artSize +
        spacingArtToTitle +
        titlePainter.height +
        spacingTitleToArtist +
        artistPainter.height +
        spacingArtistToLogo +
        logoHeight;

    // Center the content block vertically
    final double offsetY = (height - contentHeight) / 2;

    // Element vertical coordinates
    final double artY = offsetY;
    final double titleY = artY + artSize + spacingArtToTitle;
    final double artistY = titleY + titlePainter.height + spacingTitleToArtist;
    final double logoY = artistY + artistPainter.height + spacingArtistToLogo;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));

    final hsl = HSLColor.fromColor(dominantColor);
    final topColor = hsl.withLightness(0.20).withSaturation(0.6).toColor();
    final bottomColor = hsl.withLightness(0.04).withSaturation(0.4).toColor();

    final bgPaint = Paint()
      ..shader = ui.Gradient.linear(const Offset(0, 0), Offset(0, height), [
        topColor,
        bottomColor,
      ]);

    // Ensure the entire canvas is strictly transparent to avoid weird black corner rendering
    canvas.drawColor(Colors.transparent, ui.BlendMode.clear);

    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), bgPaint);

    final artRect = Rect.fromLTWH(padding, artY, artSize, artSize);
    final artRRect = RRect.fromRectAndCorners(
      artRect,
      topLeft: const Radius.circular(24),
      topRight: const Radius.circular(24),
      bottomLeft: const Radius.circular(24),
      bottomRight: const Radius.circular(24),
    );

    canvas.save();
    canvas.clipRRect(artRRect);
    paintImage(
      canvas: canvas,
      rect: artRect,
      image: albumArt,
      fit: BoxFit.cover,
    );
    canvas.restore();

    titlePainter.paint(canvas, Offset(padding, titleY));
    artistPainter.paint(canvas, Offset(padding, artistY));

    paintImage(
      canvas: canvas,
      rect: Rect.fromLTWH(padding, logoY, logoWidth, logoHeight),
      image: logoImage,
      fit: BoxFit.contain,
    );

    if (brandPainter != null) {
      brandPainter.paint(
        canvas,
        Offset(
          padding + logoWidth + 24,
          logoY + (logoHeight - brandPainter.height) / 2,
        ),
      );
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    return byteData?.buffer.asUint8List();
  } catch (e) {
    debugPrint("⚠️ Failed to generate custom share image: $e");
    return null;
  }
}
