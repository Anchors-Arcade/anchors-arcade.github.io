# Regenerates games.js (the GAMES data array used by index.html / app.js) for the Julmust hub.
# Re-run any time you add/remove game files (run _generate-covers.ps1 first for new covers).
# index.html, style.css and app.js are hand-maintained and are no longer generated.

$ErrorActionPreference = 'Stop'
$dir = $PSScriptRoot
$coversDir = Join-Path $dir 'covers'


# ---- real game names, extracted from <base href> / CDN repo URLs ----
$genericRepos = @('web-ports','web-port','gameports','games','game','brainrot','assets','asset','ugss','ugs-assets','elitecomposite','selenite','selenite-old','google-class','google-classic','cc3d-mobile','poki-sdk','poki','whatver','cg-rip','unblocked-games','unblockedgames','some-repo','gstore','flashgames','youtube','youtube-playables','playables','fnaf','ports','game-webports-onawebsite','interstellar-3','interstellar','ugs-file-encryption','emujs','emu','emu-updated','seraph','ruffle-embedded','unknown')
$containers   = @('play','dist','build','game','games','files','file','web','www','misc','unity','swfs','roms','dos','out','public','html','bin','src','projects','new','final','demo','versions','version','main','master','cdn','static','dl','dl2','dl3','dl4','flash','storage','emulatorjs','data')
$overrides = @{
    # known proper titles for slugs that title-casing gets wrong
    'sm64'='Super Mario 64'; 'ucn'='Ultimate Custom Night'; 'iwbtg'='I Wanna Be The Guy'
    'henry-stickman'='Henry Stickmin'; 'cookieclicker'='Cookie Clicker'; 'buildnow-gg'='BuildNow GG'
    'justfalllol'='JustFall.LOL'; 'gdlite'='Geometry Dash Lite'; 'off'='OFF'
    's.p.l.i.t'='SPLIT'; 'imposter-bside'='Imposter B-Side'; 'bside'='B-Side'; 'd-sides'='D-Sides'
    'fnaw'="Five Nights at Wario's"; 'rigbmx'='Rig BMX'; 'rigbmx2'='Rig BMX 2'
    'fnaf-world-refreshed'='FNaF World: Refreshed'; 'fnaf-into-the-pit'='FNaF: Into The Pit'
    # repo/subdir combos (generic repo whose subdir is a variant)
    'fnaf-1'="Five Nights at Freddy's"; 'fnaf-2'="Five Nights at Freddy's 2"
    'fnaf-3'="Five Nights at Freddy's 3"; 'fnaf-4'="Five Nights at Freddy's 4"
    'fnaf-4-halloween'="FNaF 4: Halloween Edition"; 'fnaf-sl'="FNaF: Sister Location"
    'fnaf-w'="FNaF World"; 'fnaf-ps'="FNaF: Pizzeria Simulator"; 'fnaf-ucn'="Ultimate Custom Night"
    'x3m'='X3M'; 'x3m-2'='X3M 2'; 'ovo'='OvO'; 'gladihoppper'='Gladihopper'
    'feed-and-grow'='Feed and Grow: Fish'; 'tf2'='Team Fortress 2'; 'tf-2'='Team Fortress 2'
    'helltakerweb'='Helltaker'; 'omori'='OMORI'
    'pokemon-heart-gold-version'='Pokémon HeartGold'
    'fnf'="Friday Night Funkin'"; 'fridayfunk'="Friday Night Funkin'"; 'fnfmods'='FNF Mods'
    'osu'='osu!'
    'bloonstd1'="Bloons Tower Defense 1"; 'bloonstd2'="Bloons Tower Defense 2"; 'bloonstd3'="Bloons Tower Defense 3"
    'learn-2-fly-2'="Learn To Fly 2"; 'learn2fly2'="Learn To Fly 2"
    'ducklife2'="Duck Life 2"; 'ducklife2worldchampion'="Duck Life 2"; 'ducklife3game'="Duck Life 3"
    'an_ordinary_sonic_rom_hack_cinossu_shc2013'="Sonic.Exe"
    'tosstheturtle'="Toss the Turtle"; 'mad2'='MAD 2'
    'redball1'="Red Ball 1"; 'redball2'="Red Ball 2"
    'red ball - definitive edition'="Red Ball 1"; 'red ball 2 - definitive edition'="Red Ball 2"
    'fpaworld4p1'='FPA World 4 Part 1'
    # junk repo/slug names -> leave the game unnamed
    'new'=''; 'test'=''; 'files'=''; 'file'=''; 'sdk'=''; 'swf'=''; 'j'=''; 'bl'=''; 'cl'=''
    'draw-cl'=''; 'port'=''; 'repo'=''; 'untitled'=''; 'flash-games'=''; 'html5games'=''
    'html-5-games'=''; 'unblocked-games'=''; 'unblockedgames'=''   # also in $genericRepos (subdir wins)
    'poki-sdk'=''; 'portsv'=''; 'lumassets'=''; 'portsv-4'=''; 'loader'=''; 'loaderjs'=''; 'js'=''; 'cloak'=''
}
# per-file name fixes (no slug to extract from)
$fileOverrides = @{
    '777-fix2.html'='Outhold'
    '107-fix2.html'='This Is The Only Level 2'
    '592-fix3.html'="Pac Man World"
}

