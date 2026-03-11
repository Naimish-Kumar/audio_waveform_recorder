import { useState, useEffect, useRef, useCallback } from "react";

// ── Synthetic waveform generator ─────────────────────────────────────────────
function generateWaveform(seed = 42, length = 200) {
  const samples = [];
  let phase = seed;
  for (let i = 0; i < length; i++) {
    phase += 0.13 + Math.sin(i * 0.04) * 0.06;
    const v = Math.abs(
      Math.sin(phase) * 0.6 +
      Math.sin(phase * 2.3) * 0.25 +
      Math.sin(phase * 0.7) * 0.15
    );
    samples.push(Math.min(1, v * 1.3));
  }
  return samples;
}

const WAVEFORM = generateWaveform(7, 220);

// ── Colour palettes ───────────────────────────────────────────────────────────
const PALETTES = {
  "Crimson Pulse":   { rec: "#E53935", played: "#FF7043", idle: "#37474F", bg: "#1A0A0A" },
  "Ocean Glow":      { rec: "#00BCD4", played: "#1E88E5", idle: "#37474F", bg: "#050E1A" },
  "Neon Lime":       { rec: "#C6FF00", played: "#76FF03", idle: "#33691E", bg: "#0A1A00" },
  "Purple Haze":     { rec: "#E040FB", played: "#7C4DFF", idle: "#4A148C", bg: "#0D001A" },
  "Solar Flare":     { rec: "#FF6F00", played: "#FFD600", idle: "#4E342E", bg: "#1A0800" },
  "Arctic":          { rec: "#80DEEA", played: "#B2EBF2", idle: "#546E7A", bg: "#07101A" },
};

const STYLES = [
  { id: "bars",      label: "Bars",      icon: "▊", desc: "WhatsApp / Telegram style" },
  { id: "mirror",    label: "Mirror",    icon: "⬦", desc: "Spotify symmetrical style" },
  { id: "line",      label: "Line",      icon: "〜", desc: "SoundCloud filled shape" },
  { id: "equalizer", label: "Equalizer", icon: "⬆", desc: "DJ / EQ bottom-anchored" },
  { id: "radial",    label: "Radial",    icon: "◎", desc: "Vinyl / radar circular" },
  { id: "wave",      label: "Wave",      icon: "≋", desc: "Apple Music layered bezier" },
  { id: "dots",      label: "Dots",      icon: "⠿", desc: "Retro LED dot matrix" },
  { id: "neon",      label: "Neon",      icon: "✦", desc: "Cyberpunk bloom glow" },
  { id: "stacked",   label: "Stacked",   icon: "◈", desc: "Holographic layered waves" },
  { id: "pixel",     label: "Pixel",     icon: "▦", desc: "Retro game pixel grid" },
];

