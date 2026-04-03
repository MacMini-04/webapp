import { useState, useEffect, useCallback } from "react";
import "./App.css";

const DEMO_DATA = [
  { id: 1, name: "Pipeline Deploy", status: "Active", lastRun: "2026-04-03T08:12:00Z", executions: 342, success_rate: 98.2 },
  { id: 2, name: "Data Sync — Postgres", status: "Active", lastRun: "2026-04-03T07:45:00Z", executions: 1087, success_rate: 99.1 },
  { id: 3, name: "Slack Notifications", status: "Paused", lastRun: "2026-04-02T22:30:00Z", executions: 56, success_rate: 100 },
  { id: 4, name: "Invoice Generator", status: "Error", lastRun: "2026-04-03T06:00:00Z", executions: 213, success_rate: 87.4 },
  { id: 5, name: "Lead Enrichment", status: "Active", lastRun: "2026-04-03T09:01:00Z", executions: 780, success_rate: 95.6 },
  { id: 6, name: "Backup — S3", status: "Active", lastRun: "2026-04-03T03:00:00Z", executions: 365, success_rate: 99.9 },
];

function StatusBadge({ status }) {
  const cls = `badge badge--${status.toLowerCase()}`;
  return <span className={cls}>{status}</span>;
}

function formatDate(iso) {
  const d = new Date(iso);
  return d.toLocaleString("en-US", {
    month: "short", day: "numeric", hour: "2-digit", minute: "2-digit",
  });
}

function StatCard({ label, value, sub }) {
  return (
    <div className="stat-card">
      <span className="stat-card__label">{label}</span>
      <span className="stat-card__value">{value}</span>
      {sub && <span className="stat-card__sub">{sub}</span>}
    </div>
  );
}

export default function App() {
  const [webhookUrl, setWebhookUrl] = useState("");
  const [data, setData] = useState(DEMO_DATA);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [search, setSearch] = useState("");
  const [sortCol, setSortCol] = useState(null);
  const [sortDir, setSortDir] = useState("asc");
  const [connected, setConnected] = useState(false);

  const fetchData = useCallback(async () => {
    if (!webhookUrl) return;
    setLoading(true);
    setError(null);
    try {
      const res = await fetch(webhookUrl);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const json = await res.json();
      const rows = Array.isArray(json) ? json : json.data ?? json.items ?? [json];
      setData(rows);
      setConnected(true);
    } catch (e) {
      setError(e.message);
      setConnected(false);
    } finally {
      setLoading(false);
    }
  }, [webhookUrl]);

  useEffect(() => {
    if (webhookUrl) fetchData();
  }, [webhookUrl, fetchData]);

  const columns = data.length > 0 ? Object.keys(data[0]) : [];

  const handleSort = (col) => {
    if (sortCol === col) {
      setSortDir((d) => (d === "asc" ? "desc" : "asc"));
    } else {
      setSortCol(col);
      setSortDir("asc");
    }
  };

  const filtered = data.filter((row) =>
    columns.some((col) =>
      String(row[col] ?? "").toLowerCase().includes(search.toLowerCase())
    )
  );

  const sorted = [...filtered].sort((a, b) => {
    if (!sortCol) return 0;
    const av = a[sortCol], bv = b[sortCol];
    const cmp = typeof av === "number" && typeof bv === "number"
      ? av - bv
      : String(av ?? "").localeCompare(String(bv ?? ""));
    return sortDir === "asc" ? cmp : -cmp;
  });

  const totalRows = data.length;
  const activeCount = data.filter((r) => r.status === "Active").length;
  const errorCount = data.filter((r) => r.status === "Error").length;

  return (
    <div className="app">
      <header className="header">
        <div className="header__left">
          <div className="logo">
            <svg width="28" height="28" viewBox="0 0 28 28" fill="none">
              <rect width="28" height="28" rx="6" fill="var(--accent)" />
              <path d="M8 14h4v6H8zM12 10h4v10h-4zM16 8h4v12h-4z" fill="var(--bg)" />
            </svg>
            <h1 className="logo__text">n8n Dashboard</h1>
          </div>
          <span className={`conn-dot ${connected ? "conn-dot--on" : ""}`}>
            {connected ? "Connected" : "Demo data"}
          </span>
        </div>
        <div className="header__right">
          <input
            className="url-input"
            type="url"
            placeholder="Paste n8n webhook URL…"
            value={webhookUrl}
            onChange={(e) => setWebhookUrl(e.target.value)}
          />
          <button className="btn btn--primary" onClick={fetchData} disabled={!webhookUrl || loading}>
            {loading ? "Loading…" : "Fetch"}
          </button>
        </div>
      </header>

      {error && <div className="error-bar">Error: {error}</div>}

      <section className="stats">
        <StatCard label="Total Rows" value={totalRows} />
        <StatCard label="Active" value={activeCount} sub="workflows" />
        <StatCard label="Errors" value={errorCount} sub={errorCount > 0 ? "needs attention" : "all clear"} />
        <StatCard label="Columns" value={columns.length} />
      </section>

      <section className="table-section">
        <div className="table-toolbar">
          <input
            className="search-input"
            type="search"
            placeholder="Search rows…"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
          <span className="row-count">{sorted.length} of {totalRows} rows</span>
        </div>
        <div className="table-wrap">
          <table className="data-table">
            <thead>
              <tr>
                {columns.map((col) => (
                  <th key={col} onClick={() => handleSort(col)} className="sortable">
                    {col}
                    {sortCol === col && (
                      <span className="sort-arrow">{sortDir === "asc" ? " ↑" : " ↓"}</span>
                    )}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {sorted.length === 0 ? (
                <tr><td colSpan={columns.length} className="empty">No matching rows</td></tr>
              ) : (
                sorted.map((row, i) => (
                  <tr key={row.id ?? i}>
                    {columns.map((col) => (
                      <td key={col}>
                        {col === "status" ? (
                          <StatusBadge status={row[col]} />
                        ) : col === "lastRun" || col === "last_run" ? (
                          formatDate(row[col])
                        ) : col === "success_rate" ? (
                          `${row[col]}%`
                        ) : (
                          String(row[col] ?? "—")
                        )}
                      </td>
                    ))}
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </section>

      <footer className="footer">
        <p>
          Connect your n8n workflow: add a <strong>Webhook</strong> node → set to GET →
          connect a <strong>Respond to Webhook</strong> node returning your data table JSON.
        </p>
      </footer>
    </div>
  );
}
