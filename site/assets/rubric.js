// docs/assets/rubric.js
(function () {
    // ---------- Core power rubric F_k(x) ----------
    function Fk(x, k) {
      const xk = Math.pow(x, k);
      const omxk = Math.pow(1 - x, k);
      return xk / (xk + omxk);
    }
  
    function tracePowerK(k, n = 800) {
      const xs = new Array(n), ys = new Array(n);
      for (let i = 0; i < n; i++) {
        const x = (i + 0.5) / n; // avoid exactly 0 and 1
        xs[i] = x;
        ys[i] = Fk(x, k);
      }
      return {
        id: `k-${k}`,
        x: xs,
        y: ys,
        mode: 'lines',
        line: { width: 2 },
        name: `k=${k}`,
        hovertemplate: 'x=%{x:.3f}<br>π_T/D_t=%{y:.3f}<extra></extra>',
        showlegend: true
      };
    }
  
    // ---------- Hybrid 4: Band-pass via slope design & integration ----------
    // Big movement in [mu - ~2σ, mu + ~2σ] and its mirror (1-mu).
    function traceHybridBandpass(mu = 0.75, sigma = 0.05, eps = 0.01, n = 1200) {
      const gaussian = (x, m, s) => {
        const z = (x - m) / s;
        return Math.exp(-0.5 * z * z);
      };
      const xs = new Array(n), w = new Array(n);
      const dx = 1 / n;
  
      for (let i = 0; i < n; i++) {
        const x = (i + 0.5) / n;
        const bump = gaussian(x, mu, sigma) + gaussian(x, 1 - mu, sigma);
        w[i] = bump + eps; // even slope about 0.5
        xs[i] = x;
      }
  
      // Normalize slope so ∫ w = 1
      const sumW = w.reduce((s, v) => s + v, 0) * dx || 1;
      const wn = w.map(v => v / sumW);
  
      // Integrate slope to get G(x)
      const ys = new Array(n);
      let c = 0;
      for (let i = 0; i < n; i++) {
        c += wn[i] * dx; // cumulative integral
        ys[i] = c;
      }
      ys[0] = Math.max(0, Math.min(1, ys[0]));
      ys[n - 1] = 1;
  
      const lo = Math.max(0, (mu - 2 * sigma)).toFixed(2);
      const hi = Math.min(1, (mu + 2 * sigma)).toFixed(2);
  
      return {
        id: 'hyb-band',
        x: xs,
        y: ys,
        mode: 'lines',
        line: { width: 3, dash: 'longdash' },
        name: `Hybrid (band ${lo}–${hi})`,
        hovertemplate: 'x=%{x:.3f}<br>π_T/D_t=%{y:.3f}<extra></extra>',
        showlegend: true
      };
    }
  
    // ---------- Hybrid 1: Exotic cubic (flat center, sharp ends) ----------
    function traceHybridExotic(n = 800) {
      const xs = new Array(n), ys = new Array(n);
      for (let i = 0; i < n; i++) {
        const x = (i + 0.5) / n;
        xs[i] = x;
        ys[i] = 0.5 + 0.5 * Math.pow(2 * x - 1, 3);
      }
      return {
        id: 'hyb-exotic',
        x: xs,
        y: ys,
        mode: 'lines',
        line: { width: 2, dash: 'dashdot' },
        name: 'Hybrid (exotic cubic)',
        hovertemplate: 'x=%{x:.3f}<br>π_T/D_t=%{y:.3f}<extra></extra>',
        showlegend: true
      };
    }
  
    // ---------- Hybrid 2: Piecewise ----------
    function traceHybridPiecewise(n = 800, a = 0.5, b = 2.0) {
      const xs = new Array(n), ys = new Array(n);
      const p0 = 0.2, p1 = 0.4, p2 = 0.6;
      const flatLevel = 0.2 * (a + b); // = 0.5 if a+b=2.5
  
      function G(x) {
        if (x <= p2) {
          if (x < p0) return a * x;                  // shallow
          if (x < p1) return a * p0 + b * (x - p0);  // steep
          return flatLevel;                          // flat
        }
        return 1 - G(1 - x); // mirror
      }
  
      for (let i = 0; i < n; i++) {
        const x = (i + 0.5) / n;
        xs[i] = x;
        ys[i] = G(x);
      }
      return {
        id: 'hyb-piecewise',
        x: xs,
        y: ys,
        mode: 'lines',
        line: { width: 3, dash: 'dot' },
        name: 'Hybrid (piecewise)',
        hovertemplate: 'x=%{x:.3f}<br>π_T/D_t=%{y:.3f}<extra></extra>',
        showlegend: true
      };
    }
  
    // ---------- Hybrid 3: Composite = Σ w_i * F_{k_i}(x) ----------
    function traceHybridCompositeFromKs(
      n = 800,
      parts = [
        { k: 0.5, w: 0.60 },
        { k: 2.0, w: 0.30 },
        { k: 3.0, w: 0.10 }
      ]
    ) {
      const wsum = parts.reduce((s, p) => s + p.w, 0) || 1;
      const xs = new Array(n), ys = new Array(n);
      for (let i = 0; i < n; i++) {
        const x = (i + 0.5) / n;
        let y = 0;
        for (const { k, w } of parts) y += (w / wsum) * Fk(x, k);
        xs[i] = x;
        ys[i] = y;
      }
      return {
        id: 'hyb-composite',
        x: xs,
        y: ys,
        mode: 'lines',
        line: { width: 3 },
        name: 'Hybrid (composite from k)',
        hovertemplate: 'x=%{x:.3f}<br>π_T/D_t=%{y:.3f}<extra></extra>',
        showlegend: true
      };
    }
  
    // ---------- Baseline markers ----------
    function traceBaseline() {
      return {
        id: 'baseline',
        x: [0, 0.5, 1],
        y: [0, 0.5, 1],
        type: 'scatter',
        mode: 'markers',
        name: 'Baseline points',
        marker: { size: 7, symbol: 'circle-open' },
        hoverinfo: 'skip',
        showlegend: false
      };
    }
  
    // ---------- Mount ----------
    const chartEl = document.getElementById('rubric-chart');
    if (!chartEl) return;
  
    // Builders registry
    const builders = {
      'k-0.333': () => tracePowerK(0.333),
      'k-0.5'  : () => tracePowerK(0.5),
      'k-1'    : () => tracePowerK(1),
      'k-2'    : () => tracePowerK(2),
      'k-3'    : () => tracePowerK(3),
      'hyb-exotic'    : () => traceHybridExotic(),
      'hyb-piecewise' : () => traceHybridPiecewise(),
      'hyb-composite' : () => traceHybridCompositeFromKs(),
      'hyb-band'      : () => traceHybridBandpass(0.75, 0.045, 0.008),
      'baseline'      : () => traceBaseline()
    };
  
    // Read selected IDs from either new (.curve-toggle) or old (.k-preset) controls
    function selectedIds() {
      const boxesNew = document.querySelectorAll('.curve-toggle:checked');
      const boxesOld = document.querySelectorAll('.k-preset:checked'); // back-compat
      const idsNew = Array.from(boxesNew).map(el => el.dataset.id);
      // If old style, map values to k-*; no hybrids in old style
      const idsOld = Array.from(boxesOld).map(el => `k-${el.value}`);
      const ids = [...idsNew, ...idsOld];
      return ids;
    }
  
    // If no checkboxes found or none checked, show a default set
    function defaultIds() {
      return ['k-0.333','k-0.5','k-1','k-2','k-3','hyb-composite','baseline'];
    }
  
    function buildData() {
      const order = ['k-0.333','k-0.5','k-1','k-2','k-3','hyb-composite','hyb-piecewise','hyb-exotic','hyb-band','baseline'];
      let ids = selectedIds();
      if (!ids.length) {
        ids = defaultIds();
      }
      const traces = [];
      for (const id of order) {
        if (ids.includes(id) && builders[id]) traces.push(builders[id]());
      }
      return traces;
    }
  
    function render() {
      if (typeof Plotly === 'undefined') {
        console.error('Plotly is not loaded. Make sure the Plotly script is included before rubric.js.');
        return;
      }
  
      const data = buildData();
  
      const layout = {
        title: 'Normalized Power Rubric for Different k',
        xaxis: {
          title: 'Normalized score  x = S / (mn)',
          range: [0, 1],
          zeroline: false,
          automargin: true
        },
        yaxis: {
          title: 'Payout fraction to T  (π_T / D_t)',
          range: [0, 1],
          zeroline: false,
          automargin: true,
          scaleanchor: 'x',  // 1:1 scale
          scaleratio: 1
        },
        margin: { l: 60, r: 20, t: 60, b: 120 },
        legend: { orientation: 'h', y: 1.12, x: 0.5, xanchor: 'center' },
        hovermode: 'closest',
        height: 800
      };
  
      const config = { displayModeBar: true, responsive: true };
      if (chartEl.data) Plotly.react(chartEl, data, layout, config);
      else Plotly.newPlot(chartEl, data, layout, config);
    }
  
    // Re-render on checkbox changes (new controls)
    document.addEventListener('change', (e) => {
      if (e.target && (e.target.classList.contains('curve-toggle') || e.target.classList.contains('k-preset'))) {
        render();
      }
    });
  
    // Initial render (works whether DOMContentLoaded already fired or not)
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', render);
    } else {
      render();
    }
  
    // Optional: keep square on resize
    window.addEventListener('resize', () => {
      if (chartEl && chartEl.data) {
        Plotly.Plots.resize(chartEl);
      }
    });
  })();
  