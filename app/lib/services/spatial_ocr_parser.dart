import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:uuid/uuid.dart';
import '../models/bill_item.dart';

class SpatialOcrParser {
  static const _uuid = Uuid();

  /// Parse lines and cluster item names with their corresponding prices based on 2D coordinates
  static List<BillItem> parseRecognizedText(RecognizedText recognizedText) {
    final List<TextLine> allLines = [];
    for (final block in recognizedText.blocks) {
      allLines.addAll(block.lines);
    }

    if (allLines.isEmpty) return [];

    final List<TextLine> textCandidates = [];
    final List<_PriceCandidate> priceCandidates = [];

    // Currency/number regex (matches e.g., 350.000, 350,000, 45.000, 45000, 350k)
    final priceRegex = RegExp(r'(\d{1,3}(?:[.,]\d{3})*|\d{2,7})(?:\s*(?:đ|vnd|k))?$', caseSensitive: false);

    for (final line in allLines) {
      final text = line.text.trim();
      final match = priceRegex.firstMatch(text);

      if (match != null && _isLikelyPrice(text)) {
        final parsedValue = _parsePriceValue(match.group(1)!);
        if (parsedValue > 0) {
          priceCandidates.add(_PriceCandidate(
            value: parsedValue,
            line: line,
            rect: line.boundingBox,
          ));
          continue;
        }
      }

      // If it doesn't look like a standalone price or total header, treat as item candidate
      if (!_isIgnoredHeader(text)) {
        textCandidates.add(line);
      }
    }

    final List<BillItem> results = [];

    // Spatial clustering: Match each price candidate with the nearest text line on the same horizontal band (|ΔY| <= threshold)
    for (final price in priceCandidates) {
      TextLine? bestMatch;
      double minDistance = double.infinity;

      for (final textLine in textCandidates) {
        final double deltaY = (textLine.boundingBox.center.dy - price.rect.center.dy).abs();
        final double lineHeight = max(textLine.boundingBox.height, price.rect.height);

        // Lines must be on the same horizontal reading line (|ΔY| <= 0.6 * lineHeight)
        if (deltaY <= lineHeight * 0.6) {
          // Text must be to the left of the price
          if (textLine.boundingBox.right <= price.rect.left + 20) {
            final double distanceX = price.rect.left - textLine.boundingBox.right;
            if (distanceX < minDistance) {
              minDistance = distanceX;
              bestMatch = textLine;
            }
          }
        }
      }

      if (bestMatch != null) {
        // Clean item name (strip leading numbers like "1.", "2-")
        final cleanName = bestMatch.text.replaceAll(RegExp(r'^\d+[\.\-\s]+'), '').trim();
        if (cleanName.isNotEmpty) {
          final combinedRect = Rect.fromLTRB(
            bestMatch.boundingBox.left,
            min(bestMatch.boundingBox.top, price.rect.top),
            price.rect.right,
            max(bestMatch.boundingBox.bottom, price.rect.bottom),
          );

          results.add(BillItem(
            id: _uuid.v4(),
            name: cleanName,
            price: price.value,
            quantity: 1,
            boundingBox: combinedRect,
          ));
        }
      }
    }

    return results;
  }

  static bool _isLikelyPrice(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('bàn') || lower.contains('table') || lower.contains('ngày') || lower.contains('date') || lower.contains('giờ')) {
      return false;
    }
    return RegExp(r'\d').hasMatch(text);
  }

  static bool _isIgnoredHeader(String text) {
    final lower = text.toLowerCase();
    return lower.contains('tổng cộng') ||
        lower.contains('total') ||
        lower.contains('vat') ||
        lower.contains('hóa đơn') ||
        lower.contains('receipt') ||
        lower.contains('thu ngân') ||
        lower.contains('cảm ơn');
  }

  static double _parsePriceValue(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^\d]'), '');
    final val = double.tryParse(cleaned) ?? 0;
    // Handle 'k' notation shorthand (e.g., 45k -> 45000)
    if (val < 1000 && val > 0) {
      return val * 1000;
    }
    return val;
  }
}

class _PriceCandidate {
  final double value;
  final TextLine line;
  final Rect rect;

  _PriceCandidate({
    required this.value,
    required this.line,
    required this.rect,
  });
}
