import { DualCamera, isSupported } from 'expo-dual-camera';
import { useWindowDimensions, StyleSheet, View, Text } from 'react-native';
import { useState, useEffect } from 'react';

export default function App() {
  const { width, height } = useWindowDimensions();
  const [supported, setSupported] = useState<boolean | null>(null);

  useEffect(() => {
    isSupported().then(setSupported);
  }, []);

  if (supported === false) {
    return (
      <View style={styles.container}>
        <Text style={styles.text}>Dual camera not supported on this device</Text>
      </View>
    );
  }

  if (supported === null) {
    return (
      <View style={styles.container}>
        <Text style={styles.text}>Checking dual camera support...</Text>
      </View>
    );
  }

  // Horizontal split
  return (
    <View style={styles.container}>
      <DualCamera
        frontFrame={{ x: 0, y: 0, width: width / 2, height }}
        backFrame={{ x: width / 2, y: 0, width: width / 2, height }}
        style={styles.camera}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#000',
  },
  camera: {
    flex: 1,
  },
  text: {
    color: '#fff',
    fontSize: 16,
  },
});
