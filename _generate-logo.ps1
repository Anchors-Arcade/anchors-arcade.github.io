# Builds the "Anchors Arcade" logo:
#   logo.svg      - theme-aware vector rum bottle (accent parts use CSS vars; recolors with the site theme)
#   favicon.png   - user-provided raster artwork (NOT regenerated here)
#   logo.png      - user-provided raster artwork (NOT regenerated here)
#
# Geometry mirrors the hand-made bottle artwork in logo.png:
# dark flask-shaped body with accent outline, accent cap with dark slot,
# accent label band with black star, light highlight stripe, four accent bubbles.

$ErrorActionPreference = 'Stop'
$dir = $PSScriptRoot

$acc     = 'var(--acc, #a855f7)'        # outline, cap, label band, bubbles (theme accent)
$accDeep = 'var(--acc-deep, #6b21a8)'   # cap slot (theme deep accent)
$dark    = '#171219'                    # body fill / cap border (fixed dark)
$star    = '#0d0b10'                    # label star (fixed near-black)
$light   = '#c9c9d1'                    # highlight stripe (fixed light grey)

# five-point star, point up, center (256,357), outer R 50 / inner r 21
$starPath = 'M256 307 L268.3 340 L303.6 341.6 L276 363.5 L285.4 397.4 L256 378 L226.6 397.4 L236 363.5 L208.4 341.6 L243.7 340 Z'

# flask body: neck under the cap, S-curve shoulders, straight sides, rounded bottom
$bodyPath = 'M215 86 L215 168 C215 200 157 208 157 245 L157 432 Q157 468 192 468 L320 468 Q355 468 355 432 L355 245 C355 208 297 200 297 168 L297 86 Z'

$svg = @"
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
  <!-- bubbles -->
  <circle cx="82" cy="148" r="6" fill="$acc"/>
  <circle cx="106" cy="198" r="13" fill="none" stroke="$acc" stroke-width="7"/>
  <circle cx="430" cy="96" r="10" fill="none" stroke="$acc" stroke-width="6"/>
  <circle cx="396" cy="148" r="17" fill="none" stroke="$acc" stroke-width="8"/>
  <!-- body: dark flask with accent outline -->
  <path d="$bodyPath" fill="$dark" stroke="$acc" stroke-width="11" stroke-linejoin="round"/>
  <!-- label band -->
  <rect x="152" y="305" width="208" height="107" fill="$acc"/>
  <!-- star -->
  <path d="$starPath" fill="$star"/>
  <!-- highlight stripe -->
  <rect x="181" y="232" width="21" height="58" rx="10" fill="$light"/>
  <!-- cap -->
  <rect x="205" y="40" width="102" height="52" rx="14" fill="$acc" stroke="$dark" stroke-width="8"/>
  <rect x="226" y="60" width="60" height="12" rx="6" fill="$accDeep"/>
</svg>
"@

Set-Content -Path (Join-Path $dir 'logo.svg') -Value $svg -Encoding UTF8
Write-Output 'logo.svg written (theme-aware rum bottle; PNGs left untouched)'
