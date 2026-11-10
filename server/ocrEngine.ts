import { spawn } from 'child_process';
import { writeFileSync, unlinkSync } from 'fs';
import { tmpdir } from 'os';
import { join } from 'path';

export interface OcrResultItem {
  id: string;
  name: string;
  price: number;
  quantity: number;
}

/**
 * Call native macOS Vision OCR to detect text blocks and 2D bounding boxes
 */
export async function performReceiptOcr(imageBuffer: Buffer): Promise<OcrResultItem[]> {
  const tempPath = join(tmpdir(), `receipt_${Date.now()}_${Math.random().toString(36).substring(7)}.jpg`);
  writeFileSync(tempPath, imageBuffer);

  return new Promise((resolve) => {
    const swiftScript = `
import Cocoa
import Vision

let imagePath = "${tempPath}"
guard let image = NSImage(contentsOfFile: imagePath),
      let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    print("[]")
    exit(0)
}

struct LineItem: Codable {
    let text: String
    let x: Double
    let y: Double
    let width: Double
    let height: Double
}

var lines: [LineItem] = []

let request = VNRecognizeTextRequest { req, err in
    guard let obs = req.results as? [VNRecognizedTextObservation] else { return }
    for o in obs {
        if let top = o.topCandidates(1).first {
            let b = o.boundingBox
            lines.append(LineItem(text: top.string, x: b.origin.x, y: b.origin.y, width: b.size.width, height: b.size.height))
        }
    }
}
request.recognitionLevel = .accurate
request.recognitionLanguages = ["vi-VN", "en-US"]

let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
try? handler.perform([request])

if let data = try? JSONEncoder().encode(lines), let jsonStr = String(data: data, encoding: .utf8) {
    print(jsonStr)
} else {
    print("[]")
}
`;

    const proc = spawn('swift', ['-e', swiftScript]);
    let stdout = '';
    proc.stdout.on('data', (d) => { stdout += d.toString(); });
    
    proc.on('close', () => {
      try {
        unlinkSync(tempPath);
      } catch (_) {}

      try {
        const rawLines: Array<{ text: string; x: number; y: number; width: number; height: number }> = JSON.parse(stdout.trim());
        const parsed = clusterReceiptLines(rawLines);
        resolve(parsed);
      } catch (e) {
        resolve([]);
      }
    });

    proc.on('error', () => {
      try { unlinkSync(tempPath); } catch (_) {}
      resolve([]);
    });
  });
}

function clusterReceiptLines(lines: Array<{ text: string; x: number; y: number; width: number; height: number }>): OcrResultItem[] {
  const priceRegex = /(\d{1,3}(?:[.,]\d{3})*|\d{2,7})(?:\s*(?:đ|vnd|k))?$/i;
  
  const textCandidates: typeof lines = [];
  const priceCandidates: Array<{ value: number; line: typeof lines[0] }> = [];

  for (const line of lines) {
    const text = line.text.trim();
    if (isIgnoredHeader(text)) continue;

    const match = text.match(priceRegex);
    if (match && isLikelyPrice(text)) {
      const val = parsePriceValue(match[1]);
      if (val >= 1000) {
        priceCandidates.add ? priceCandidates.push({ value: val, line }) : priceCandidates.push({ value: val, line });
        continue;
      }
    }
    textCandidates.push(line);
  }

  const results: OcrResultItem[] = [];

  for (const price of priceCandidates) {
    let bestMatch: typeof lines[0] | null = null;
    let minDistance = Infinity;

    for (const textLine of textCandidates) {
      // In Vision framework, y is normalized 0.0 at bottom to 1.0 at top
      const deltaY = Math.abs(textLine.y - price.line.y);
      const lineHeight = Math.max(textLine.height, price.line.height);

      if (deltaY <= lineHeight * 0.9) {
        // Text must be to the left of price
        if (textLine.x < price.line.x) {
          const distX = price.line.x - (textLine.x + textLine.width);
          if (distX < minDistance) {
            minDistance = distX;
            bestMatch = textLine;
          }
        }
      }
    }

    if (bestMatch) {
      let cleanName = bestMatch.text.replace(/^\d+[\.\-\s]+/, '').trim();
      // Remove trailing noise
      cleanName = cleanName.replace(/[\:\-\_]+$/, '').trim();

      if (cleanName.length > 2 && !cleanName.toLowerCase().includes('tổng')) {
        results.push({
          id: `item_${Math.random().toString(36).substring(7)}`,
          name: cleanName,
          price: price.value,
          quantity: 1,
        });
      }
    }
  }

  return results;
}

function parsePriceValue(raw: string): number {
  const cleaned = raw.replace(/[.,\s]/g, '');
  return parseInt(cleaned, 10) || 0;
}

function isLikelyPrice(text: string): boolean {
  const lower = text.toLowerCase();
  if (lower.includes('bàn') || lower.includes('ngày') || lower.includes('giờ') || lower.includes('đt')) {
    return false;
  }
  return true;
}

function isIgnoredHeader(text: string): boolean {
  const lower = text.toLowerCase();
  const ignored = ['phiếu thanh toán', 'hóa đơn', 'tổng cộng', 'tiền thừa', 'cảm ơn', 'hẹn gặp lại', 'quán', 'đc:', 'đt:', 'tên món', 'thành tiền', 'sl'];
  return ignored.some(k => lower.includes(k));
}
