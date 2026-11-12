IRON KNIGHTS ALPHA - Web version (0.1.0-alpha)

Browsers block web games opened straight from a file, so double-clicking index.html will NOT work.
Run it from a small web server instead:

OPTION A (Python installed):
  1. Open a command prompt in this folder (type cmd in the Explorer address bar).
  2. Run:  python -m http.server 8000
  3. Open http://localhost:8000 in Chrome, Edge or Firefox.

OPTION B (Node installed):  npx http-server -p 8000   then open http://localhost:8000

OPTION C: zip this folder and upload it to itch.io as an HTML game (tick 'This file will be played in the browser').

Notes: first load takes a while (about 140 MB). The web version runs slower than the Windows build; use a desktop browser.
Controls are the same as the Windows build (see README in the Windows build folder).
