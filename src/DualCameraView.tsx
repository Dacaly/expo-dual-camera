import { requireNativeViewManager } from "expo-modules-core";
import React from "react";
import {
  DualCameraFrontViewProps,
  DualCameraBackViewProps,
} from "./ExpoDualCamera.types";

const NativeDualCamera = requireNativeViewManager("ExpoDualCamera");

export function DualCameraFrontView({
  style,
  zoom,
  mirror,
  autofocus,
  onCameraReady,
  onMountError,
}: DualCameraFrontViewProps) {
  return (
    <NativeDualCamera
      style={style}
      side="front"
      zoom={zoom}
      mirror={mirror}
      autofocus={autofocus}
      onCameraReady={onCameraReady}
      onMountError={onMountError}
    />
  );
}

export function DualCameraBackView({
  style,
  lens = "wide",
  zoom,
  enableTorch,
  flash,
  mirror,
  autofocus,
  onCameraReady,
  onMountError,
}: DualCameraBackViewProps) {
  return (
    <NativeDualCamera
      style={style}
      side="back"
      lens={lens}
      zoom={zoom}
      enableTorch={enableTorch}
      flash={flash}
      mirror={mirror}
      autofocus={autofocus}
      onCameraReady={onCameraReady}
      onMountError={onMountError}
    />
  );
}
