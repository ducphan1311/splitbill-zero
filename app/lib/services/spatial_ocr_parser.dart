import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:uuid/uuid.dart';
import '../models/bill_item.dart';

class SpatialOcrParser {
  static const _uuid = Uuid();

  /// Parse lines and cluster item names with their corresponding prices based on 2D coordinates
  /// Handles Vietnamese F&B receipts, multi-line item names, DG/TT double price columns, and table boundaries
  static List<BillItem> parseRecognizedText(RecognizedText recognizedText) {
    final List<TextLine> allLines = [];
    for (final block in recognizedText.blocks) {
      allLines.addAll(block.lines);
    }

    if (allLines.isEmpty) return [];

    // Helper: Normalize string by removing Vietnamese accents for resilient matching
    String stripAccents(String s) {
      var result = s.toLowerCase();
      const accents = {
        'a': 'áàảãạăắằẳẵặâấầẩẫậ',
        'e': 'éèẻẽẹêếềểễệ',
        'i': 'íìỉĩị',
        'o': 'óòỏõọôốồổỗộơớờởỡợ',
        'u': 'úùủũụưứừửữự',
        'y': 'ýỳỷỹỵ',
        'd': 'đ',
      };
      accents.forEach((key, value) {
        for (var char in value.split('')) {
          result = result.replaceAll(char, key);
        }
      });
      return result;
    }

    // 1. Find Total/Cutoff line (e.g. 'tổng thanh toán', 'tổng cộng', 'còn phải thu')
    double totalCutoffY = double.infinity;
    for (final line in allLines) {
      final norm = stripAccents(line.text);
      if (norm.contains('tong thanh toan') || norm.contains('tong cong') || norm.contains('con phai thu') || (norm.contains('thanh toan') && !norm.contains('truoc khi'))) {
        if (line.boundingBox.top < totalCutoffY) {
          totalCutoffY = line.boundingBox.top - 8.0;
        }
      }
    }

    // 2. Find Header Cutoff line (e.g. 'tên món', 'món ăn', 'đg', 'tt', 'sl', 'thu ngân')
    double topCutoffY = 0.0;
    for (final line in allLines) {
      final norm = stripAccents(line.text).trim();
      if (norm.contains('ten mon') || norm.contains('mon an') || norm == 'dg' || norm == 'tt' || norm == 'sl' || norm.contains('thu ngan') || norm.contains('ban:')) {
        if (line.boundingBox.bottom > topCutoffY) {
          topCutoffY = line.boundingBox.bottom;
        }
      }
    }

    // 3. Extract price candidates from lines
    // Matches 440,000, 185.000, 190.000, 980.000
    final priceRegex = RegExp(r'(\d{1,3}(?:[.,]\d{3})+|\d{4,7})\s*(?:đ|vnd|k)?', caseSensitive: false);

    final List<_PriceCandidate> priceCandidates = [];

    for (final line in allLines) {
      final text = line.text.trim();
      if (line.boundingBox.top >= totalCutoffY) continue;
      if (line.boundingBox.bottom <= topCutoffY) continue;

      // Filter out dates, times, phone numbers, receipt IDs
      if (_isDateOrTimeOrPhone(text)) continue;
      if (_isNoiseOrHeader(text, stripAccents)) continue;

      final matches = priceRegex.allMatches(text);
      for (final m in matches) {
        final val = _parsePriceValue(m.group(1)!);
        // Typical dish price between 5,000 VND and 50,000,000 VND
        if (val >= 5000 && val <= 50000000) {
          priceCandidates.add(_PriceCandidate(
            value: val,
            rect: line.boundingBox,
          ));
        }
      }
    }

    if (priceCandidates.isEmpty) return [];

    // Sort prices by Y ascending (top to bottom)
    priceCandidates.sort((a, b) => a.rect.center.dy.compareTo(b.rect.center.dy));

    // Deduplicate price candidates on the same row (e.g. DG vs TT columns)
    // Keep the rightmost price (largest rect.center.dx) which is the TT (Thành tiền) column
    final List<_PriceCandidate> dedupedPrices = [];
    for (final price in priceCandidates) {
      bool matched = false;
      for (int i = 0; i < dedupedPrices.length; i++) {
        final existing = dedupedPrices[i];
        final deltaY = (existing.rect.center.dy - price.rect.center.dy).abs();
        // If close in Y or same value on adjacent columns, treat as same row
        if (deltaY < 24 || (deltaY < 36 && existing.value == price.value)) {
          matched = true;
          if (price.rect.center.dx > existing.rect.center.dx) {
            dedupedPrices[i] = price;
          }
          break;
        }
      }
      if (!matched) {
        dedupedPrices.add(price);
      }
    }

    // 4. Determine disjoint vertical cutoffs between dish rows
    final List<double> cutoffs = [topCutoffY];
    for (int i = 0; i < dedupedPrices.length - 1; i++) {
      cutoffs.add(dedupedPrices[i + 1].rect.top);
    }
    cutoffs.add(totalCutoffY == double.infinity ? 999999.0 : totalCutoffY);

    // 5. Filter text line candidates for dish names
    final List<TextLine> textCandidates = [];
    for (final line in allLines) {
      final text = line.text.trim();
      if (line.boundingBox.top >= totalCutoffY) continue;
      if (line.boundingBox.bottom <= topCutoffY) continue;
      if (_isDateOrTimeOrPhone(text)) continue;
      if (_isNoiseOrHeader(text, stripAccents)) continue;
      if (RegExp(r'^\d+[\.\-\s]*$').hasMatch(text)) continue;

      // Skip lines that are purely standalone prices
      if (RegExp(r'^\s*(\d{1,3}(?:[.,]\d{3})+|\d{4,7})\s*(?:đ|vnd|k)?\s*$', caseSensitive: false).hasMatch(text)) {
        continue;
      }

      textCandidates.add(line);
    }

    final List<BillItem> results = [];

    // 6. Partition text into corresponding item rows
    for (int i = 0; i < dedupedPrices.length; i++) {
      final p = dedupedPrices[i];
      final double topBound = cutoffs[i];
      final double bottomBound = cutoffs[i + 1];

      final matchedTexts = textCandidates.where((t) {
        final y = t.boundingBox.center.dy;
        final x = t.boundingBox.right;
        return y >= topBound && y < bottomBound && x <= p.rect.left + 25;
      }).toList();

      matchedTexts.sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

      String cleanName = matchedTexts.map((e) => e.text).join(' ');
      cleanName = cleanName.replaceAll(RegExp(r'^\d+[\.\-\s]+'), '').trim();

      if (cleanName.isNotEmpty) {
        final double leftMost = matchedTexts.fold(p.rect.left, (prev, e) => min(prev, e.boundingBox.left));
        final double rightMost = p.rect.right;
        final double topMost = matchedTexts.fold(p.rect.top, (prev, e) => min(prev, e.boundingBox.top));
        final double bottomMost = max(p.rect.bottom, matchedTexts.fold(0.0, (prev, e) => max(prev, e.boundingBox.bottom)));

        results.add(BillItem(
          id: _uuid.v4(),
          name: cleanName,
          price: p.value,
          quantity: 1,
          boundingBox: Rect.fromLTRB(leftMost, topMost, rightMost, bottomMost),
        ));
      }
    }

    return results;
  }

