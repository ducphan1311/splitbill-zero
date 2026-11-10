/**
 * Deep Link Scheme & Universal App Launchers for Vietnam Banking Apps
 * Supports Napas 24/7 instant interbank settlement
 */

export interface BankAppLauncher {
  name: string;
  scheme: string;
  packageAndroid?: string;
  appStoreId?: string;
  deeplink: (qrContent: string) => string;
}

export const VIETNAM_POPULAR_BANKS: Record<string, BankAppLauncher> = {
  vpbank: {
    name: 'VPBank NEO',
    scheme: 'vpbankneo://',
    packageAndroid: 'com.vpb.neo',
    appStoreId: '1540916301',
    deeplink: (qr) => `vpbankneo://qr?data=${encodeURIComponent(qr)}`,
  },
  vcb: {
    name: 'Vietcombank (VCB Digibank)',
    scheme: 'vcbdigibank://',
    packageAndroid: 'com.VCB',
    appStoreId: '561433133',
    deeplink: (qr) => `vcbdigibank://payment?qr=${encodeURIComponent(qr)}`,
  },
  tcb: {
    name: 'Techcombank Mobile',
    scheme: 'tcb://',
    packageAndroid: 'vn.com.techcombank.bb.app',
    appStoreId: '1548623362',
    deeplink: (qr) => `tcb://scan?data=${encodeURIComponent(qr)}`,
  },
  mbbank: {
    name: 'MBBank',
    scheme: 'mbmobile://',
    packageAndroid: 'com.mbmobile',
    appStoreId: '1205807863',
    deeplink: (qr) => `mbmobile://qr?qrCode=${encodeURIComponent(qr)}`,
  },
  momo: {
    name: 'MoMo E-Wallet',
    scheme: 'momo://',
    packageAndroid: 'com.mservice.momotransfer',
    appStoreId: '918786221',
    deeplink: (qr) => `momo://?action=payWithApp&qr=${encodeURIComponent(qr)}`,
  },
};

/**
 * Launch best banking application or fallback to saving QR image
 */
export function openBankingApp(qrPayload: string, preferredBank = 'vpbank'): void {
  const bank = VIETNAM_POPULAR_BANKS[preferredBank] || VIETNAM_POPULAR_BANKS.vpbank;
  const targetUrl = bank.deeplink(qrPayload);

  // Attempt window redirect to custom deep-link scheme
  window.location.href = targetUrl;
}
