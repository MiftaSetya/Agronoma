#!/usr/bin/env node
/**
 * Memetakan nama semantik ikon (`data-name`, mis. "mingcute:location-fill")
 * ke berkas aset lokal.
 *
 * `get_design_context` menghasilkan JSX + daftar `const imgX = "<url>"`. Di dalam
 * JSX, elemen yang punya `data-name` menunjukkan nama ikon aslinya, dan elemen
 * itu memakai salah satu `imgX` lewat `src={imgX}`. Skrip ini memasangkan
 * keduanya: untuk tiap `data-name`, ia mengambil `src` pertama SETELAH atribut
 * itu (ikon selalu elemen daun, jadi ini tepat), lalu menerjemahkan `imgX` ke
 * <sha> dari daftar const.
 *
 * Pemakaian: node tool/figma_semantic_map.mjs <nodeId> [<nodeId> ...]
 * Keluaran: namaSemantik|sha|constName (satu per baris), terurut.
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

const call = await connect();
const rows = new Map(); // semantic -> Set(sha)

for (const nodeId of process.argv.slice(2)) {
  const res = await call('get_design_context', {
    nodeId,
    clientLanguages: 'dart',
    clientFrameworks: 'flutter',
  });
  const text = (res?.result?.content ?? [])
    .filter((c) => c.type === 'text')
    .map((c) => c.text ?? '')
    .join('\n');

  // const imgX = ".../<sha>.<ext>"
  const constToSha = new Map();
  for (const m of text.matchAll(/const (\w+) = "http:\/\/localhost:3845\/assets\/([0-9a-f]+)\.(\w+)"/g)) {
    constToSha.set(m[1], m[2]);
  }

  // Kumpulkan token secara berurutan, lalu untuk setiap `src` ambil `data-name`
  // terdekat SEBELUMNYA yang bermakna. Struktur JSX-nya bersarang:
  //   <div data-name="mingcute:location-fill">
  //     <div data-name="Group"><img src={imgGroup2} /></div>
  // jadi `data-name` langsung sebelum src sering hanya "Group"/"Close".
  const tokens = [];
  const tokenRe =
    /data-name="([^"]+)"|src=\{?(img\w+|http:\/\/localhost:3845\/assets\/[0-9a-f]+\.\w+)/g;
  for (const m of text.matchAll(tokenRe)) {
    tokens.push(m[1] !== undefined ? { kind: 'name', value: m[1] } : { kind: 'src', value: m[2] });
  }

  const GENERIC = new Set(['Group', 'Close', 'Container', 'Frame', 'Background', 'Text']);
  for (let i = 0; i < tokens.length; i++) {
    if (tokens[i].kind !== 'src') continue;
    let semantic = null;
    for (let j = i - 1; j >= 0; j--) {
      if (tokens[j].kind !== 'name') continue;
      if (!GENERIC.has(tokens[j].value)) {
        semantic = tokens[j].value;
        break;
      }
      // "Group" milik ikon ini: teruskan mencari nama pembungkusnya.
    }
    if (!semantic) continue;
    const ref = tokens[i].value;
    const sha = ref.startsWith('http')
      ? /assets\/([0-9a-f]+)\./.exec(ref)?.[1]
      : constToSha.get(ref);
    if (!sha) continue;
    if (!rows.has(semantic)) rows.set(semantic, new Set());
    rows.get(semantic).add(sha);
  }
}

for (const [semantic, shas] of [...rows.entries()].sort()) {
  console.log(`${semantic}|${[...shas].join(',')}`);
}
