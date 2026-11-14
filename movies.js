"use strict";
/* =====================================================================
   Julmust Movies — TMDB-powered movie discovery (replaces the old
   proxied flixer.gd tab). Vanilla JS, no build step.
   Loaded by index.html after app.js; all data comes from api.themoviedb.org.

   ── API KEY CONFIG ──────────────────────────────────────────────────
   Paste your rotated TMDB v3 API key on the API_KEY line below.

   NOTE: this site is static (GitHub Pages), so the v3 key is publicly
   visible in this file to anyone who loads the page. That is expected —
   TMDB allows browser apps to ship the v3 key, as long as the key is
   not abused. Keep your v4 API Read Access Token (the long bearer
   token) private and NEVER put it in this file or commit it anywhere.

   TMDB provides metadata and images only — there are no full-length
   movie streams here. Details views may embed official YouTube trailers
   (via TMDB's video data). Plug a legitimate video source in later if
   you ever get one.
   ===================================================================== */

window.Movies = (function () {

  /* ============================== CONFIG ============================== */
  const API_KEY = "1cc02ad325e995507263ab6523eab061";
  const API = "https://api.themoviedb.org/3";
  const IMG = "https://image.tmdb.org/t/p";
  const LIST_TTL = 60 * 60e3;      // list endpoints cached 1 hour
  const DETAIL_TTL = 6 * 3600e3;   // movie details cached 6 hours
  const PAGE = 20;                 // TMDB page size

  const keyOk = () => API_KEY && API_KEY !== "1cc02ad325e995507263ab6523eab061" && API_KEY.length >= 20;

  /* ============================== HELPERS ============================== */
  const $ = id => document.getElementById(id);
  const esc = s => String(s ?? "").replace(/[&<>"']/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
  const lsGet = (k, d) => { try { const v = localStorage.getItem(k); return v === null ? d : JSON.parse(v); } catch (e) { return d; } };
  const lsSet = (k, v) => { try { localStorage.setItem(k, JSON.stringify(v)); } catch (e) {} };
  const year = d => (d || "").slice(0, 4);
  const fmtRating = v => v ? (Math.round(v * 10) / 10).toFixed(1) : "—";
  const fmtRuntime = m => m ? (m >= 60 ? Math.floor(m / 60) + "h " + (m % 60) + "m" : m + "m") : "";
  const fmtDate = d => {
    if (!d) return "";
    const dt = new Date(d + "T00:00:00");
    return isNaN(dt) ? d : dt.toLocaleDateString(undefined, { year: "numeric", month: "long", day: "numeric" });
  };
  const posterUrl = (p, s) => p ? IMG + "/w" + (s || 342) + p : null;
  const backdropUrl = (p, s) => p ? IMG + "/" + (s || "w1280") + p : null;

  /* ============================== STATE ============================== */
  const state = {
    init: false,
    genres: new Map(),           // id -> name
    watchlist: lsGet("jm_watchlist", []),
    seed: lsGet("jm_seed", null), // last opened movie {id,title}, seeds recommendations
    popularSeed: null,            // fallback seed while nothing has been opened
    wlOnly: false,                // toolbar watchlist filter
    search: { q: "", page: 0, total: 0, reqId: 0 },
    genre: { id: 0, page: 0, total: 0 },
  };

  /* ============================== CACHE ============================== */
  const CACHE_KEY = "jm_tmdb_v1";
  const mem = new Map();

  function cacheGet(url, ttl) {
    const r = mem.get(url);
    if (r && Date.now() - r.t < ttl) return r.d;
    const e = lsGet(CACHE_KEY, {})[url];
    if (e && Date.now() - e.t < ttl) { mem.set(url, e); return e.d; }
    return null;
  }

  function cachePut(url, d) {
    const e = { t: Date.now(), d };
    mem.set(url, e);
    const s = lsGet(CACHE_KEY, {});
    const keys = Object.keys(s);
    if (keys.length >= 80) {                       // prune oldest, keep it small
      keys.sort((a, b) => (s[a].t || 0) - (s[b].t || 0));
      for (const k of keys.slice(0, keys.length - 60)) delete s[k];
    }
    s[url] = e;
    lsSet(CACHE_KEY, s);
  }

  /* ============================== API ============================== */
  function fullUrl(path, params) {
    const u = new URL(API + path);
    u.searchParams.set("api_key", API_KEY);
    if (params) for (const [k, v] of Object.entries(params)) if (v != null && v !== "") u.searchParams.set(k, v);
    return u.toString();
  }

  async function fetchJSON(url, retried) {
    let res;
    try { res = await fetch(url, { headers: { Accept: "application/json" } }); }
    catch (e) { throw new Error("Network error — could not reach TMDB."); }
    if (res.status === 401) throw new Error("TMDB rejected the API key (401). Double-check the key in movies.js.");
    if (res.status === 429 && !retried) {          // rate limited: wait out the Retry-After once
      const wait = Math.min(parseFloat(res.headers.get("Retry-After")) || 2, 8);
      await new Promise(r => setTimeout(r, wait * 1000));
      return fetchJSON(url, true);
    }
    if (!res.ok) throw new Error("TMDB request failed (" + res.status + "). Try again in a moment.");
    return res.json();
  }

  async function tmdb(path, params, ttl) {
    const url = fullUrl(path, params);
    const hit = cacheGet(url, ttl || LIST_TTL);
    if (hit) return hit;
    const d = await fetchJSON(url);
    cachePut(url, d);
    return d;
  }

  /* ============================== CARD FACTORY ============================== */
  const ICON_HEART = '<svg class="ico" aria-hidden="true"><use href="#i-heart"/></svg>';

  function genresOf(m) {
    if (Array.isArray(m.genres)) return m.genres.map(g => g.name).filter(Boolean);
    if (Array.isArray(m.genre_ids)) return m.genre_ids.map(id => state.genres.get(id)).filter(Boolean);
    return [];
  }

  function cardSub(m) {
    const parts = [year(m.release_date), genresOf(m).slice(0, 2).join(", ")].filter(Boolean);
    return parts.join(" · ");
  }

  function posterHTML(m, size) {
    const src = posterUrl(m.poster_path, size);
    const initial = esc(String(m.title || m.original_title || "?").charAt(0).toUpperCase());
    return src
      ? '<img class="mdyn" loading="lazy" decoding="async" data-fb="' + initial + '" src="' + esc(src) + '" alt="">'
      : '<div class="mfb"><span>' + initial + '</span></div>';
  }

  function hookImgs(scope) {
    for (const img of scope.querySelectorAll("img.mdyn")) {
      img.addEventListener("load", () => img.classList.add("ok"));
      img.addEventListener("error", () => {
        const fb = document.createElement("div");
        fb.className = "mfb";
        fb.innerHTML = "<span>" + (img.dataset.fb || "?") + "</span>";
        img.replaceWith(fb);
      });
    }
  }

  function makeCard(m) {
    const el = document.createElement("div");
    el.className = "mcard";
    el.dataset.mid = m.id;
    el.innerHTML =
      '<button type="button" class="mcard-link" title="' + esc(m.title || "Untitled") + ' — details">' +
        '<div class="mposter">' + posterHTML(m, 342) +
          '<span class="mrating">' + esc(fmtRating(m.vote_average)) + "</span>" +
        "</div>" +
        '<div class="mmeta"><span class="mtitle">' + esc(m.title || "Untitled") + "</span>" +
        '<span class="msub">' + esc(cardSub(m)) + "</span></div>" +
      "</button>" +
      '<button type="button" class="mfav' + (isWatched(m.id) ? " on" : "") + '" title="Toggle watchlist" aria-label="Toggle watchlist">' + ICON_HEART + "</button>";
    el.querySelector(".mcard-link").addEventListener("click", () => openDetail(m.id));
    el.querySelector(".mfav").addEventListener("click", e => { e.stopPropagation(); toggleWatch(slim(m)); });
    hookImgs(el);
    requestAnimationFrame(() => requestAnimationFrame(() => el.classList.add("in")));  // fade-in reveal
    return el;
  }

  function cardsFrag(list) {
    const frag = document.createDocumentFragment();
    for (const m of (list || [])) if (m && m.id && (m.title || m.original_title)) frag.appendChild(makeCard(m));
    return frag;
  }

  function skeletons(n) {
    const frag = document.createDocumentFragment();
    for (let i = 0; i < n; i++) {
      const d = document.createElement("div");
      d.className = "mcard sk";
      d.innerHTML = '<div class="mposter msk"></div><div class="mmeta"><span class="msk msk-line"></span><span class="msk msk-line short"></span></div>';
      frag.appendChild(d);
    }
    return frag;
  }

  /* ============================== WATCHLIST ============================== */
  function slim(m) {
    return {
      id: m.id,
      title: m.title || m.original_title || "Untitled",
      poster_path: m.poster_path || null,
      release_date: m.release_date || "",
      vote_average: m.vote_average || 0,
      genre_ids: Array.isArray(m.genre_ids) ? m.genre_ids : null,
    };
  }

  const isWatched = id => state.watchlist.some(m => m.id === id);

  function toggleWatch(m) {
    if (isWatched(m.id)) {
      state.watchlist = state.watchlist.filter(x => x.id !== m.id);
      toast("Removed from watchlist");
    } else {
      state.watchlist = [slim(m), ...state.watchlist];
      toast("Added to watchlist");
    }
    lsSet("jm_watchlist", state.watchlist);
    syncWatchUI();
  }

  function syncWatchUI() {
    $("mWatchCount").textContent = state.watchlist.length;
    for (const el of document.querySelectorAll(".mcard[data-mid]")) {
      const b = el.querySelector(".mfav");
      if (b) b.classList.toggle("on", isWatched(+el.dataset.mid));
    }
    if (state.curDetail) syncDetailWatchBtn(state.curDetail);
    renderWatchRow();
  }

  function renderWatchRow() {
    const sec = $("mWatchSec"), row = $("mWatchRow"), empty = $("mWatchEmpty");
    if (state.watchlist.length === 0) {
      sec.hidden = !state.wlOnly;
      row.replaceChildren();
      empty.hidden = !state.wlOnly;
      if (state.wlOnly) empty.innerHTML = "Your watchlist is empty.<br>Tap the <b>heart</b> on any movie to save it here.";
      return;
    }
    sec.hidden = false;
    empty.hidden = true;
    row.replaceChildren(cardsFrag(state.watchlist));
  }

  function setWlOnly(on) {
    state.wlOnly = on;
    const btn = $("mWatchBtn");
    btn.classList.toggle("on", on);
    btn.setAttribute("aria-pressed", on ? "true" : "false");
    $("mHero").hidden = on;
    $("mSetup").hidden = true;
    for (const s of document.querySelectorAll("#mBrowse > section:not(#mWatchSec)")) s.hidden = on;
    renderWatchRow();
    if (on) {
      $("mWatchSec").hidden = false;
      $("mWatchSec").scrollIntoView({ behavior: "smooth", block: "nearest" });
    }
  }

  /* ============================== HERO ============================== */
  function heroMeta(m) {
    const parts = ["★ " + fmtRating(m.vote_average), year(m.release_date)];
    const g = genresOf(m).slice(0, 3).join(", ");
    if (g) parts.push(g);
    return parts.join("  ·  ");
  }

  function renderHero(m) {
    const el = $("mHero");
    const bd = backdropUrl(m.backdrop_path, "w1280");
    el.hidden = false;
    el.innerHTML =
      (bd ? '<img class="mhero-bg mdyn" data-fb="" src="' + esc(bd) + '" alt="">'
          : '<div class="mhero-bg mhero-bg-fb"></div>') +
      '<div class="mhero-shade"></div>' +
      '<div class="mhero-info">' +
        '<p class="mhero-kicker">Featured today</p>' +
        "<h2>" + esc(m.title || "Untitled") + "</h2>" +
        '<p class="mhero-meta">' + esc(heroMeta(m)) + "</p>" +
        '<p class="mhero-ov">' + esc(cut(m.overview, 240)) + "</p>" +
        '<div class="mhero-btns">' +
          '<button type="button" class="btn btn-primary" data-act="info">More info</button>' +
          '<button type="button" class="btn" data-act="wl">' + (isWatched(m.id) ? "✓ In watchlist" : "+ Watchlist") + "</button>" +
        "</div>" +
      "</div>";
    el.dataset.mid = m.id;
    el.dataset.raw = JSON.stringify(slim(m));
    hookImgs(el);
    el.querySelector('[data-act="info"]').addEventListener("click", () => openDetail(m.id));
    el.querySelector('[data-act="wl"]').addEventListener("click", () => toggleWatch(slim(m)));
  }

  function cut(s, n) {
    s = (s || "").trim();
    return s.length > n ? s.slice(0, n).replace(/\s+\S*$/, "") + "…" : s;
  }

  /* ============================== ROWS ============================== */
  const ROWS = {
    trending: { path: "/trending/movie/week", label: "Trending this week" },
    popular:  { path: "/movie/popular",       label: "Popular" },
    top:      { path: "/movie/top_rated",     label: "Top rated" },
    now:      { path: "/movie/now_playing",   label: "Now playing" },
    upcoming: { path: "/movie/upcoming",      label: "Upcoming" },
    recs:     { rec: true,                    label: "Recommended for you" },
  };

  function rowError(body, key, err) {
    body.replaceChildren();
    const d = document.createElement("div");
    d.className = "mrow-err";
    d.innerHTML = "<span>" + esc(err.message || "Could not load movies.") + '</span> <button type="button" class="linkbtn" data-retry="' + key + '">Retry</button>';
    d.querySelector("[data-retry]").addEventListener("click", () => loadRow(key));
    body.appendChild(d);
  }

  async function loadRow(key) {
    const body = document.querySelector('[data-mbody="' + key + '"]');
    if (!body || body.dataset.loaded === "1" || body.dataset.busy === "1") return;
    body.dataset.busy = "1";
    body.replaceChildren(skeletons(PAGE));
    try {
      let results;
      if (ROWS[key].rec) results = await loadRecommendations();
      else results = (await tmdb(ROWS[key].path)).results;
      if (!body.isConnected) return;
      if (!results || !results.length) {
        document.getElementById("mSec-" + key).hidden = true;   // nothing to show — hide the whole section
        return;
      }
      if (key === "popular" && !state.popularSeed) state.popularSeed = results[Math.min(6, results.length - 1)].id;
      body.replaceChildren(cardsFrag(results));
      body.dataset.loaded = "1";
    } catch (err) {
      if (body.isConnected) rowError(body, key, err);
      console.error("Movies row " + key + ":", err);
    } finally {
      body.dataset.busy = "";
    }
  }

  async function loadRecommendations() {
    let seedId = state.seed && state.seed.id;
    if (!seedId) {
      if (!state.popularSeed) {
        const d = await tmdb("/movie/popular");
        state.popularSeed = (d.results || []).length ? d.results[Math.min(6, d.results.length - 1)].id : null;
      }
      seedId = state.popularSeed;
    }
    if (!seedId) throw new Error("Could not find anything to recommend from.");
    const d = await tmdb("/movie/" + seedId + "/recommendations");
    return (d.results || []).filter(m => m.title).slice(0, PAGE);
  }

  /* rows load themselves as they scroll into view */
  let rowIO = null;
  function observeRows() {
    if (rowIO) return;
    rowIO = new IntersectionObserver(es => {
      for (const e of es) if (e.isIntersecting) {
        rowIO.unobserve(e.target);
        loadRow(e.target.dataset.mrow);
      }
    }, { rootMargin: "500px 0px" });
    for (const s of document.querySelectorAll("#mBrowse section[data-mrow]")) rowIO.observe(s);
  }

  /* ============================== GENRES ============================== */
  async function loadGenres() {
    try {
      const d = await tmdb("/genre/movie/list");
      for (const g of (d.genres || [])) state.genres.set(g.id, g.name);
      renderGenreChips();
    } catch (err) { console.error("Movie genres:", err); }
  }

  function renderGenreChips() {
    const wrap = $("mGenreChips");
    wrap.replaceChildren();
    for (const [id, name] of [...state.genres.entries()].sort((a, b) => a[1].localeCompare(b[1]))) {
      const b = document.createElement("button");
      b.type = "button";
      b.className = "chip" + (state.genre.id === id ? " on" : "");
      b.textContent = name;
      b.addEventListener("click", () => openGenre(id, name));
      wrap.appendChild(b);
    }
  }

  async function openGenre(id, name) {
    state.genre = { id, name, page: 1, total: 0 };
    renderGenreChips();
    $("mGenreArea").hidden = false;
    $("mGenreTitle").textContent = name + " movies";
    $("mGenreCount").textContent = "";
    $("mGenreMore").hidden = true;
    const grid = $("mGenreGrid");
    grid.replaceChildren(skeletons(PAGE));
    try {
      const d = await tmdb("/discover/movie", { with_genres: id, sort_by: "popularity.desc", page: 1, include_adult: false, "vote_count.gte": 50 });
      if (state.genre.id !== id) return;
      state.genre.total = d.total_pages || 0;
      $("mGenreCount").textContent = d.total_results ? d.total_results.toLocaleString() + (d.total_results === 1 ? " movie" : " movies") : "";
      grid.replaceChildren(cardsFrag(d.results));
      $("mGenreMore").hidden = state.genre.page >= state.genre.total;
      $("mGenreArea").scrollIntoView({ behavior: "smooth", block: "nearest" });
    } catch (err) {
      if (state.genre.id !== id) return;
      grid.replaceChildren();
      $("mGenreEmpty").hidden = false;
      $("mGenreEmpty").textContent = err.message || "Could not load this genre.";
    }
  }

  async function genreMore() {
    const g = state.genre;
    if (!g.id || g.page >= g.total) return;
    g.page++;
    $("mGenreMore").disabled = true;
    try {
      const d = await tmdb("/discover/movie", { with_genres: g.id, sort_by: "popularity.desc", page: g.page, include_adult: false, "vote_count.gte": 50 });
      if (state.genre.id !== g.id) return;
      $("mGenreGrid").appendChild(cardsFrag(d.results));
      $("mGenreMore").hidden = g.page >= g.total;
    } catch (err) {
      toast(err.message || "Could not load more movies.");
      g.page--;
    } finally {
      $("mGenreMore").disabled = false;
    }
  }

  /* ============================== SEARCH ============================== */
  let searchTimer = null;

  async function runSearch(q) {
    state.search.q = q;
    const reqId = ++state.search.reqId;
    state.search.page = 1;
    $("mSearchQ").textContent = "“" + q + "”";
    $("mSearchArea").hidden = false;
    $("mBrowse").hidden = true;
    $("mSearchEmpty").hidden = true;
    $("mSearchMore").hidden = true;
    $("mSearchCount").textContent = "";
    const grid = $("mSearchGrid");
    grid.replaceChildren(skeletons(PAGE));
    try {
      const d = await tmdb("/search/movie", { query: q, page: 1, include_adult: false });
      if (reqId !== state.search.reqId) return;    // a newer search superseded this one
      state.search.total = d.total_pages || 0;
      const n = d.results || [];
      if (!n.length) {
        grid.replaceChildren();
        const e = $("mSearchEmpty");
        e.hidden = false;
        e.innerHTML = "No movies match <b>" + esc(q) + "</b>.<br>Try a different title or check the spelling.";
        return;
      }
      $("mSearchCount").textContent = (d.total_results || n.length) + (d.total_results === 1 ? " result" : " results");
      grid.replaceChildren(cardsFrag(n));
      $("mSearchMore").hidden = state.search.page >= state.search.total;
    } catch (err) {
      if (reqId !== state.search.reqId) return;
      grid.replaceChildren();
      const e = $("mSearchEmpty");
      e.hidden = false;
      e.textContent = err.message || "Search failed.";
    }
  }

  async function searchMore() {
    const s = state.search;
    if (!s.q || s.page >= s.total) return;
    s.page++;
    $("mSearchMore").disabled = true;
    try {
      const d = await tmdb("/search/movie", { query: s.q, page: s.page, include_adult: false });
      if (s.q !== state.search.q) return;
      $("mSearchGrid").appendChild(cardsFrag(d.results));
      $("mSearchMore").hidden = s.page >= s.total;
    } catch (err) {
      toast(err.message || "Could not load more results.");
      s.page--;
    } finally {
      $("mSearchMore").disabled = false;
    }
  }

  function onSearchInput() {
    const q = $("mSearch").value.trim();
    clearTimeout(searchTimer);
    if (q.length < 2) { exitSearch(); return; }
    searchTimer = setTimeout(() => runSearch(q), 400);   // debounce
  }

  function exitSearch() {
    state.search.reqId++;      // drop any in-flight search render
    state.search.q = "";
    $("mSearchArea").hidden = true;
    $("mBrowse").hidden = false;
  }

  /* ============================== DETAILS MODAL ============================== */
  function detailSkeleton() {
    $("mMContent").innerHTML =
      '<div class="mhero-bd msk"></div>' +
      '<div class="mdetail">' +
        '<div class="mdhead"><div class="mposter mdposter msk"></div>' +
        '<div class="mdinfo"><span class="msk msk-line" style="width:70%"></span><span class="msk msk-line short"></span><span class="msk msk-line" style="width:45%"></span></div></div>' +
        '<span class="msk msk-line"></span><span class="msk msk-line"></span><span class="msk msk-line short"></span>' +
      "</div>";
  }

  function renderDetailSkeletonOpen() {
    detailSkeleton();
    $("mModal").classList.add("active");
    document.body.style.overflow = "hidden";
    $("mModalClose").focus();
  }

  function closeDetail() {
    state.curDetail = null;
    $("mModal").classList.remove("active");
    const f = $("mMTrailerFrame");
    if (f) f.removeAttribute("src");       // stop trailer audio
    const w = $("mMTrailer");
    if (w) w.hidden = true;
    document.body.style.overflow = "";
  }

  function syncDetailWatchBtn(d) {
    const b = $("mMDetailWatch");
    if (!b || !state.curDetail || state.curDetail.id !== d.id) return;
    const on = isWatched(d.id);
    b.textContent = on ? "✓ In watchlist" : "+ Watchlist";
    b.setAttribute("aria-pressed", on ? "true" : "false");
  }

  function trailerOf(d) {
    const vids = (d.videos && d.videos.results || []).filter(v => v.site === "YouTube" && v.key);
    const score = v => (v.type === "Trailer" ? 4 : v.type === "Teaser" ? 3 : v.type === "Clip" ? 2 : 1) + (v.official ? 1 : 0);
    vids.sort((a, b) => score(b) - score(a));
    return vids[0] || null;
  }

  function renderDetail(d) {
    state.curDetail = d;
    const bd = backdropUrl(d.backdrop_path, "w1280") || posterUrl(d.poster_path, "w780");
    const trailer = trailerOf(d);
    const cast = ((d.credits && d.credits.cast) || []).slice(0, 12);
    const companies = (d.production_companies || []).map(c => c.name).slice(0, 6);

    const metaParts = [
      d.release_date ? fmtDate(d.release_date) : "",
      fmtRuntime(d.runtime),
      "★ " + fmtRating(d.vote_average) + " / 10",
      d.status && d.status !== "Released" ? d.status : "",
    ].filter(Boolean);

    $("mMContent").innerHTML =
      '<div class="mhero-bd">' +
        (bd ? '<img class="mdyn" data-fb="" src="' + esc(bd) + '" alt="">'
            : '<div class="mfb"><span>' + esc(String(d.title || "?").charAt(0)) + "</span></div>") +
        '<div class="mhero-shade"></div>' +
      "</div>" +
      '<div class="mdetail">' +
        '<div class="mdhead">' +
          '<div class="mposter mdposter">' + posterHTML(d, 500) + "</div>" +
          '<div class="mdinfo">' +
            "<h2>" + esc(d.title || "Untitled") + "</h2>" +
            (d.tagline ? '<p class="mtag">' + esc(d.tagline) + "</p>" : "") +
            '<p class="mmeta-line">' + esc(metaParts.join("  ·  ")) + "</p>" +
            '<div class="chips mchips-sm">' +
              (genresOf(d).map(g => '<span class="chip static">' + esc(g) + "</span>").join("") || "") +
            "</div>" +
          "</div>" +
        "</div>" +
        '<div class="mdetail-actions">' +
          '<button type="button" class="btn btn-primary" id="mMDetailWatch" aria-pressed="' + (isWatched(d.id) ? "true" : "false") + '">' + (isWatched(d.id) ? "✓ In watchlist" : "+ Watchlist") + "</button>" +
          (trailer ? '<button type="button" class="btn" id="mMDetailTrailerBtn"><svg class="ico fill" aria-hidden="true"><use href="#i-play"/></svg> Trailer</button>' : "") +
          (d.homepage ? '<a class="btn" href="' + esc(d.homepage) + '" target="_blank" rel="noopener">Official site</a>' : "") +
        "</div>" +
        (trailer ? '<div class="mtrailer" id="mMTrailer" hidden><iframe id="mMTrailerFrame" title="Trailer" allow="autoplay; encrypted-media; fullscreen" allowfullscreen referrerpolicy="strict-origin-when-cross-origin"></iframe></div>' : "") +
        (d.overview ? '<p class="mov">' + esc(d.overview) + "</p>" : '<p class="mov dim">No synopsis available for this movie yet.</p>') +
        (cast.length ? "<h3>Cast</h3>" +
          '<div class="mcast">' + cast.map(c => {
            const img = c.profile_path
              ? '<img class="mdyn" loading="lazy" decoding="async" data-fb="' + esc(String(c.name || "?").charAt(0).toUpperCase()) + '" src="' + esc(posterUrl(c.profile_path, 185)) + '" alt="">'
              : '<div class="mfb"><span>' + esc(String(c.name || "?").charAt(0).toUpperCase()) + "</span></div>";
            return '<button type="button" class="mcastcard"><span class="mcastimg">' + img + "</span>" +
              '<span class="mcastname">' + esc(c.name) + "</span>" +
              '<span class="mcastchar">' + esc(c.character || "") + "</span></button>";
          }).join("") + "</div>"
        : "") +
        (companies.length ? "<h3>Production</h3><p class='mcomp'>" + esc(companies.join(" · ")) + "</p>" : "") +
        '<p class="msrc">Movie data from <a href="https://www.themoviedb.org/movie/' + d.id + '" target="_blank" rel="noopener">TMDB</a>.</p>' +
      "</div>";

    hookImgs($("mMContent"));

    $("mMDetailWatch").addEventListener("click", () => toggleWatch(slim(d)));
    if (trailer) $("mMDetailTrailerBtn").addEventListener("click", () => {
      const w = $("mMTrailer"), f = $("mMTrailerFrame");
      if (w.hidden) {
        w.hidden = false;
        f.src = "https://www.youtube.com/embed/" + encodeURIComponent(trailer.key) + "?autoplay=1&rel=0";
        w.scrollIntoView({ behavior: "smooth", block: "center" });
      } else {
        w.hidden = true;
        f.removeAttribute("src");
      }
    });
  }

  function renderDetailError(err) {
    $("mMContent").innerHTML =
      '<div class="mdetail" style="padding-top:40px;text-align:center">' +
        '<div class="pt-ico">!</div>' +
        '<h2 style="margin-top:14px">Could not load this movie</h2>' +
        "<p>" + esc(err.message || "Something went wrong.") + "</p>" +
        '<div class="ptbtns"><button type="button" class="btn btn-primary" id="mMDetailRetry">Retry</button></div>' +
      "</div>";
    const r = $("mMDetailRetry");
    if (r && state.curDetailId) r.addEventListener("click", () => openDetail(state.curDetailId));
  }

  async function openDetail(id) {
    state.curDetailId = id;
    renderDetailSkeletonOpen();
    try {
      const d = await tmdb("/movie/" + id, { append_to_response: "credits,videos" }, DETAIL_TTL);
      if (state.curDetailId !== id) return;
      state.seed = { id: d.id, title: d.title || d.original_title };
      lsSet("jm_seed", state.seed);
      renderDetail(d);
    } catch (err) {
      if (state.curDetailId !== id) return;
      console.error("Movie detail:", err);
      renderDetailError(err);
    }
  }

  /* ============================== SETUP / ERROR PANELS ============================== */
  function showSetup() {
    $("mSetup").hidden = false;
    $("mHero").hidden = true;
    $("mToolbar").hidden = true;
    $("mBrowse").hidden = true;
  }

  function showFatal(err) {
    $("mHero").hidden = true;
    const el = $("mFatal");
    el.hidden = false;
    el.innerHTML = '<div class="pt-ico">!</div><h2>Movies could not be loaded</h2><p>' + esc(err.message || "TMDB is unreachable right now.") + "</p>" +
      '<div class="ptbtns"><button type="button" class="btn btn-primary" id="mFatalRetry">Retry</button></div>';
    $("mFatalRetry").addEventListener("click", () => { el.hidden = true; buildOnce(); });
  }

  /* ============================== INIT ============================== */
  function buildOnce() {
    observeRows();
    loadGenres();

    tmdb("/trending/movie/week").then(d => {
      const list = (d.results || []).filter(m => m.title);
      const m = list.find(x => x.backdrop_path && x.overview) || list[0];
      if (m) {
        renderHero(m);
        if (!state.popularSeed) state.popularSeed = m.id;
      }
    }).catch(err => { console.error("Movies hero:", err); showFatal(err); });
  }

  function show() {
    if (!state.init) {
      state.init = true;
      if (!keyOk()) { showSetup(); return; }
      buildOnce();
    }
    if (state.wlOnly) renderWatchRow();
    syncWatchUI();
  }

  /* ============================== WIRING ============================== */
  $("mSearch").addEventListener("input", onSearchInput);
  $("mSearch").addEventListener("keydown", e => { if (e.key === "Escape") { $("mSearch").value = ""; exitSearch(); } });
  $("mSearchMore").addEventListener("click", searchMore);
  $("mGenreMore").addEventListener("click", genreMore);
  $("mWatchBtn").addEventListener("click", () => setWlOnly(!state.wlOnly));
  $("mModalClose").addEventListener("click", closeDetail);
  $("mModalBack").addEventListener("click", closeDetail);
  $("mWatchClear").addEventListener("click", () => {
    if (state.watchlist.length === 0) { toast("Watchlist is already empty"); return; }
    if (!confirm("Remove all movies from your watchlist?")) return;
    state.watchlist = [];
    lsSet("jm_watchlist", state.watchlist);
    syncWatchUI();
    toast("Watchlist cleared");
  });

  /* Escape closes the details modal (capture phase, before the app's other handlers) */
  document.addEventListener("keydown", e => {
    if (!$("mModal").classList.contains("active")) return;
    if ($("settingsModal") && $("settingsModal").classList.contains("active")) return;
    if (e.key === "Escape") { e.stopPropagation(); closeDetail(); }
  }, true);

  return { show, openDetail };
})();

/* if the page was opened directly on #movies, route() already ran before this
   file loaded — kick the view off once window.Movies is in place */
if (document.body.dataset.view === "movies") setTimeout(() => window.Movies.show(), 0);