function ConvertTo-GameTitle([string]$slug) {
    if (-not $slug) { return '' }
    $slug = ($slug -replace '@[^/]*$','')          # strip jsdelivr @branch/@commit
    $s = $slug
    $s = $s -creplace '\.(swf|html?|js|data|wasm|unityweb|bin|rom|gba|gbc|gb|nds|smc|sfc|nes|zip|chd|iso|cue|md|7z)$',''
    $s = $s -creplace '^\d+_+',''                  # 593275_FPAWorld3 -> FPAWorld3
    $s = $s -creplace '^[-_ ]+',''                 # -3 -> 3 (then digits-only -> unnamed)
    $s = $s -ireplace '[-_ ]+(main|port|web|build|html|copy|fixed|offline|full|secure|updated|update|upd3)$','' # junk tails
    $s = $s -creplace '^[-_ ]+',''
    $s = $s -creplace '^(secure|new)[-_ ]+',''
    if (-not $s -or $s -cmatch '^\d+$') { return '' }
    $key = $s.ToLower()
    if ($overrides.ContainsKey($key)) { return $overrides[$key] }
    $s = $s -replace '[-_+]+',' '
    $s = $s -creplace '(?<=[a-z0-9])(?=[A-Z])',' '   # camelCase split
    $s = $s -creplace '(?<=[A-Z])(?=[A-Z][a-z])',' ' # FPAWorld -> FPA World
    $s = $s -creplace '(?<=[A-Za-z])(?=\d)|(?<=\d)(?=[A-Za-z])',' ' # World3 -> World 3
    $s = ($s -split '\s+' | Where-Object { $_ }) -join ' '
    if (-not $s) { return '' }
    $s = $s -ireplace ' (main|port|web|build|html|copy|fixed|offline|full|secure|updated|update|upd3)$',''  # post-split junk tails
    $s = $s -ireplace '\b(\d+) D\b','$1D'                                       # 3 D -> 3D
    $words = @($s -split '\s+' | Where-Object { $_ })
    if ($words.Count -ge 6) {                                                   # hash-like slug -> unnamed
        $short = @($words | Where-Object { $_.Length -le 2 }).Count
        if ($short * 2 -ge $words.Count) { return '' }
    }
    $res = New-Object System.Collections.Generic.List[string]
    foreach ($w in ($s -split '\s+')) {
        if ($w -ieq 'io' -and $res.Count -gt 0) { $res[$res.Count-1] += '.io' }   # slime io -> Slime.io
        elseif ($w -cmatch "^[A-Z0-9.&'/]{1,4}$") { $res.Add($w) }                # keep short acronyms
        else { $res.Add((Get-Culture).TextInfo.ToTitleCase($w.ToLower())) }
    }
    return ($res -join ' ').Trim()
}

function Get-SlugFromUrl([string]$url) {
    if (-not $url) { return '' }
    try { $u = [uri]::UnescapeDataString($url) } catch { $u = $url }
    $u = ($u -replace '[?#].*$','').TrimEnd('/')
    $segs = @(($u -replace '^https?://[^/]+/?','') -split '/' | Where-Object { $_ })
    if ($segs.Count -eq 0) { return '' }
    if ($segs[0] -ieq 'gh') { $segs = @($segs | Select-Object -Skip 1) }
    if ($segs.Count -eq 0) { return '' }
    if ($segs.Count -eq 1) { return ConvertTo-GameTitle $segs[0] }
    $repo = ($segs[1] -replace '@.*$','').ToLower()
    $rest = @($segs | Select-Object -Skip 2)
    # githack-style branch/commit marker
    if ($rest.Count -gt 0 -and ($rest[0] -ieq 'main' -or $rest[0] -ieq 'master' -or $rest[0] -cmatch '^[0-9a-f]{40}$')) {
        $rest = @($rest | Select-Object -Skip 1)
    }
    if ($genericRepos -cnotcontains $repo) { return ConvertTo-GameTitle $repo }
    foreach ($sg in $rest) {                        # generic repo -> use first non-container subdir
        if ($containers -cnotcontains $sg.ToLower()) {
            $key = ($repo + '-' + ($sg -replace '@.*$','')).ToLower()
            if ($overrides.ContainsKey($key)) { return $overrides[$key] }   # fnaf/2 -> Five Nights at Freddy's 2
            $t = ConvertTo-GameTitle $sg
            if ($t) { return $t }                   # skip junk segs, keep scanning
        }
    }
    return ''
    return ''
}

