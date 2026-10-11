#!/usr/bin/env node
/**
 * Mengumpulkan semua deklarasi aset (`const imgX = "http://localhost:3845/assets/<sha>.<ext>"`)
 * dari beberapa node Figma sekaligus, lalu memetakan <sha> ke path lokal.
 *
 * Dipakai sekali untuk membuat `docs/asset-map.md` (nama semantik -> sha -> file
 * lokal). Tidak dipakai saat runtime aplikasi.
 *
 * Pemakaian: node tool/figma_assets.mjs <nodeId> [<nodeId> ...]
 */

const MCP_URL = process.env.FIGMA_MCP_URL ?? 'http://127.0.0.1:3845/mcp';

async function connect() {
  const base = {
    'content-type': 'application/json',
    accept: 'application/json, text/event-stream',
  };
  const initRes = await fetch(MCP_URL, {
    method: 'POST',
    headers: base,
    body: JSON.stringify({
      jsonrpc: '2.0',
      id: 1,
      method: 'initialize',
      params: {
        protocolVersion: '2024-11-05',
        capabilities: {},
        clientInfo: { name: 'agronoma-tool', version: '1.0.0' },
      },
    }),
  });
  await initRes.text();
  const headers = { ...base };
  const sid = initRes.headers.get('mcp-session-id');
  if (sid) headers['mcp-session-id'] = sid;
  await fetch(MCP_URL, {
    method: 'POST',
    headers,
    body: JSON.stringify({ jsonrpc: '2.0', method: 'notifications/initialized' }),
  }).then((r) => r.text());

  return async (name, args) => {
    const r = await fetch(MCP_URL, {
      method: 'POST',
      headers,
      body: JSON.stringify({
        jsonrpc: '2.0',
        id: 2,
        method: 'tools/call',
        params: { name, arguments: args },
      }),
    });
    const raw = await r.text();
    const data = raw
      .split('\n')
      .filter((l) => l.startsWith('data:'))
      .map((l) => l.slice(5).trim())
      .join('');
    try {
      return JSON.parse(data || raw);
    } catch {
      return { raw: raw.slice(0, 300) };
    }
  };
}

const nodes = process.argv.slice(2);
const call = await connect();

const seen = new Map(); // name -> url
const byUrl = new Map(); // url -> names[]

for (const nodeId of nodes) {
  const res = await call('get_design_context', {
    nodeId,
    clientLanguages: 'dart',
    clientFrameworks: 'flutter',
  });
  const text = (res?.result?.content ?? [])
    .filter((c) => c.type === 'text')
    .map((c) => c.text ?? '')
    .join('\n');

  for (const m of text.matchAll(/const (\w+) = "(http:\/\/localhost:3845\/assets\/[^"]+)"/g)) {
    const [, name, url] = m;
    seen.set(name, url);
    if (!byUrl.has(url)) byUrl.set(url, []);
    byUrl.get(url).push(name);
  }
}

const rows = [...byUrl.entries()].map(([url, names]) => {
  const file = url.split('/').pop();
  const ext = file.split('.').pop();
  return {
    file,
    dir: ext === 'svg' ? 'assets/icons' : 'assets/images',
    names: [...new Set(names)].sort(),
  };
});
rows.sort((a, b) => a.file.localeCompare(b.file));

for (const r of rows) {
  console.log(`${r.file}|${r.dir}|${r.names.join(', ')}`);
}
console.error(`${rows.length} aset unik dari ${nodes.length} node`);
