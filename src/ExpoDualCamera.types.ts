export type VideoGravity = 'resize' | 'resizeAspect' | 'resizeAspectFill';

export type Frame = {
  x: number;
  y: number;
  width: number;
  height: number;
};

export type DualCameraProps = {
  frontFrame: Frame;
  backFrame: Frame;
  frontGravity?: VideoGravity;
  backGravity?: VideoGravity;
  style?: object;
};
