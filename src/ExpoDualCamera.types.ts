import type { ViewStyle, StyleProp } from "react-native";

export type DualCameraFrontProps = {
  style?: StyleProp<ViewStyle>;
  onReady?: () => void;
};

export type DualCameraBackProps = {
  style?: StyleProp<ViewStyle>;
  lens?: "wide" | "ultraWide" | "telephoto";
  onReady?: () => void;
};
