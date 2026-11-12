$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$prefix = 'http://localhost:8765/'

# if the arcade is already being served, this instance exits quietly
$existing = Get-NetTCPConnection -LocalPort 8765 -State Listen -ErrorAction SilentlyContinue
if ($existing) {
    Write-Output "Port 8765 already in use - Julmust Arcade is probably already running. Closing."
    Start-Sleep -Seconds 3
    exit
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($prefix)
$listener.Start()
Write-Output "Serving Julmust Arcade ($root) at $prefix  -  keep this window open while playing"

$mime = @{
    '.html' = 'text/html; charset=utf-8'; '.png' = 'image/png'; '.jpg' = 'image/jpeg'
    '.jpeg' = 'image/jpeg'; '.gif' = 'image/gif'; '.webp' = 'image/webp'
    '.avif' = 'image/avif'; '.js' = 'text/javascript'; '.mjs' = 'text/javascript'
    '.css' = 'text/css'; '.ico' = 'image/x-icon'; '.svg' = 'image/svg+xml'
    '.txt' = 'text/plain'; '.wasm' = 'application/wasm'
    '.json' = 'application/json'; '.data' = 'application/octet-stream'
    '.unityweb' = 'application/octet-stream'; '.br' = 'application/octet-stream'
}
# Unity WebGL builds: .br/.gz files must be served with the matching Content-Encoding
$enc = @{ '.br' = 'br'; '.gz' = 'gzip' }
$rootFull = [IO.Path]::GetFullPath($root)

while ($listener.IsListening) {
    $ctx = $listener.GetContext()
    try {
        $path = [uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath)   # Unity builds contain spaces
        if ($path -eq '/') { $path = '/index.html' }
        $file = [IO.Path]::GetFullPath((Join-Path $rootFull ($path.TrimStart('/') -replace '/', '\')))
        if (-not $file.StartsWith($rootFull)) { $ctx.Response.StatusCode = 403 }
        elseif (Test-Path $file -PathType Leaf) {
            $ext = [IO.Path]::GetExtension($file).ToLower()
            $ctx.Response.ContentType = if ($mime.ContainsKey($ext)) { $mime[$ext] } else { 'application/octet-stream' }
            if ($enc.ContainsKey($ext)) { $ctx.Response.Headers['Content-Encoding'] = $enc[$ext] }
            # brotli-compressed wasm: correct MIME enables streaming compilation after decoding
            if ($file -match '\.wasm\.br$') { $ctx.Response.ContentType = 'application/wasm' }
            $bytes = [IO.File]::ReadAllBytes($file)
            $ctx.Response.ContentLength64 = $bytes.Length
            if ($ctx.Request.HttpMethod -ne 'HEAD') { $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length) }
        }
        else { $ctx.Response.StatusCode = 404 }
    }
    catch { try { $ctx.Response.StatusCode = 500 } catch {} }
    finally { try { $ctx.Response.OutputStream.Close() } catch {} }
}