// ── Canvas drawing engine ─────────────────────────────────────────────────────
function drawWaveform(ctx, w, h, samples, style, opts) {
  const {
    rec, played, idle, bg,
    barW = 3, barGap = 2, progress = 0.45,
    isRecording = false, glowRadius = 8,
    useGradient = false, dotRows = 8, pixelRows = 10,
    waveLayerCount = 3, mirrorOpacity = 0.45,
    showPeak = true, radialInner = 0.28, showPlayhead = true,
  } = opts;

  ctx.clearRect(0, 0, w, h);

  const stride = barW + barGap;
  const maxBars = Math.floor(w / stride);
  const resample = (n) => {
    if (samples.length <= n) return [...samples, ...Array(n - samples.length).fill(0)];
    const out = [];
    const step = samples.length / n;
    for (let i = 0; i < n; i++) {
      const s = Math.floor(i * step), e = Math.min(Math.ceil((i+1)*step), samples.length);
      out.push(samples.slice(s, e).reduce((a, b) => a + b, 0) / (e - s));
    }
    return out;
  };

  const barColor = (idx, total) => {
    if (isRecording) return rec;
    return idx / total <= progress ? played : idle;
  };

  const gradFill = (x, y, bw, bh, colors) => {
    const g = ctx.createLinearGradient(x, y, x, y + bh);
    g.addColorStop(0, colors[0]);
    g.addColorStop(1, colors[1] || colors[0]);
    return g;
  };

  const drawPlayhead = (px) => {
    if (!showPlayhead || progress <= 0) return;
    ctx.save();
    ctx.strokeStyle = played;
    ctx.lineWidth = 2;
    ctx.globalAlpha = 0.9;
    ctx.beginPath(); ctx.moveTo(px, 0); ctx.lineTo(px, h); ctx.stroke();
    ctx.fillStyle = played;
    ctx.beginPath(); ctx.moveTo(px-5,0); ctx.lineTo(px+5,0); ctx.lineTo(px,9); ctx.fill();
    ctx.restore();
  };

  // ── BARS ────────────────────────────────────────────────────────────────
  if (style === "bars") {
    const s = resample(maxBars);
    const cy = h / 2, minH = h * 0.05;
    s.forEach((amp, i) => {
      const bh = Math.max(minH, amp * h);
      const x = i * stride;
      ctx.fillStyle = useGradient
        ? gradFill(x, cy - bh/2, barW, bh, i/maxBars <= progress ? [rec,"#FF7043"] : [idle,"#546E7A"])
        : barColor(i, maxBars);
      ctx.beginPath();
      ctx.roundRect(x, cy - bh/2, barW, bh, 2);
      ctx.fill();
    });
    drawPlayhead(progress * w);
  }

  // ── MIRROR ──────────────────────────────────────────────────────────────
  else if (style === "mirror") {
    const s = resample(maxBars);
    const halfH = h / 2, minH = halfH * 0.05;
    s.forEach((amp, i) => {
      const bh = Math.max(minH, amp * halfH * 0.95);
      const cx = i * stride + barW / 2;
      const c = barColor(i, maxBars);
      ctx.fillStyle = c;
      ctx.beginPath(); ctx.roundRect(cx - barW/2, halfH - bh, barW, bh, 2); ctx.fill();
      ctx.fillStyle = hexToRgba(c, mirrorOpacity);
      ctx.beginPath(); ctx.roundRect(cx - barW/2, halfH, barW, bh, 2); ctx.fill();
    });
    drawPlayhead(progress * w);
  }

  // ── LINE ────────────────────────────────────────────────────────────────
  else if (style === "line") {
    const sCount = Math.floor(w);
    const s = resample(sCount);
    const cy = h / 2;
    const path = new Path2D();
    s.forEach((amp, i) => {
      const x = (i / sCount) * w, hh = amp * cy * 0.9;
      i === 0 ? path.moveTo(x, cy - hh) : path.lineTo(x, cy - hh);
    });
    for (let i = sCount - 1; i >= 0; i--) {
      path.lineTo((i / sCount) * w, cy + s[i] * cy * 0.9);
    }
    path.closePath();

    ctx.save();
    ctx.clip(new Path2D(`M0,0 H${progress*w} V${h} H0 Z`));
    ctx.fillStyle = useGradient ? gradFill(0,0,w,h,[rec+"CC","#FF7043"+"88"]) : hexToRgba(played, 0.75);
    ctx.fill(path);
    ctx.restore();
    ctx.save();
    ctx.clip(new Path2D(`M${progress*w},0 H${w} V${h} H${progress*w} Z`));
    ctx.fillStyle = hexToRgba(idle, 0.4);
    ctx.fill(path);
    ctx.restore();

    ctx.strokeStyle = isRecording ? rec : idle;
    ctx.lineWidth = 1.5; ctx.stroke(path);
    drawPlayhead(progress * w);
  }

  // ── EQUALIZER ───────────────────────────────────────────────────────────
  else if (style === "equalizer") {
    const s = resample(maxBars);
    const minH = h * 0.04;
    if (!opts._peaks) opts._peaks = new Array(maxBars).fill(0);
    s.forEach((amp, i) => {
      const bh = Math.max(minH, amp * h * 0.92);
      const x = i * stride;
      if (amp > opts._peaks[i]) opts._peaks[i] = amp;
      else opts._peaks[i] *= 0.93;

      if (useGradient) {
        const g = ctx.createLinearGradient(0, h, 0, 0);
        g.addColorStop(0, "#43A047"); g.addColorStop(0.6, "#FDD835"); g.addColorStop(1, "#E53935");
        ctx.fillStyle = g;
      } else {
        ctx.fillStyle = barColor(i, maxBars);
      }
      ctx.beginPath(); ctx.roundRect(x, h - bh, barW, bh, 2); ctx.fill();

      if (showPeak && opts._peaks[i] > 0.03) {
        const peakH = Math.max(minH, opts._peaks[i] * h * 0.92);
        ctx.fillStyle = "rgba(255,255,255,0.9)";
        ctx.fillRect(x, h - peakH - 3, barW, 2.5);
      }
    });
    drawPlayhead(progress * w);
  }

  // ── RADIAL ──────────────────────────────────────────────────────────────
  else if (style === "radial") {
    const maxBarsR = 120;
    const s = resample(maxBarsR);
    const cx = w/2, cy = h/2;
    const maxR = Math.min(w, h) / 2 - 4;
    const innerR = maxR * radialInner;
    const angleStep = (2 * Math.PI) / maxBarsR;

    s.forEach((amp, i) => {
      const barLen = Math.max(2, amp * (maxR - innerR));
      const angle = i * angleStep - Math.PI / 2;
      const sx = cx + innerR * Math.cos(angle), sy = cy + innerR * Math.sin(angle);
      const ex = cx + (innerR + barLen) * Math.cos(angle), ey = cy + (innerR + barLen) * Math.sin(angle);

      const frac = i / maxBarsR;
      let c = frac <= progress ? played : idle;
      if (isRecording) c = rec;

      if (glowRadius > 0 && amp > 0.1) {
        ctx.save();
        ctx.shadowColor = c; ctx.shadowBlur = glowRadius * amp * 2;
        ctx.strokeStyle = c; ctx.lineWidth = barW; ctx.lineCap = "round";
        ctx.beginPath(); ctx.moveTo(sx, sy); ctx.lineTo(ex, ey); ctx.stroke();
        ctx.restore();
      }
      ctx.strokeStyle = c; ctx.lineWidth = barW; ctx.lineCap = "round";
      ctx.beginPath(); ctx.moveTo(sx, sy); ctx.lineTo(ex, ey); ctx.stroke();
    });

    // Inner ring
    ctx.beginPath(); ctx.arc(cx, cy, innerR - 2, 0, Math.PI*2);
    ctx.strokeStyle = hexToRgba(isRecording ? rec : played, 0.5);
    ctx.lineWidth = 1.5; ctx.stroke();
    ctx.fillStyle = hexToRgba(bg, 0.6); ctx.fill();
  }

  // ── WAVE ────────────────────────────────────────────────────────────────
  else if (style === "wave") {
    const count = Math.floor(w / 2);
    const s = resample(count);
    const cy = h / 2;
    const baseColor = isRecording ? rec : played;
    const layers = waveLayerCount;

    for (let layer = layers - 1; layer >= 0; layer--) {
      const t = layer / Math.max(layers - 1, 1);
      const yOff = (layer - layers / 2) * 0.07 * h;
      const opacity = 0.2 + (1 - t) * 0.6;
      const scale = 0.55 + t * 0.45;

      const path = new Path2D();
      for (let i = 0; i < count; i++) {
        const x = (i / count) * w, hh = s[i] * cy * 0.88 * scale;
        i === 0 ? path.moveTo(x, cy - hh + yOff) : path.quadraticBezierTo
          ? path.moveTo(x, cy - hh + yOff) // fallback
          : path.lineTo(x, cy - hh + yOff);
        if (i > 0) {
          const px = ((i-1)/count)*w, ph = s[i-1]*cy*0.88*scale;
          // simple lineTo for compatibility
          path.lineTo(x, cy - hh + yOff);
        }
      }
      for (let i = count - 1; i >= 0; i--) {
        path.lineTo((i/count)*w, cy + s[i]*cy*0.88*scale + yOff);
      }
      path.closePath();

      if (useGradient) {
        const g = ctx.createLinearGradient(0, 0, 0, h);
        g.addColorStop(0, hexToRgba(rec, opacity));
        g.addColorStop(1, hexToRgba(played, opacity * 0.3));
        ctx.fillStyle = g;
      } else {
        ctx.fillStyle = hexToRgba(baseColor, opacity * (layer === 0 ? 1 : 0.55));
      }
      ctx.fill(path);
      if (layer === 0) {
        ctx.strokeStyle = hexToRgba(baseColor, 0.9);
        ctx.lineWidth = 1.5; ctx.stroke(path);
      }
    }
    drawPlayhead(progress * w);
  }

  // ── DOTS ────────────────────────────────────────────────────────────────
  else if (style === "dots") {
    const s = resample(maxBars);
    const rows = dotRows;
    const cellH = h / rows;
    const r = Math.min(barW, cellH) * 0.42;

    s.forEach((amp, col) => {
      const litRows = Math.max(1, Math.round(amp * rows));
      const cx2 = col * stride + barW / 2;
      const frac = col / maxBars;
      for (let row = 0; row < rows; row++) {
        const cy2 = h - (row + 0.5) * cellH;
        const isLit = row < litRows;
        const rowFrac = row / rows;
        let c;
        if (!isLit) c = hexToRgba(idle, 0.18);
        else if (isRecording) {
          c = useGradient ? lerpColor(rec, "#FF7043", rowFrac) : rec;
        } else if (frac <= progress) {
          c = useGradient ? lerpColor(played, "#B2EBF2", rowFrac) : played;
        } else {
          c = hexToRgba(idle, 0.5);
        }
        ctx.fillStyle = c;
        ctx.beginPath(); ctx.arc(cx2, cy2, r, 0, Math.PI*2); ctx.fill();
      }
    });
  }

  // ── NEON ────────────────────────────────────────────────────────────────
  else if (style === "neon") {
    const s = resample(maxBars);
    const cy = h / 2, minH = h * 0.04;
    s.forEach((amp, i) => {
      const bh = Math.max(minH, amp * h);
      const x = i * stride;
      const c = barColor(i, maxBars);

      // Glow layers
      for (let g = 3; g >= 0; g--) {
        ctx.save();
        ctx.shadowColor = c;
        ctx.shadowBlur = glowRadius * (g + 1) * amp;
        ctx.fillStyle = hexToRgba(c, 0.06 + 0.05 * (1 - g / 3));
        ctx.beginPath(); ctx.roundRect(x, cy - bh/2, barW, bh, 2); ctx.fill();
        ctx.restore();
      }
      // Core bar
      ctx.fillStyle = c;
      ctx.beginPath(); ctx.roundRect(x, cy - bh/2, barW, bh, 2); ctx.fill();
      // Bright centre
      if (amp > 0.05) {
        ctx.fillStyle = `rgba(255,255,255,${0.5 * amp})`;
        ctx.beginPath(); ctx.roundRect(x + barW*0.33, cy - bh*0.42, barW*0.34, bh*0.84, 1); ctx.fill();
      }
    });
    drawPlayhead(progress * w);
  }

  // ── STACKED ─────────────────────────────────────────────────────────────
  else if (style === "stacked") {
    const count = Math.floor(w / 2);
    const s = resample(count);
    const cy = h / 2;
    const layers = waveLayerCount;
    const baseColor = isRecording ? rec : played;

    for (let layer = layers - 1; layer >= 0; layer--) {
      const t = layer / Math.max(layers - 1, 1);
      const yShift = (layer - layers / 2) * 0.09 * h;
      const opacity = 0.1 + (1 - t) * 0.55;
      const scale = 0.5 + t * 0.5;
      const hue = layer * 18;

      const path = new Path2D();
      for (let i = 0; i < count; i++) {
        const x = (i / count) * w, hh = s[i] * cy * 0.85 * scale;
        i === 0 ? path.moveTo(x, cy - hh + yShift) : path.lineTo(x, cy - hh + yShift);
      }
      for (let i = count - 1; i >= 0; i--) {
        path.lineTo((i / count) * w, cy + s[i] * cy * 0.85 * scale + yShift);
      }
      path.closePath();

      ctx.fillStyle = useGradient
        ? hexToRgba(shiftHue(baseColor, hue), opacity)
        : hexToRgba(shiftHue(baseColor, hue), opacity);
      ctx.fill(path);
      ctx.strokeStyle = hexToRgba(shiftHue(baseColor, hue), opacity * 1.4);
      ctx.lineWidth = 0.8; ctx.stroke(path);
    }
    drawPlayhead(progress * w);
  }

  // ── PIXEL ────────────────────────────────────────────────────────────────
  else if (style === "pixel") {
    const s = resample(maxBars);
    const rows = pixelRows;
    const gap = 1.5;
    const cellH = (h - gap * (rows + 1)) / rows;

    s.forEach((amp, col) => {
      const litRows = Math.max(1, Math.round(amp * rows));
      const cx2 = col * stride;
      const frac = col / maxBars;
      for (let row = 0; row < rows; row++) {
        const cy2 = h - gap - (row + 1) * (cellH + gap);
        const isLit = row < litRows;
        const rowFrac = row / rows;
        let c;
        if (!isLit) c = hexToRgba(idle, 0.1);
        else if (isRecording) c = lerpColor("#43A047", rowFrac > 0.65 ? "#E53935" : "#FDD835", rowFrac);
        else if (frac <= progress) c = useGradient ? lerpColor(played, rec, rowFrac) : played;
        else c = hexToRgba(idle, 0.45);

        ctx.fillStyle = c;
        ctx.fillRect(cx2, cy2, barW, cellH);
        if (isLit) {
          ctx.fillStyle = "rgba(255,255,255,0.3)";
          ctx.fillRect(cx2 + 0.5, cy2 + 0.5, barW * 0.4, 1.5);
        }
      }
    });
  }
}

