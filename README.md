# Kasuku (working title, Swahili-first)

Mwalimu Neema (placeholder name, change `Coach.name`) teaches Spanish, Japanese, Mandarin and Russian **through Swahili**: kind to kids,
strict about pronunciation. This drop is the full app: Swahili curriculum built from the four Foundations Guides
(23 lessons incl. 6 Russian), flashcards (spaced repetition), speaking + writing drills, Mandarin Tone Gym,
unit quizzes with stars, a pre-lesson **memory check**, daily review, stories and songs.
The old Core Lab is kept for developers: Settings -> *Maabara ya majaribio*.

## Run it
```bash
./setup.sh            # creates android/, patches permissions + minSdk 24, pub get, analyze, flutter test
flutter run --release # on your phone (debug builds are far too slow for Whisper)
flutter build apk --release --split-per-abi   # the APK: build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

## The brain, two layers, no switches
| Layer | What | When |
|---|---|---|
| **Tip bank** (Phase 1, in this drop) | `assets/content/tips_sw.json`: Swahili coaching tips chosen by *what went wrong* (nothing / too short / too long / wrong sound / nearly) and by language, plus the word's own note. Authored, then extended offline with swahili-gemma-1b via `tool/gen_tips.py`. | instant, offline, cannot crash |
| **Live Gemma** (Phase 2) | swahili-gemma-1b on-device in a separate Android process (`:brain`) so a native crash cannot take the app down. Prefetches a fresh tip in the background; it replaces the bank tip on the learner's *next* failed try. | invisible: no toggle, no waiting, no retry logic. `BrainClient` in `brain.dart` is the seam; today `NullBrain`. |

## The voice stack
| Part | What |
|---|---|
| **Ears** | Whisper **tiny** (whisper.cpp ggml from `ggerganov/whisper.cpp` on Hugging Face, ~75 MB, offline after first download) hears you say es/ja/zh/ru |
| **Mouth** | Android system TTS: Swahili for the teacher, es/ja/zh/ru for the words. No Swahili voice? A button opens Android's voice installer and the app re-checks when you come back. Phase 3: in-app Swahili voice add-on (MMS-TTS, non-commercial licence) for phones without Google speech. |
| **Tone ear** | `pitch.dart`: autocorrelation pitch tracker; Whisper "auto-corrects" Mandarin tones, so tones are judged from your pitch contour |

## Files
`models.dart` (Swahili fields win, English fallback) | `store.dart` (XP/streak, spaced repetition, memory pool, stars) |
`scoring.dart` (normalise + score + `diagnose`) | `coach.dart` (personality) | `tips.dart` (bank + TipService) |
`brain.dart` (seam) | `audio.dart` | `pitch.dart` | `test/core_test.dart` (`flutter test`)

## Honest limits
- Not compiled here (no Flutter SDK in my sandbox). Syntax-checked; tone logic verified in a Python port (36/36
  synthetic voices; real voices are messier). `flutter analyze` may flag plugin-API details
  (`whisper_flutter_new` `TranscribeRequest`). Send me the output.
- `tool/gen_tips.py` is untested (no Hugging Face access from my sandbox). Review its output as a Swahili speaker.
- Whisper-tiny is weak on Mandarin and Russian (`base`, ~140 MB, is the upgrade). It scores *what it understood*, not an accent grade.
- Songs via TTS are rhythmic chanting, not singing.

## Curriculum
`tool/build_content.py` -> `assets/content/{es,ja,zh,ru}.json`. Swahili is primary; English is kept per item (`m`) for reference
and for `tool/gen_tips.py review`. **Have a Swahili speaker review the Swahili before release.**

## Licences to track (you plan to go commercial)
Whisper / whisper.cpp: MIT. ML Kit Digital Ink: Google ML Kit terms. Gemma (Phase 2): Gemma Terms of Use, check redistribution.
MMS-TTS Swahili voice (Phase 3): CC-BY-NC, non-commercial only, keep it swappable.

## The teacher character
`lib/teacher.dart` draws her in code: an original flat illustration of a Black African woman teacher (patterned headwrap,
glasses, gold earrings) with six moods. No third-party art, no mascot borrowed from any brand. It is a simple placeholder:
for the real launch commission an illustrator (ideally from your target community) and swap `TeacherPainter` for their images.
Rename the app and the Android id (`com.happiness.kasuku`) before publishing: the id is permanent on Google Play.
