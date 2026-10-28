import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.iiecm.admin',
  appName: 'IIECM Admin',
  webDir: 'dist',
  bundledWebRuntime: false,
  android: {
    allowMixedContent: false,
    backgroundColor: '#0f1a36',
  },
  server: {
    androidScheme: 'https',
  },
};

export default config;
