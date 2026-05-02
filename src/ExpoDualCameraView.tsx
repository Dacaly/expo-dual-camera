import { requireNativeView } from 'expo';
import * as React from 'react';

import { ExpoDualCameraViewProps } from './ExpoDualCamera.types';

const NativeView: React.ComponentType<ExpoDualCameraViewProps> =
  requireNativeView('ExpoDualCamera');

export default function ExpoDualCameraView(props: ExpoDualCameraViewProps) {
  return <NativeView {...props} />;
}
