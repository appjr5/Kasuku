"""Patches the freshly generated android/ folder: permissions, TTS query, minSdk 24, app label."""
import re, pathlib
root = pathlib.Path(__file__).resolve().parent.parent / "android" / "app"
man = root / "src" / "main" / "AndroidManifest.xml"
x = man.read_text()
add = ""
for p in ['android.permission.RECORD_AUDIO', 'android.permission.INTERNET', 'android.permission.MODIFY_AUDIO_SETTINGS']:
    if p not in x:
        add += f'    <uses-permission android:name="{p}"/>\n'
if "TTS_SERVICE" not in x:
    add += '    <queries>\n        <intent>\n            <action android:name="android.intent.action.TTS_SERVICE"/>\n        </intent>\n    </queries>\n'
if add:
    x = x.replace("<application", add + "    <application", 1)
x = re.sub(r'android:label="[^"]*"', 'android:label="Kasuku"', x, count=1)
man.write_text(x)
done = False
for name in ("build.gradle.kts", "build.gradle"):
    f = root / name
    if f.exists():
        g = f.read_text()
        g2 = re.sub(r'minSdk(Version)?\s*=?\s*flutter\.minSdkVersion', 'minSdk = 24' if name.endswith('kts') else 'minSdkVersion 24', g)
        f.write_text(g2); done = done or g2 != g
print("manifest patched; minSdk patched:", done)
