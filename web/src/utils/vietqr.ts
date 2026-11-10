export function crc16ccitt(data: string): string {
  let crc = 0xffff;
  const polynomial = 0x1021;

  for (let i = 0; i < data.length; i++) {
    const byte = data.charCodeAt(i);
    for (let bit = 0; bit < 8; bit++) {
      const bitVal = ((byte >> (7 - bit)) & 1) === 1;
      const c15 = ((crc >> 15) & 1) === 1;
      crc <<= 1;
      if (c15 !== bitVal) {
        crc ^= polynomial;
      }
    }
  }

  crc &= 0xffff;
  return crc.toString(16).toUpperCase().padStart(4, "0");
}

function formatTlv(tag: string, value: string): string {
  const len = value.length.toString().padStart(2, "0");
  return `${tag}${len}${value}`;
}

export interface VietQrOptions {
  bankBin: string; // e.g., '970432' (VPBank)
  accountNumber: string;
  amount: number;
  memo: string;
}

/**
 * Synthesize strict EMVCo TLV VietQR string for Napas 24/7 instant transfer
 */
export function generateVietQrPayload({
  bankBin,
  accountNumber,
  amount,
  memo,
}: VietQrOptions): string {
  // Format 00: Payload Format Indicator
  let payload = formatTlv("00", "01");

  // Format 01: Point of Initiation Method (12 = Dynamic QR)
  payload += formatTlv("01", "12");

  // Tag 38: Merchant Account Information (Consumer-Presented QR for Napas 24/7)
  const guid = formatTlv("00", "A000000727"); // Napas AID
  const benInfo = formatTlv("00", bankBin) + formatTlv("01", accountNumber);
  const serviceCode = formatTlv("02", "QRIBFTTA"); // Napas 247 Instant Transfer to Account
  const tag38Value = guid + formatTlv("01", benInfo) + serviceCode;
  payload += formatTlv("38", tag38Value);

  // Tag 53: Transaction Currency (704 = VND)
  payload += formatTlv("53", "704");

  // Tag 54: Transaction Amount
  payload += formatTlv("54", Math.round(amount).toString());

  // Tag 58: Country Code (VN)
  payload += formatTlv("58", "VN");

  // Tag 62: Additional Data Field (Purpose of Transaction / Transfer Note)
  const tag62Value = formatTlv("08", memo.trim());
  payload += formatTlv("62", tag62Value);

  // Tag 63: CRC-16 Checksum
  const prefixForCrc = payload + "6304";
  const checksum = crc16ccitt(prefixForCrc);

  return prefixForCrc + checksum;
}
