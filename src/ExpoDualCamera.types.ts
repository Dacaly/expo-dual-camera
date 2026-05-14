import type { ViewStyle, StyleProp } from "react-native";

export type DualCameraFrontProps = {
  style?: StyleProp<ViewStyle>;
  onReady?: () => void;
  onError?: (event: { nativeEvent: { message: string } }) => void;
};

export type DualCameraBackProps = {
  style?: StyleProp<ViewStyle>;
  lens?: "wide" | "ultraWide" | "telephoto";
  onReady?: () => void;
  onError?: (event: { nativeEvent: { message: string } }) => void;
};