function Get-GameTitleFromHtml([string]$content) {
    $urls = [regex]::Matches($content, 'https?://(?:[a-z0-9.-]*jsdelivr\.net|[a-z0-9.-]*githack\.com|raw\.githubusercontent\.com)/[^\s"''<>\\]+') | ForEach-Object { $_.Value }
    # EmuJS / emulator loaders carry the real game name in their config
    $m = [regex]::Match($content, 'EJS_gameName\s*=\s*"([^"]{2,80})"')
    if ($m.Success) {
        $t = $m.Groups[1].Value.Trim()
        while ($t -cmatch '\s*\([^)]+\)$') { $t = $t -creplace '\s*\([^)]+\)$','' }   # strip region/disc tags
        $t = ($t -replace '\.(gba|gbc|gb|nds|smc|sfc|nes|zip|chd|bin|iso|cue|md)$','').Trim()
        if ($t) { return $t.Trim() }
    }
    $m = [regex]::Match($content, 'gameconfig\s*=\s*\{[^}]*?name\s*:\s*"([^"]{2,80})"')
    if ($m.Success) {
        $t = $m.Groups[1].Value.Trim()
        while ($t -cmatch '\s*\([^)]+\)$') { $t = $t -creplace '\s*\([^)]+\)$','' }
        $t = ($t -replace '\.(gba|gbc|gb|nds|smc|sfc|nes|zip|chd|bin|iso|cue|md)$','').Trim()
        if ($t) { return $t.Trim() }
    }
    # emulator rom archives — the filename is the game
    foreach ($u in $urls) {
        if ($u -imatch '\.(zip|chd|bin|gba|gbc|gb|nds|smc|sfc|nes|iso|cue|md|7z)([?#]|$)') {
            try { $t = [uri]::UnescapeDataString([io.path]::GetFileName(($u -replace '\\','/'))) } catch { $t = '' }
            $t = ($t -ireplace '\.(zip|chd|bin|gba|gbc|gb|nds|smc|sfc|nes|iso|cue|md|7z)$','').Trim()
            while ($t -cmatch '\s*\([^)]+\)$') { $t = $t -creplace '\s*\([^)]+\)$','' }   # strip region/disc tags
            $t = $t.Trim()
            if ($t -and $t.Length -ge 3) { return $t.Trim() }
        }
    }
    $m = [regex]::Match($content, '<base\s+href\s*=\s*"([^"]+)"')
    if ($m.Success) { $t = Get-SlugFromUrl $m.Groups[1].Value; if ($t) { return $t } }
    $urls = [regex]::Matches($content, 'https?://(?:[a-z0-9.-]*jsdelivr\.net|rawcdn\.githack\.com|raw\.githubusercontent\.com)/[^\s"''<>()\\]+') | ForEach-Object { $_.Value }
    foreach ($u in $urls) { $t = Get-SlugFromUrl $u; if ($t) { return $t } }
    # last resort: SWF filename (ruffle/flash wrappers) — the basename is the real game
    foreach ($u in $urls) {
        if ($u -imatch '\.swf($|[?&#])') {
            try { $dec = [uri]::UnescapeDataString($u) } catch { $dec = $u }
            $b = (($dec -replace '[?#].*$','').Split('/')[-1]) -ireplace '\.swf$',''
            if ($b -and $b.Length -ge 3) {
                $t = ConvertTo-GameTitle $b
                if ($t -and $t -cnotmatch '^(Game|Swf|Loader|Preloader|File|Test|Untitled)$') { return $t }
            }
        }
    }
    $m = [regex]::Match($content, 'eaglercraft\.dev/downloads/([^/''"\s]+?)\.html')
    if ($m.Success) { $t = ConvertTo-GameTitle $m.Groups[1].Value; if ($t) { return $t } }
    return ''
}

# ---- collect game files (skip the launcher itself) ----
$set = @{}
if (Test-Path $coversDir) {
    Get-ChildItem $coversDir -File | ForEach-Object { $set[$_.Name] = $true }
}

$games = Get-ChildItem -Path $dir -File |
    Where-Object { $_.Name -cne 'index.html' -and $_.Name -cmatch '\.html' }