// ── Color helpers ────────────────────────────────────────────────────────────
function hexToRgba(hex, a = 1) {
  const r = parseInt(hex.slice(1, 3), 16);
  const g = parseInt(hex.slice(3, 5), 16);
  const b = parseInt(hex.slice(5, 7), 16);
  return `rgba(${r},${g},${b},${a})`;
}
function lerpColor(a, b, t) {
  const ar = parseInt(a.slice(1,3),16), ag = parseInt(a.slice(3,5),16), ab = parseInt(a.slice(5,7),16);
  const br = parseInt(b.slice(1,3),16), bg = parseInt(b.slice(3,5),16), bb = parseInt(b.slice(5,7),16);
  const r = Math.round(ar + (br-ar)*t), g = Math.round(ag + (bg-ag)*t), bl = Math.round(ab + (bb-ab)*t);
  return `#${r.toString(16).padStart(2,'0')}${g.toString(16).padStart(2,'0')}${bl.toString(16).padStart(2,'0')}`;
}
function shiftHue(hex, deg) {
  const r = parseInt(hex.slice(1,3),16)/255, g = parseInt(hex.slice(3,5),16)/255, b = parseInt(hex.slice(5,7),16)/255;
  const max = Math.max(r,g,b), min = Math.min(r,g,b), d = max - min;
  let h = 0, s = max === 0 ? 0 : d / max, v = max;
  if (d > 0) { if (max===r) h=(g-b)/d%6; else if(max===g) h=(b-r)/d+2; else h=(r-g)/d+4; h*=60; if(h<0) h+=360; }
  h = (h + deg) % 360; if (h < 0) h += 360;
  const c = v * s, x2 = c * (1 - Math.abs((h/60)%2-1)), m = v - c;
  let r2,g2,b2;
  if(h<60){r2=c;g2=x2;b2=0}else if(h<120){r2=x2;g2=c;b2=0}else if(h<180){r2=0;g2=c;b2=x2}
  else if(h<240){r2=0;g2=x2;b2=c}else if(h<300){r2=x2;g2=0;b2=c}else{r2=c;g2=0;b2=x2}
  const tr=Math.round((r2+m)*255),tg=Math.round((g2+m)*255),tb=Math.round((b2+m)*255);
  return `#${tr.toString(16).padStart(2,'0')}${tg.toString(16).padStart(2,'0')}${tb.toString(16).padStart(2,'0')}`;
}

