// Reexport the native module. On web, it will be resolved to ExpoDualCameraModule.web.ts
// and on native platforms to ExpoDualCameraModule.ts
export { default } from './ExpoDualCameraModule';
export { default as ExpoDualCameraView } from './ExpoDualCameraView';
export * from  './ExpoDualCamera.types';
