"""Compose docs/hero.png for the README from the real screenshots in docs/screenshots.

    pip install playwright && playwright install chromium
    python tool/make_hero.py
"""
import base64
import pathlib

from playwright.sync_api import sync_playwright

ROOT = pathlib.Path(__file__).resolve().parent.parent
SHOTS = ROOT / 'docs' / 'screenshots'
FONTS = ROOT / 'tool' / 'fonts'

# Turkish letters (ı ş ğ İ) live in the latin-ext subset, so both subsets are loaded.
LATIN = 'U+0000-00FF, U+0131, U+0152-0153, U+02BB-02BC, U+02C6, U+02DA, U+02DC, U+2000-206F, U+20AC, U+2122'
LATIN_EXT = 'U+0100-02AF, U+0304, U+0308, U+0329, U+1E00-1E9F, U+1EF2-1EFF, U+2020, U+20A0-20AB, U+20AD-20C0, U+2113, U+2C60-2C7F, U+A720-A7FF'


def b64(path):
    return base64.b64encode(path.read_bytes()).decode()


def font_faces():
    css = []
    for weight in (500, 700, 800):
        for subset, rng in (('latin', LATIN), ('latin-ext', LATIN_EXT)):
            data = b64(FONTS / f'manrope-{subset}-{weight}.woff2')
            css.append(f"@font-face {{ font-family: 'Manrope'; font-weight: {weight}; unicode-range: {rng}; "
                       f"src: url(data:font/woff2;base64,{data}) format('woff2'); }}")
    return '\n'.join(css)


def phone(name, extra=''):
    return (f'<div class="phone {extra}"><img src="data:image/png;base64,{b64(SHOTS / name)}"></div>')


HTML = f"""<!doctype html><html><head><meta charset="utf-8"><style>
{font_faces()}
* {{ box-sizing: border-box; margin: 0; }}
body {{ width: 1280px; height: 720px; overflow: hidden; position: relative;
       background: #F0F0EE; font-family: 'Manrope'; color: #1B2328; }}
.blob {{ position: absolute; right: -140px; top: -160px; width: 820px; height: 820px; border-radius: 50%;
        background: radial-gradient(circle at 40% 40%, #CFE3EB 0%, #DCEAEF 45%, rgba(240,240,238,0) 70%); }}
.left {{ position: absolute; left: 76px; top: 92px; width: 470px; }}
.kicker {{ display: inline-flex; gap: 10px; align-items: center; font-weight: 700; font-size: 14px;
          letter-spacing: .14em; text-transform: uppercase; color: #3B7A93; }}
.kicker i {{ width: 26px; height: 2px; background: #3B7A93; display: inline-block; }}
h1 {{ font-weight: 800; font-size: 86px; line-height: .95; letter-spacing: -.035em; margin-top: 22px; }}
h1 span {{ color: #3B7A93; }}
p {{ font-weight: 500; font-size: 22px; line-height: 1.45; color: #4A565C; margin-top: 24px; }}
.tags {{ display: flex; flex-wrap: wrap; gap: 10px; margin-top: 30px; }}
.tags b {{ font-weight: 700; font-size: 15px; background: #fff; padding: 9px 14px; border-radius: 12px; color: #2C3A40; }}
.phone {{ position: absolute; width: 268px; height: 580px; border-radius: 42px; background: #12181B; padding: 9px;
         box-shadow: 0 30px 60px rgba(28, 52, 62, .22), 0 6px 14px rgba(28,52,62,.10); }}
.phone img {{ width: 100%; height: 100%; object-fit: cover; object-position: top; border-radius: 34px; display: block; }}
.p1 {{ left: 560px; top: 104px; z-index: 2; }}
.p2 {{ left: 772px; top: 64px; z-index: 3; transform: rotate(2deg); }}
.p3 {{ left: 978px; top: 120px; z-index: 1; transform: rotate(5deg); }}
</style></head><body>
<div class="blob"></div>
<div class="left">
  <div class="kicker"><i></i>UNIDEV · Mobile App Assignment · 2025</div>
  <h1>UNIDEV<br><span>Notlar.</span></h1>
  <p>Not al, kategorilere ayır, tarih ekle. Takvim, geri sayım ve telefon hatırlatmalarıyla; tek kod tabanından Android, iOS ve web.</p>
  <div class="tags"><b>Flutter · Dart 3</b><b>Hive</b><b>Material 3</b><b>54 test</b></div>
</div>
{phone('01-home.png', 'p1')}
{phone('09-calendar.png', 'p2')}
{phone('10-upcoming.png', 'p3')}
</body></html>"""


def main():
    with sync_playwright() as p:
        browser = p.chromium.launch()
        page = browser.new_page(viewport={'width': 1280, 'height': 720}, device_scale_factor=2)
        page.set_content(HTML)
        page.wait_for_timeout(400)
        out = ROOT / 'docs' / 'hero.png'
        page.screenshot(path=str(out))
        browser.close()
    print(f'wrote {out.relative_to(ROOT)}')


if __name__ == '__main__':
    main()
