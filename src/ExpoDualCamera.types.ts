export type CameraStyle = {
  top?: number;
  left?: number;
  right?: number;
  bottom?: number;
  width?: number | string; // number (px) or '100%'
  height?: number | string;
  zIndex?: number;
  borderRadius?: number;
  objectFit?: "cover" | "contain" | "fill";
};

export type DualCameraProps = {
  style?: any;
  frontStyle?: CameraStyle;
  backStyle?: CameraStyle;
};
