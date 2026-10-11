#!/usr/bin/env node
/**
 * Alat bantu Figma Dev Mode MCP untuk pengembangan.
 *
 * Figma Desktop menyediakan server MCP lokal di http://127.0.0.1:3845/mcp yang
 * hanya hidup selama Figma terbuka. Skrip ini melakukan handshake MCP-nya
 * (initialize -> notifications/initialized -> tools/call) supaya bisa dipakai
 * dari terminal, tanpa perlu aplikasi klien MCP.
 *
 * Pemakaian:
 *   node tool/figma.mjs metadata   <nodeId>
 *   node tool/figma.mjs context    <nodeId>
 *   node tool/figma.mjs variables  <nodeId>
 *   node tool/figma.mjs screenshot <nodeId> <keluaran.png>
 *
 * Contoh:
 *   node tool/figma.mjs screenshot 10:29 C:\Users\mifta\AppData\Local\Temp\ref\home.png
 */

import { writeFile, mkdir } from 'node:fs/promises';
import { dirname } from 'node:path';

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
      throw new Error(`Balasan MCP tidak bisa dibaca:\n${raw.slice(0, 500)}`);
    }
  };
}

/** Argumen umum yang diminta semua tool Figma. */
const baseArgs = (nodeId) => ({
  nodeId,
  clientLanguages: 'dart',
  clientFrameworks: 'flutter',
});

async function main() {
  const [command, nodeId, outPath] = process.argv.slice(2);
  if (!command || !nodeId) {
    console.error(
      'Pemakaian: node tool/figma.mjs <metadata|context|variables|screenshot> <nodeId> [keluaran.png]',
    );
    process.exit(2);
  }

  const call = await connect();
  const tool = {
    metadata: 'get_metadata',
    context: 'get_design_context',
    variables: 'get_variable_defs',
    screenshot: 'get_screenshot',
  }[command];

  if (!tool) {
    console.error(`Perintah tidak dikenal: ${command}`);
    process.exit(2);
  }

  const res = await call(tool, baseArgs(nodeId));
  const content = res?.result?.content ?? [];

  if (command === 'screenshot') {
    const img = content.find((c) => c.type === 'image');
    if (!img?.data) {
      console.error('Tidak ada gambar pada balasan:', JSON.stringify(res).slice(0, 400));
      process.exit(1);
    }
    if (!outPath) {
      console.error('screenshot butuh argumen <keluaran.png>');
      process.exit(2);
    }
    await mkdir(dirname(outPath), { recursive: true });
    await writeFile(outPath, Buffer.from(img.data, 'base64'));
    console.error(`tersimpan: ${outPath} (${img.mimeType})`);
    return;
  }

  const text = content
    .filter((c) => c.type === 'text')
    .map((c) => c.text ?? '')
    .join('\n');
  process.stdout.write(text);
}

main().catch((err) => {
  console.error(err.message ?? err);
  process.exit(1);
});