// ── WaveformCanvas component ──────────────────────────────────────────────────
function WaveformCanvas({ style, opts, width = 600, height = 100 }) {
  const canvasRef = useRef(null);
  const peaksRef = useRef([]);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    const dpr = window.devicePixelRatio || 1;
    canvas.width = width * dpr;
    canvas.height = height * dpr;
    canvas.style.width = width + "px";
    canvas.style.height = height + "px";
    ctx.scale(dpr, dpr);

    const drawOpts = { ...opts, _peaks: peaksRef.current };
    drawWaveform(ctx, width, height, WAVEFORM, style, drawOpts);
  }, [style, opts, width, height]);

  return (
    <canvas
      ref={canvasRef}
      style={{ display: "block", borderRadius: 8 }}
    />
  );
}

// ── Slider control ────────────────────────────────────────────────────────────
function Slider({ label, value, min, max, step = 0.01, onChange, unit = "" }) {
  return (
    <div style={{ marginBottom: 10 }}>
      <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 4 }}>
        <span style={{ fontSize: 11, color: "#90A4AE", letterSpacing: "0.5px" }}>{label}</span>
        <span style={{ fontSize: 11, color: "#CFD8DC", fontVariantNumeric: "tabular-nums" }}>
          {typeof value === "number" ? value.toFixed(step < 0.1 ? 2 : 0) : value}{unit}
        </span>
      </div>
      <input
        type="range" min={min} max={max} step={step} value={value}
        onChange={e => onChange(parseFloat(e.target.value))}
        style={{ width: "100%", accentColor: "#1E88E5", cursor: "pointer" }}
      />
    </div>
  );
}

