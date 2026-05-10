import { requireNativeViewManager } from "expo-modules-core";
import React from "react";
import { DualCameraFrontProps, DualCameraBackProps } from "./ExpoDualCamera.types";

const NativeDualCamera = requireNativeViewManager("ExpoDualCamera");

export function DualCameraFront({ style }: DualCameraFrontProps) {
  return <NativeDualCamera style={style} side="front" />;
}

export function DualCameraBack({ style, lens = "wide" }: DualCameraBackProps) {
  return <NativeDualCamera style={style} side="back" lens={lens} />;
}