  static bool _isDateOrTimeOrPhone(String text) {
    if (RegExp(r'\d{1,2}/\d{1,2}/\d{2,4}').hasMatch(text)) return true;
    if (RegExp(r'\d{1,2}:\d{2}').hasMatch(text)) return true;
    if (RegExp(r'0\d{8,10}').hasMatch(text)) return true;
    if (RegExp(r'240100\d+').hasMatch(text)) return true;
    return false;
  }

  static bool _isNoiseOrHeader(String text, String Function(String) stripAccents) {
    final norm = stripAccents(text);
    final blacklist = [
      'phieu', 'tam tinh', 'hoa don', 'ngay:', 'ban:', 'khach:', 'thu ngan',
      'ten mon', 'dg', 'tt', 'sl', 'tong thanh toan', 'con phai thu', 'thue vat',
      'thue gtgt', 'cukcuk', 'misa', 'kiotviet', 'ipos', 'cam on', 'hen gap lai',
      'kiem tra', 'xuat hoa don', 'dt:', 'mv1', 'st khach'
    ];
    if (blacklist.any((k) => norm.contains(k))) return true;
    return false;
  }

  static double _parsePriceValue(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^\d]'), '');
    final val = double.tryParse(cleaned) ?? 0;
    if (val < 1000 && val > 0) {
      return val * 1000;
    }
    return val;
  }
}

class _PriceCandidate {
  final double value;
  final Rect rect;

  _PriceCandidate({
    required this.value,
    required this.rect,
  });
}
