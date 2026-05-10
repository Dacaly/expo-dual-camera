# expo-dual-camera

Native dual camera support for Expo apps using AVCaptureMultiCamSession (iOS) and CameraX (Android).

## Features

- True simultaneous front and back camera capture
- Raw frame control - style the cameras however you want in your app
- iOS 13+ with AVCaptureMultiCamSession support
- Android API 24+ with CameraX
- Flexible camera styling with `top`, `left`, `right`, `bottom` positioning
- Support for percentage-based dimensions (e.g., `width: '50%'`)
- `zIndex` control for camera layering
- `borderRadius` for rounded corners
- `objectFit` ('cover', 'contain', 'fill') for video scaling

## Installation

```bash
npx expo install expo-dual-camera
```

## Usage

```tsx
import { DualCamera, isSupported } from 'expo-dual-camera';
import { StyleSheet, View, useWindowDimensions } from 'react-native';

const supported = await isSupported();

const { width, height } = useWindowDimensions();

// Horizontal split - 50% top, 50% bottom
<DualCamera
  frontStyle={{ left: 0, top: 0, width: '100%', height: '50%' }}
  backStyle={{ left: 0, top: '50%', width: '100%', height: '50%' }}
  style={styles.container}
/>

// Vertical split - full width, each camera full height (black bars for unfilled space)
<DualCamera
  frontStyle={{ left: 0, top: 0, width: '50%', height: '50%' }}
  backStyle={{ left: width / 2, top: (height - height / 2) / 2, width: '50%', height: '50%' }}
  style={styles.container}
/>

// Picture-in-picture - small camera in corner, large background camera
const pipSize = Math.min(width, height) * 0.25;
const pipMargin = 20;
<DualCamera
  frontStyle={{
    left: pipMargin,
    top: pipMargin,
    width: pipSize,
    height: pipSize * 1.4,
    borderRadius: 12,
    zIndex: 1
  }}
  backStyle={{ left: 0, top: 0, width: '100%', height: '100%' }}
  style={styles.container}
/>

// Using fixed pixel values
<DualCamera
  frontStyle={{ left: 20, top: 20, width: 120, height: 160, borderRadius: 8 }}
  backStyle={{ left: 0, top: 0, width: '100%', height: '100%' }}
  style={styles.container}
/>

// Access the camera via layout measurement
import { useSafeAreaInsets } from 'react-native-safe-area-context';

const insets = useSafeAreaInsets();
<DualCamera
  frontStyle={{ left: insets.left + 20, top: insets.top + 60, width: 100, height: 140 }}
  backStyle={{ left: 0, top: 0, width: '100%', height: '100%' }}
  style={{ flex: 1 }}
/>
```

## Props

| Prop         | Type          | Description                              |
| ------------ | ------------- | ---------------------------------------- |
| `style`      | `ViewStyle`   | Container style for the dual camera view |
| `frontStyle` | `CameraStyle` | Styling for the front camera             |
| `backStyle`  | `CameraStyle` | Styling for the back camera              |

### CameraStyle Properties

| Property       | Type                             | Description                                      |
| -------------- | -------------------------------- | ------------------------------------------------ |
| `top`          | `number \| string`               | Top offset (px or '%')                           |
| `left`         | `number \| string`               | Left offset (px or '%')                          |
| `right`        | `number \| string`               | Right offset (px or '%') - overrides left if set |
| `bottom`       | `number \| string`               | Bottom offset (px or '%') - overrides top if set |
| `width`        | `number \| string`               | Width (px or '%') - defaults to '100%'           |
| `height`       | `number \| string`               | Height (px or '%') - defaults to '100%'          |
| `zIndex`       | `number`                         | Layer order (higher = on top)                    |
| `borderRadius` | `number`                         | Corner radius in pixels                          |
| `objectFit`    | `'cover' \| 'contain' \| 'fill'` | Video scaling mode (default: 'cover')            |

## Functions

- `isSupported()` - Returns `Promise<boolean>` indicating if dual camera is available on this device

## License

MIT