$items = foreach ($f in $games) {
    $base = $f.Name -replace '\.html$',''
    $n = 999999; $s = ''
    if ($base -cmatch '^(\d+)[-.](.+)$') { $n = [int]$matches[1]; $s = $matches[2] }
    elseif ($base -cmatch '^(\d+)$')     { $n = [int]$matches[1] }
    if ($s -cmatch '^html[-.]?(.*)$') { $s = $Matches[1] }   # 615.html-a -> variant 'a'

    # cover resolution: exact number+suffix jpg, then plain number jpg, then any other format (png/gif/webp/avif)
    $c = $null
    if ($s -ne '' -and $set.ContainsKey(("{0}-{1}.jpg" -f $n, $s))) { $c = "covers/{0}-{1}.jpg" -f $n, $s }
    elseif ($set.ContainsKey(("{0}.jpg" -f $n))) { $c = "covers/{0}.jpg" -f $n }
    else {
        $alt = $set.Keys |
            Where-Object { $_ -cmatch ('^' + [regex]::Escape([string]$n) + '\.(png|gif|webp|avif|jpe?g|bmp)$') } |
            Sort-Object | Select-Object -First 1
        if ($alt) { $c = "covers/$alt" }
    }
    $content = Get-Content $f.FullName -Raw
    $title = if ($fileOverrides.ContainsKey($f.Name)) { $fileOverrides[$f.Name] } else { Get-GameTitleFromHtml $content }
    [pscustomobject]@{ F = $f.Name; N = $n; S = $s; C = $c; T = $title }
}
$sorted = $items | Sort-Object N, F

# ---- home-made games (own Unity/web builds copied from Downloads\GAMES) ----
$ownSrc = 'C:\Users\alveb\Downloads\GAMES'
$ownDefs = @(
    @{ folder='anchorsworld'; name='Anchors World';        je='\uD83C\uDF0D' }  # globe
    @{ folder='fort';         name='Fort';                 je='\uD83C\uDFF0' }  # castle
    @{ folder='ironknights';  name='Iron Knights';         je='\u2694\uFE0F' }  # crossed swords
    @{ folder='mobilegame';   name='Mobilegame';           je='\uD83D\uDCF1' }  # phone
    @{ folder='musspel';      name='Mouse Quest Ultimate'; je='\uD83D\uDC2D' }  # mouse
)
$ownReady = @()
foreach ($o in $ownDefs) {
    $src = Join-Path $ownSrc $o.folder
    if (-not (Test-Path (Join-Path $src 'index.html'))) { Write-Output ("skip (no source): {0}" -f $o.folder); continue }
    $dst = Join-Path $dir ('mygames\' + $o.folder)
    if (-not (Test-Path (Join-Path $dst 'index.html'))) {
        robocopy $src $dst /E /XD .git /NFL /NDL /NJH /NJS /NP | Out-Null
    }
    if (Test-Path (Join-Path $dst 'index.html')) { $ownReady += $o }
    else { Write-Output ("skip (copy failed): {0}" -f $o.folder) }
}
$ownLines = foreach ($o in $ownReady) {
    '  {{f:"mygames/{0}/index.html",n:null,s:"",t:"{1}",c:null,e:"{2}",o:1}}' -f $o.folder, $o.name, $o.je
}

# ---- build the JS array ----
$nl = [Environment]::NewLine
$lines = foreach ($g in $sorted) {
    $f = $g.F -replace '\\','\\\\' -replace '"','\"'
    $s = $g.S -replace '\\','\\\\' -replace '"','\"'
    $t = $g.T -replace '\\','\\\\' -replace '"','\"'
    $c = if ($g.C) { '"' + $g.C + '"' } else { 'null' }
    '  {{f:"{0}",n:{1},s:"{2}",t:"{3}",c:{4}}}' -f $f, $g.N, $s, $t, $c
}
$arr = '[' + $nl + (($lines + $ownLines) -join (',' + $nl)) + $nl + ']'

$js = 'const GAMES = ' + $arr + ';' + $nl
[IO.File]::WriteAllText((Join-Path $dir 'games.js'), $js, (New-Object System.Text.UTF8Encoding($false)))

$withCovers = @($sorted | Where-Object { $_.C }).Count
$named = @($sorted | Where-Object { $_.T }).Count
Write-Output ("games.js generated: {0} games, {1} with covers, {2} named" -f $sorted.Count, $withCovers, $named)

# full mapping for inspection (not part of the site)
$prev = $sorted | ForEach-Object { "{0,-4}  {1}" -f $_.N, $_.T }
$prev | Set-Content -Path (Join-Path $env:TEMP 'opencode\names-preview.txt') -Encoding UTF8
$sorted | ForEach-Object { "{0}`t{1}" -f $_.F, $_.T } |
    Set-Content -Path (Join-Path $env:TEMP 'opencode\file-titles.txt') -Encoding UTF8
Write-Output "sample:"
$sorted | Where-Object { $_.T } | Select-Object -First 12 | ForEach-Object { Write-Output ("  {0} -> {1}" -f $_.F, $_.T) }
