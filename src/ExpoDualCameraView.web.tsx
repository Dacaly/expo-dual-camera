import * as React from 'react';

import { ExpoDualCameraViewProps } from './ExpoDualCamera.types';

export default function ExpoDualCameraView(props: ExpoDualCameraViewProps) {
  return (
    <div>
      <iframe
        style={{ flex: 1 }}
        src={props.url}
        onLoad={() => props.onLoad({ nativeEvent: { url: props.url } })}
      />
    </div>
  );
}
