import React from 'react';
import { StyleSheet } from 'react-native';
import { requireNativeViewManager } from 'expo-modules-core';
import type { DualCameraProps } from './ExpoDualCamera.types';

const NativeDualCameraView = requireNativeViewManager('ExpoDualCamera');

const GRAVITY_MAP = {
  resize: 'resize',
  resizeAspect: 'resizeAspect',
  resizeAspectFill: 'resizeAspectFill',
} as const;

function frameToProp(frame: { x: number; y: number; width: number; height: number }) {
  return {
    x: frame.x,
    y: frame.y,
    width: frame.width,
    height: frame.height,
  };
}

export function DualCamera(props: DualCameraProps): React.ReactElement {
  const { style, frontFrame, backFrame, frontGravity = 'resizeAspectFill', backGravity = 'resizeAspectFill' } = props;

  return (
    <NativeDualCameraView
      style={[styles.container, style]}
      frontFrame={frameToProp(frontFrame)}
      backFrame={frameToProp(backFrame)}
      frontGravity={GRAVITY_MAP[frontGravity]}
      backGravity={GRAVITY_MAP[backGravity]}
    />
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
});