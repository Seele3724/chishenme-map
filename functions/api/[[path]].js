// Cloudflare Pages Function：把 /api/* 反代到 Supabase
// 目的：绕过 supabase.co 在国内被阻断的问题，前端只改 SUPABASE_URL 常量。

const SUPABASE = "https://vovzusarziwiimbkazqk.supabase.co";

const DROP_REQ = new Set([
  "host", "connection", "content-length", "transfer-encoding",
  "cf-connecting-ip", "cf-ipcountry", "cf-ray", "cf-visitor",
  "cf-worker", "x-forwarded-proto", "x-real-ip", "accept-encoding"
]);

const DROP_RES = new Set([
  "content-encoding", "content-length", "transfer-encoding", "connection",
  "keep-alive", "set-cookie"
]);

export async function onRequest(context) {
  const { request } = context;
  const url = new URL(request.url);
  const path = url.pathname.replace(/^\/api/, "") || "/";
  const target = SUPABASE + path + url.search;

  const headers = new Headers();
  for (const [k, v] of request.headers) {
    if (!DROP_REQ.has(k.toLowerCase())) headers.set(k, v);
  }

  const init = { method: request.method, headers, redirect: "follow" };
  if (request.method !== "GET" && request.method !== "HEAD") {
    init.body = request.body;
  }

  let resp;
  try {
    resp = await fetch(target, init);
  } catch (e) {
    return new Response(
      JSON.stringify({ proxy_error: String(e && e.message || e) }),
      { status: 502, headers: { "content-type": "application/json; charset=utf-8", "access-control-allow-origin": "*" } }
    );
  }

  const out = new Headers();
  for (const [k, v] of resp.headers) {
    if (!DROP_RES.has(k.toLowerCase())) out.set(k, v);
  }
  out.set("access-control-allow-origin", "*");

  return new Response(resp.body, { status: resp.status, headers: out });
}
