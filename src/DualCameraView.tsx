import { requireNativeViewManager } from "expo-modules-core";
import React, { useCallback, useState } from "react";
import { LayoutChangeEvent, View } from "react-native";
import { DualCameraProps, CameraStyle } from "./ExpoDualCamera.types";

const NativeDualCamera = requireNativeViewManager("ExpoDualCamera");

function resolveStyle(style: CameraStyle | undefined, parentWidth: number, parentHeight: number) {
  if (!style)
    return { x: 0, y: 0, width: parentWidth, height: parentHeight, zIndex: 0, borderRadius: 0, objectFit: "cover" };

  const resolve = (val: number | string | undefined, parent: number, fallback: number) => {
    if (val === undefined) return fallback;
    if (typeof val === "string" && val.endsWith("%")) return (parseFloat(val) / 100) * parent;
    return typeof val === "number" ? val : fallback;
  };

  const w = resolve(style.width, parentWidth, parentWidth);
  const h = resolve(style.height, parentHeight, parentHeight);

  let x = style.left ?? 0;
  let y = style.top ?? 0;
  if (style.right !== undefined && style.left === undefined) x = parentWidth - w - style.right;
  if (style.bottom !== undefined && style.top === undefined) y = parentHeight - h - style.bottom;

  return {
    x,
    y,
    width: w,
    height: h,
    zIndex: style.zIndex ?? 0,
    borderRadius: style.borderRadius ?? 0,
    objectFit: style.objectFit ?? "cover",
  };
}

export function DualCamera({ style, frontStyle, backStyle }: DualCameraProps) {
  const [layout, setLayout] = useState({ width: 0, height: 0 });

  const onLayout = useCallback((e: LayoutChangeEvent) => {
    const { width, height } = e.nativeEvent.layout;
    setLayout({ width, height });
  }, []);

  const front = resolveStyle(frontStyle, layout.width, layout.height);
  const back = resolveStyle(backStyle, layout.width, layout.height);

  return (
    <View style={style} onLayout={onLayout}>
      {layout.width > 0 && (
        <NativeDualCamera
          style={{ position: "absolute", top: 0, left: 0, width: layout.width, height: layout.height }}
          frontCamera={front}
          backCamera={back}
        />
      )}
    </View>
  );
}
