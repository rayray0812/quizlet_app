# On-Device Gemma POC

## Current status

The app now includes an Android method channel scaffold for on-device AI:

- Flutter service: `lib/services/on_device_ai_service.dart`
- Android bridge: `android/app/src/main/kotlin/com/studyapp/recall_app/OnDeviceAiChannel.kt`

This is **not yet running Gemma 4 locally**. It only prepares the app to detect
Android-side readiness and gives us a stable place to wire AICore or LiteRT-LM next.

## What you need to prepare manually

### Preferred path: Android AICore Developer Preview

1. Use an Android phone that is suitable for current on-device AI previews.
   Android 14+ is the practical baseline.
2. Join the AICore / on-device AI developer preview if Google requires access.
3. Install any required system components or model packs on the device.
4. Keep enough free storage for model downloads.

### Fallback path: self-bundled LiteRT-LM

If AICore preview is unavailable on your device, we can switch to a self-managed
runtime later, but that will require:

1. Picking a concrete Gemma edge model size.
2. Downloading model weights manually.
3. Packaging or side-loading those weights.
4. Adding native runtime dependencies and memory management.

## Next implementation step

Once the device path is confirmed, wire one of these:

- AICore `GenerativeModel` for system-managed Gemma.
- LiteRT-LM for app-managed local inference.

The first real feature target should be:

- `OCR -> on-device Gemma -> vocabulary JSON`

Do **not** start with full conversation generation.