function Toggle({ label, value, onChange }) {
  return (
    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 8 }}>
      <span style={{ fontSize: 11, color: "#90A4AE" }}>{label}</span>
      <button
        onClick={() => onChange(!value)}
        style={{
          width: 38, height: 20, borderRadius: 10, border: "none", cursor: "pointer",
          background: value ? "#1E88E5" : "#37474F", transition: "background 0.2s", position: "relative",
        }}
      >
        <div style={{
          position: "absolute", top: 2, left: value ? 18 : 2,
          width: 16, height: 16, borderRadius: "50%", background: "#fff", transition: "left 0.2s"
        }} />
      </button>
    </div>
  );
}

// ── Main App ──────────────────────────────────────────────────────────────────
export default function App() {
  const [activeStyle, setActiveStyle] = useState("bars");
  const [palette, setPalette]         = useState("Crimson Pulse");
  const [progress, setProgress]       = useState(0.42);
  const [barW, setBarW]               = useState(3);
  const [barGap, setBarGap]           = useState(2);
  const [glowRadius, setGlowRadius]   = useState(8);
  const [dotRows, setDotRows]         = useState(8);
  const [pixelRows, setPixelRows]     = useState(10);
  const [waveLayerCount, setWaveLayerCount] = useState(3);
  const [mirrorOpacity, setMirrorOpacity]   = useState(0.45);
  const [radialInner, setRadialInner]       = useState(0.28);
  const [useGradient, setUseGradient]       = useState(false);
  const [showPeak, setShowPeak]             = useState(true);
  const [showPlayhead, setShowPlayhead]     = useState(true);
  const [isRecording, setIsRecording]       = useState(false);
  const [animFrame, setAnimFrame]           = useState(0);

  // Live recording animation
  useEffect(() => {
    if (!isRecording) return;
    const id = setInterval(() => setAnimFrame(f => f + 1), 80);
    return () => clearInterval(id);
  }, [isRecording]);

  const pal = PALETTES[palette];
  const opts = {
    ...pal,
    barW, barGap, progress,
    glowRadius, dotRows, pixelRows, waveLayerCount,
    mirrorOpacity, radialInner, useGradient, showPeak, showPlayhead,
    isRecording,
    _animFrame: animFrame, // force repaint
  };

  // Which controls to show per style
  const showBar  = ["bars","mirror","equalizer","neon","dots","pixel"].includes(activeStyle);
  const showGlow = ["neon","radial"].includes(activeStyle);
  const showDots = activeStyle === "dots";
  const showPix  = activeStyle === "pixel";
  const showWave = ["wave","stacked","line"].includes(activeStyle);
  const showMirror = activeStyle === "mirror";
  const showPeakCtl = activeStyle === "equalizer";
  const showRadial = activeStyle === "radial";

  return (
    <div style={{
      background: "#080E14",
      minHeight: "100vh",
      fontFamily: "'DM Mono', 'Fira Code', monospace",
      color: "#CFD8DC",
      display: "flex",
      flexDirection: "column",
    }}>
      {/* Header */}
      <div style={{
        borderBottom: "1px solid #1A2530",
        padding: "18px 28px 14px",
        display: "flex",
        alignItems: "baseline",
        gap: 16,
      }}>
        <span style={{ fontSize: 13, color: "#1E88E5", letterSpacing: "2px", fontWeight: 700 }}>
          WAVEFORM
        </span>
        <span style={{ fontSize: 11, color: "#37474F", letterSpacing: "1px" }}>
          STYLE PLAYGROUND — 10 MODES
        </span>
      </div>

      <div style={{ display: "flex", flex: 1 }}>

        {/* Left — style picker */}
        <div style={{
          width: 160,
          borderRight: "1px solid #1A2530",
          padding: "16px 0",
          flexShrink: 0,
        }}>
          {STYLES.map(s => (
            <button
              key={s.id}
              onClick={() => setActiveStyle(s.id)}
              style={{
                display: "flex",
                alignItems: "center",
                gap: 10,
                width: "100%",
                padding: "9px 16px",
                background: activeStyle === s.id ? "#0D1E2E" : "none",
                border: "none",
                borderLeft: `3px solid ${activeStyle === s.id ? "#1E88E5" : "transparent"}`,
                color: activeStyle === s.id ? "#E3F2FD" : "#546E7A",
                cursor: "pointer",
                textAlign: "left",
                transition: "all 0.15s",
                fontSize: 12,
              }}
            >
              <span style={{ fontSize: 14, width: 18 }}>{s.icon}</span>
              <span style={{ letterSpacing: "0.3px" }}>{s.label}</span>
            </button>
          ))}
        </div>

        {/* Centre — canvas preview */}
        <div style={{ flex: 1, padding: "28px 32px", display: "flex", flexDirection: "column", gap: 24 }}>

          {/* Style info */}
          <div>
            <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 6 }}>
              <span style={{ fontSize: 22 }}>{STYLES.find(s=>s.id===activeStyle)?.icon}</span>
              <span style={{ fontSize: 16, color: "#E3F2FD", letterSpacing: "0.5px" }}>
                {STYLES.find(s=>s.id===activeStyle)?.label}
              </span>
              <span style={{ fontSize: 11, color: "#37474F", marginLeft: 4 }}>
                {STYLES.find(s=>s.id===activeStyle)?.desc}
              </span>
            </div>
          </div>

          {/* Main canvas */}
          <div style={{
            background: pal.bg,
            borderRadius: 14,
            padding: "20px 20px",
            border: `1px solid ${hexToRgba(pal.played, 0.2)}`,
            boxShadow: `0 0 40px ${hexToRgba(pal.rec, 0.08)}`,
          }}>
            <WaveformCanvas style={activeStyle} opts={opts} width={580} height={120} />
          </div>

          {/* Palette row */}
          <div>
            <div style={{ fontSize: 10, color: "#37474F", letterSpacing: "1.5px", marginBottom: 10 }}>
              COLOUR PALETTE
            </div>
            <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
              {Object.entries(PALETTES).map(([name, p]) => (
                <button
                  key={name}
                  onClick={() => setPalette(name)}
                  style={{
                    padding: "6px 12px",
                    borderRadius: 6,
                    border: `1.5px solid ${palette === name ? p.played : "transparent"}`,
                    background: palette === name ? hexToRgba(p.played, 0.15) : "#0D1A24",
                    cursor: "pointer",
                    display: "flex",
                    alignItems: "center",
                    gap: 7,
                    fontSize: 11,
                    color: palette === name ? "#E3F2FD" : "#546E7A",
                    transition: "all 0.15s",
                  }}
                >
                  <span style={{
                    width: 8, height: 8, borderRadius: "50%",
                    background: `linear-gradient(135deg, ${p.rec}, ${p.played})`,
                    flexShrink: 0,
                  }} />
                  {name}
                </button>
              ))}
            </div>
          </div>

          {/* Playback scrub */}
          <div style={{
            background: "#0A1620",
            borderRadius: 10,
            padding: "14px 18px",
            border: "1px solid #1A2530",
          }}>
            <div style={{ fontSize: 10, color: "#37474F", letterSpacing: "1.5px", marginBottom: 10 }}>
              PLAYBACK POSITION
            </div>
            <Slider label="Progress" value={progress} min={0} max={1} step={0.01}
              onChange={setProgress} unit="%" />
            <div style={{ display: "flex", gap: 12, marginTop: 6 }}>
              <button
                onClick={() => setIsRecording(r => !r)}
                style={{
                  padding: "6px 16px",
                  borderRadius: 6,
                  border: `1.5px solid ${isRecording ? pal.rec : "#37474F"}`,
                  background: isRecording ? hexToRgba(pal.rec, 0.2) : "#0D1A24",
                  color: isRecording ? pal.rec : "#546E7A",
                  cursor: "pointer",
                  fontSize: 11,
                  letterSpacing: "0.5px",
                }}
              >
                {isRecording ? "● REC LIVE" : "○ SIMULATE REC"}
              </button>
            </div>
          </div>
        </div>

        {/* Right — controls */}
        <div style={{
          width: 230,
          borderLeft: "1px solid #1A2530",
          padding: "20px 18px",
          overflowY: "auto",
          flexShrink: 0,
        }}>
          <div style={{ fontSize: 10, color: "#37474F", letterSpacing: "1.5px", marginBottom: 14 }}>
            CUSTOMISATION
          </div>

          <Toggle label="Use Gradient" value={useGradient} onChange={setUseGradient} />
          <Toggle label="Show Playhead" value={showPlayhead} onChange={setShowPlayhead} />

          {showBar && (
            <>
              <div style={{ marginTop: 10, marginBottom: 6, fontSize: 10, color: "#455A64", letterSpacing: "1px" }}>BAR</div>
              <Slider label="Width" value={barW} min={1} max={10} step={0.5} onChange={setBarW} unit="dp" />
              <Slider label="Gap" value={barGap} min={0.5} max={8} step={0.5} onChange={setBarGap} unit="dp" />
            </>
          )}

          {showGlow && (
            <>
              <div style={{ marginTop: 10, marginBottom: 6, fontSize: 10, color: "#455A64", letterSpacing: "1px" }}>GLOW</div>
              <Slider label="Glow Radius" value={glowRadius} min={0} max={24} step={1} onChange={setGlowRadius} unit="px" />
            </>
          )}

          {showMirror && (
            <>
              <div style={{ marginTop: 10, marginBottom: 6, fontSize: 10, color: "#455A64", letterSpacing: "1px" }}>MIRROR</div>
              <Slider label="Reflection Opacity" value={mirrorOpacity} min={0} max={1} step={0.05} onChange={setMirrorOpacity} />
            </>
          )}

          {showDots && (
            <>
              <div style={{ marginTop: 10, marginBottom: 6, fontSize: 10, color: "#455A64", letterSpacing: "1px" }}>DOTS</div>
              <Slider label="Dot Rows" value={dotRows} min={4} max={20} step={1} onChange={setDotRows} />
            </>
          )}

          {showPix && (
            <>
              <div style={{ marginTop: 10, marginBottom: 6, fontSize: 10, color: "#455A64", letterSpacing: "1px" }}>PIXEL</div>
              <Slider label="Pixel Rows" value={pixelRows} min={4} max={20} step={1} onChange={setPixelRows} />
            </>
          )}

          {showWave && (
            <>
              <div style={{ marginTop: 10, marginBottom: 6, fontSize: 10, color: "#455A64", letterSpacing: "1px" }}>WAVE LAYERS</div>
              <Slider label="Layer Count" value={waveLayerCount} min={1} max={6} step={1} onChange={setWaveLayerCount} />
            </>
          )}

          {showPeakCtl && (
            <>
              <div style={{ marginTop: 10, marginBottom: 6, fontSize: 10, color: "#455A64", letterSpacing: "1px" }}>EQUALIZER</div>
              <Toggle label="Peak Dots" value={showPeak} onChange={setShowPeak} />
            </>
          )}

          {showRadial && (
            <>
              <div style={{ marginTop: 10, marginBottom: 6, fontSize: 10, color: "#455A64", letterSpacing: "1px" }}>RADIAL</div>
              <Slider label="Inner Radius" value={radialInner} min={0.1} max={0.5} step={0.01} onChange={setRadialInner} />
            </>
          )}

          {/* All-styles grid preview */}
          <div style={{ marginTop: 20, borderTop: "1px solid #1A2530", paddingTop: 16 }}>
            <div style={{ fontSize: 10, color: "#37474F", letterSpacing: "1.5px", marginBottom: 12 }}>
              ALL STYLES
            </div>
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 6 }}>
              {STYLES.map(s => (
                <div
                  key={s.id}
                  onClick={() => setActiveStyle(s.id)}
                  style={{
                    background: activeStyle === s.id ? hexToRgba(pal.played, 0.15) : "#0A1420",
                    border: `1px solid ${activeStyle === s.id ? hexToRgba(pal.played, 0.4) : "#1A2530"}`,
                    borderRadius: 8, padding: "6px 8px", cursor: "pointer",
                    transition: "all 0.15s",
                  }}
                >
                  <div style={{ background: pal.bg, borderRadius: 4, overflow: "hidden", marginBottom: 4 }}>
                    <WaveformCanvas style={s.id} opts={{...opts, showPlayhead: false}} width={80} height={28} />
                  </div>
                  <div style={{ fontSize: 9, color: activeStyle === s.id ? "#E3F2FD" : "#546E7A", letterSpacing: "0.3px" }}>
                    {s.label}
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
