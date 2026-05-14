import { requireNativeViewManager } from "expo-modules-core";
import React from "react";
import { DualCameraFrontProps, DualCameraBackProps } from "./ExpoDualCamera.types";

const NativeDualCamera = requireNativeViewManager("ExpoDualCamera");

export function DualCameraFront({ style, onReady, onError }: DualCameraFrontProps) {
  return <NativeDualCamera style={style} side="front" onReady={onReady} onError={onError} />;
}

export function DualCameraBack({ style, lens = "wide", onReady, onError }: DualCameraBackProps) {
  return (
    <NativeDualCamera style={style} side="back" lens={lens} onReady={onReady} onError={onError} />
  );
}
