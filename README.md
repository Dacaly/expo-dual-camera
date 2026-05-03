# expo-dual-camera

Native dual camera support for Expo apps using AVCaptureMultiCamSession (iOS) and CameraX (Android).

## Features

- True simultaneous front and back camera capture
- Raw frame control - style the cameras however you want in your app
- iOS 13+ with AVCaptureMultiCamSession support
- Android API 24+ with CameraX

## Installation

```bash
npx expo install expo-dual-camera
```

## Usage

```tsx
import { DualCamera, isSupported } from 'expo-dual-camera';
import { StyleSheet, View, useWindowDimensions } from 'react-native';

const supported = await isSupported();

// Style cameras yourself - horizontal split
const { width, height } = useWindowDimensions();

<DualCamera
  frontFrame={{ x: 0, y: 0, width: width / 2, height }}
  backFrame={{ x: width / 2, y: 0, width: width / 2, height }}
  style={styles.container}
/>

// Or vertical split
<DualCamera
  frontFrame={{ x: 0, y: 0, width, height: height / 2 }}
  backFrame={{ x: 0, y: height / 2, width, height: height / 2 }}
  style={styles.container}
/>

// Or picture-in-picture
const pipSize = Math.min(width, height) * 0.25;
<DualCamera
  frontFrame={{ x: width - pipSize - 16, y: height - pipSize - 16, width: pipSize, height: pipSize }}
  backFrame={{ x: 0, y: 0, width, height }}
  style={styles.container}
/>
```

## Props

| Prop | Type | Description |
|------|------|-------------|
| `frontFrame` | `{ x, y, width, height }` | Position and size of front camera |
| `backFrame` | `{ x, y, width, height }` | Position and size of back camera |
| `frontGravity` | `'resize' \| 'resizeAspect' \| 'resizeAspectFill'` | Video gravity for front camera (default: `resizeAspectFill`) |
| `backGravity` | `'resize' \| 'resizeAspect' \| 'resizeAspectFill'` | Video gravity for back camera (default: `resizeAspectFill`) |

## Functions

- `isSupported()` - Returns `Promise<boolean>` indicating if dual camera is available on this device

## License

MIT
