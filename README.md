# Wardrobe Stylist (Android, offline-first)

Atricent-style daily outfit suggestions from photos of your own wardrobe.
Everything — tagging, color analysis, outfit scoring, storage — runs on-device.

## Architecture
- **Flutter** (single codebase, Android-first)
- **Vision**: `tflite_flutter` (MobileNet labels: shirt/jeans/sneaker/...) + `palette_generator` (dominant hues) — fully offline
- **Storage**: Hive NoSQL + images in app documents dir — fully offline
- **Stylist engine**: color-theory scoring (complementary/analogous/triadic), formality vs occasion, weather layering, least-worn-first variety, your like/dislike feedback
- **Regular updates**: `workmanager` periodic task (every ~24h, network not required) → computes outfit of the day, stores it, local notification
- **Learning**: thumbs up/down + wear counts stored per item; next iteration can train weights from this history

## Setup
1. `flutter create wardrobe_stylist` (generates the android/ folder), then copy this `lib/`, `pubspec.yaml` into it.
2. Download the offline model (one-time, then the app never needs internet):
   - `curl -L -o assets/mobilenet_v1_1.0_224_quant.tflite https://storage.googleapis.com/download.tensorflow.org/models/mobilenet_v1_2018_08_02/mobilenet_v1_1.0_224_quant.tgz`
     (extract the .tflite from the tgz), or grab `mobilenet_v1_1.0_224_quant.tflite` + `labels.txt` from the tensorflow examples repo.
3. AndroidManifest.xml: add `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>` (Android 13+).
4. `flutter pub get && flutter run`

## How it maps to your ask
| Requirement | Implementation |
|---|---|
| Upload wardrobe photos | Gallery picker → on-device analysis → auto category + colors |
| Daily style suggestions | Stylist engine + daily background worker + notification |
| Offline mode | Hive + TFLite + palette extraction; zero network calls |
| Regular updates | WorkManager daily task; swap model/rules anytime for "updates" |

## Honest limitation vs Atricent
Real Atricent-grade styling uses large embedding models (e.g. CLIP/fashion transformers)
usually run in the cloud. This starter is deliberately 100% offline, so it uses
MobileNet labels + color theory. Next upgrades, in order of impact:
1. **CLIP-style embeddings** (on-device via ONNX/TFLite) for true "does this match" similarity
2. **Feedback learning** — learn per-user weights from like/dislike history (data already collected)
3. **Occasion/weather enrichment** when online (optional), still with offline fallback
