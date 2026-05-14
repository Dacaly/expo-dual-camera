import { useCallback, useRef, useState } from "react";

/**
 * Tracks readiness of the dual camera session.
 *
 * Both the front and back views must fire their `onReady` event before
 * `isReady` becomes `true`. Pass the returned handlers as the `onReady`
 * prop on each view:
 *
 * ```tsx
 * const { isReady, onFrontReady, onBackReady } = useIsDualCameraReady();
 *
 * <DualCameraFront onReady={onFrontReady} style={styles.front} />
 * <DualCameraBack  onReady={onBackReady}  style={styles.back} />
 *
 * <Button disabled={!isReady} title="Switch lens" onPress={switchLens} />
 * ```
 */
export function useIsDualCameraReady() {
  const [isReady, setIsReady] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const readyRef = useRef({ front: false, back: false });

  const check = () => {
    if (readyRef.current.front && readyRef.current.back) {
      setIsReady(true);
    }
  };

  const onFrontReady = useCallback(() => {
    readyRef.current.front = true;
    check();
  }, []);

  const onBackReady = useCallback(() => {
    readyRef.current.back = true;
    check();
  }, []);

  const onFrontError = useCallback(
    (e: { nativeEvent: { message: string } }) => {
      setError(e.nativeEvent.message);
      setIsReady(false);
    },
    []
  );

  const onBackError = useCallback(
    (e: { nativeEvent: { message: string } }) => {
      setError(e.nativeEvent.message);
      setIsReady(false);
    },
    []
  );

  /** Call this when tearing down / switching modes to reset the state. */
  const reset = useCallback(() => {
    readyRef.current = { front: false, back: false };
    setIsReady(false);
    setError(null);
  }, []);

  return {
    isReady,
    error,
    onFrontReady,
    onBackReady,
    onFrontError,
    onBackError,
    reset,
  } as const;
}
