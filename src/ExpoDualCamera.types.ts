import type { ViewStyle, StyleProp } from "react-native";

export type DualCameraFrontProps = {
  style?: StyleProp<ViewStyle>;
};

export type DualCameraBackProps = {
  style?: StyleProp<ViewStyle>;
  lens?: "wide" | "ultraWide" | "telephoto";
};
