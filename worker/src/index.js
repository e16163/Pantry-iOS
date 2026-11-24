// Pantry's free backend on Cloudflare Workers.
//   GET  /photo?title=Garlic%20Butter%20Steak  -> an AI-made JPEG of that dish (or its saved Pixabay photo), kept in KV
//   POST /scan?hints=... (JPEG body; hints are the user's past fixes) -> {"items":[{"name":"egg","count":6}]}
//   POST /recipes {"ingredients":["egg"],"maxMinutes":30,"excluding":["Omelette"]} -> {"recipes":[...3 recipes]}
// Deploy: npx wrangler deploy (from this folder)

const SCAN_PROMPT = "List the food ingredients someone could cook with that you can see in this photo of a fridge, " +
  "freezer, pantry, kitchen counter or groceries. Check every shelf, drawer, door bin and bag. Read the labels on " +
  "bottles, jars, cartons, cans and packets, and name what's inside as specifically as a shopping list would: " +
  "\"canola oil\" not \"oil\", \"sweet chili sauce\" not \"sauce\", \"skim milk\", \"cheddar cheese\". Only list " +
  "what is really there: skip empty packaging, trash, peels, pictures printed on packaging, the ingredient list " +
  "printed on a package (name the product instead), plain water, soda, containers whose contents you can't tell (never just \"can\" or \"jar\"), " +
  "brands and non-food items. Use lowercase singular grocery names and list each ingredient once. count is how many " +
  "whole pieces you can see, like 9 mushrooms, 6 eggs, 3 pears or 2 cans of tomatoes; use 0 only for things " +
  "measured by amount, like milk, juice, sliced cheese, rice or flour. For those, amount and unit say how much " +
  "there is: read the size on the label (a gallon of milk is 3.8 L, a 16 oz block of cheese is 16 oz), or " +
  "estimate what's left from how full it looks; amount is 0 when you can't tell.";

import { DurableObject } from "cloudflare:workers";

// One owner per photo, decided in one place, so two dishes picked at the same moment on different servers can't
// both get it. A stand-in's claim lapses with the stand-in.
export class Claims extends DurableObject {
  async claim(id, title, ttl) {
    const owner = await this.ctx.storage.get(String(id));
    if (owner && owner.title !== title && owner.until > Date.now()) return false;
    await this.ctx.storage.put(String(id), { title, until: ttl ? Date.now() + ttl * 1000 : Number.MAX_SAFE_INTEGER });
    return true;
  }
}

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    try {
      if (request.method === "GET" && url.pathname === "/photo") return await photo(url, env);
      if (request.method === "POST" && url.pathname === "/scan") return await scan(request, env);
      if (request.method === "POST" && url.pathname === "/recipes") return await recipes(request, env, ctx);
      if (request.method === "POST" && url.pathname === "/photo-eval") return await photoEval(request, env);
    } catch (error) {
      return Response.json({ error: String(error) }, { status: 502 });
    }
    return new Response("Not found", { status: 404 });
  },
};

async function photo(url, env) {
  const title = url.searchParams.get("title") ?? "";
  if (!title.trim()) return new Response("Missing title", { status: 400 });
  const headers = { "content-type": "image/jpeg", "cache-control": "public, max-age=31536000, immutable" };
  return new Response(await dishPhoto(env, title), { headers });
}

// A real stock photo of exactly this dish, found with the photo search the recipe AI wrote ("spinach omelette"),
// else with the title. When no photo shows it, a picture is made from the title (capped at 3 s).
// Recipes wait at most 1.5 s for their photo. A check still running then keeps going in the background, and the
// best-ranked photo (downloaded while the check runs) stands in for 6 h; an exact match found afterwards replaces
// it for everyone from then on.
async function quickPhoto(env, ctx, rawTitle, query) {
  let closest;
  const full = dishPhoto(env, rawTitle, query, (hit) => {
    closest = { hit, bytes: fetch(hit.largeImageURL).then((r) =>
      (r.ok && r.headers.get("content-type")?.startsWith("image/") ? r.arrayBuffer() : null), () => null) };
  }).catch(() => {});
  const finished = await Promise.race([full.then(() => true), new Promise((done) => setTimeout(done, 1_500, false))]);
  if (finished) return;
  ctx.waitUntil(full);
  const bytes = await closest?.bytes;
  if (!bytes) return full;
  const title = dishTitle(rawTitle), options = { expirationTtl: 6 * 3600 };
  await Promise.all([env.PHOTOS.put(`dish:${title}`, bytes, options),
    env.PHOTOS.put(`claimed:${closest.hit.id}`, title, options)]);
}

const dishTitle = (raw) => raw.trim().toLowerCase().replace(/\s+/g, " ").slice(0, 120);

async function dishPhoto(env, rawTitle, query, onRanked) {
  const title = dishTitle(rawTitle);
  const known = await env.PHOTOS.get(`dish:${title}`, "arrayBuffer");
  if (known) return known;
  const choice = env.PIXABAY_KEY && await choosePhoto(env, title, query, taking, { onRanked }).catch(() => null);
  if (choice?.id) {
    // Every sure match is shared, so the next "spinach omelette" anyone gets needs no looking.
    if (choice.verified.length) {
      await env.PHOTOS.put(`verified:${choice.dishName}`,
        JSON.stringify([...choice.library, ...choice.verified.map((id) => ({ id }))]));
    }
    const bytes = await keep(env, title, choice);
    if (bytes) return bytes;
  }
  // No exact Pixabay photo yet: the closest one, kept 6 hours so the dish gets an exact photo later.
  const standIn = choice?.closest?.() ??
    (env.PIXABAY_KEY && await choosePhoto(env, title, query, taking, { standIn: true }).catch(() => null));
  const bytes = standIn?.id && await keep(env, title, standIn, 6 * 3600);
  if (!bytes) throw new Error(`no Pixabay photo for ${title}`);
  return bytes;
}

// Runs the photo picker on a list of dishes without saving anything, skipping the shared library and past claims,
// so the search and check can be measured and rerun: POST {dishes: [{title, query}], taken: [ids]}.
async function photoEval(request, env) {
  const { dishes, taken = [], groq } = await request.json();
  if (groq) env = { ...env, GEMINI_KEY: undefined };  // measures the backup checker
  const batch = new Set(taken);
  const results = await Promise.all(dishes.map(async ({ title, query }) => {
    const started = Date.now();
    const choice = await choosePhoto(env, title.toLowerCase(), query, batch, { library: false, claims: false })
      .catch((error) => ({ miss: String(error) }));
    return { title, query, ...choice, ms: Date.now() - started };
  }));
  return Response.json({ results, taken: [...batch] });
}

const PROTEINS = ["shrimp", "prawn", "chicken", "beef", "pork", "bacon", "ham", "sausage", "salmon", "tuna", "fish",
  "meat", "lamb", "turkey", "crab", "lobster", "steak", "mussels", "squid"];
const RAW = ["raw", "plant", "garden", "growing", "grow", "harvest", "field", "seedling", "agriculture", "market",
  "ingredient", "uncooked", "isolated", "dough", "farm", "organic"];
const DISHES = ["soup", "stew", "chili", "salad", "taco", "burrito", "bowl", "pasta", "noodle", "spaghetti", "curry",
  "sandwich", "toast", "pizza", "burger", "smoothie", "pancake", "waffle", "omelette", "omelet", "rice", "cake", "pie",
  "wrap", "quesadilla", "fry", "hash", "skewer", "kebab", "dumpling", "roll", "risotto", "casserole", "frittata",
  "scramble", "bake", "gratin", "lasagna", "salmon", "steak", "bruschetta", "muffin", "porridge", "oatmeal"];
// Photos picked by this server, so two dishes picked at once don't both take the same one.
const taking = new Set();
const geminiOut = new Map();
const SERVED = ["dish", "plate", "meal", "dinner", "lunch", "breakfast", "served", "cuisine", "delicious", "tasty"];

// Picks this dish's photo: a Pixabay photo showing exactly this dish that no other dish has, from the shared
// library of checked photos, else searched ("garlic butter steak", then "butter steak", then "steak") and looked at.
// Only reads; dishPhoto saves. Returns a Choice {id, url, image, source, dishName, library, verified} or {miss}.
// The chosen id is added to `taken` with no wait in between, so dishes picked at the same moment can't share one.
async function choosePhoto(env, title, query, taken, { library: useLibrary = true, claims = true, standIn = false, onRanked } = {}) {
  // Words that describe the cooking, not the dish, only confuse a photo search.
  const filler = /^(quick|easy|simple|homemade|classic|best|cheesy|creamy|spicy|crispy|savory|fresh|hearty|light|healthy|veggie|loaded|one|pan|skillet|style|with|and|&|on|the|a|of|in)$/;
  const words = String(query || title).toLowerCase().split(/[^a-z]+/).filter((word) => word && !filler.test(word));
  // The dish goes last ("pasta mushroom" searches as "mushroom pasta"), since searches drop words from the front.
  const dish = words.findLast((word) => DISHES.includes(word.replace(/e?s$/, "")));
  if (dish) words.push(...words.splice(words.indexOf(dish), 1));
  const dishName = words.join(" ");
  const claimed = (ids) => (claims ? Promise.all(ids.map((id) => env.PHOTOS.get(`claimed:${id}`))) : ids.map(() => null));
  // Photos already checked to show exactly this dish, for anyone: the first one no dish has taken is used at once.
  const library = useLibrary ? JSON.parse(await env.PHOTOS.get(`verified:${dishName}`) ?? "[]") : [];
  const libraryUsed = await claimed(library.map((photo) => photo.id));
  // Takes a photo for this dish if no other dish has it: in this batch (taken) and, for real picks, everywhere.
  const owns = async (id, ttl) => {
    if (taken.has(id)) return false;
    if (claims && !await env.CLAIMS.get(env.CLAIMS.idFromName("photos")).claim(id, title, ttl)) return false;
    taken.add(id);
    return true;
  };
  const firstOwned = async (list, ttl) => {
    for (const item of list) if (await owns(item.id, ttl)) return item;
    return null;
  };
  const ready = standIn ? null : await firstOwned(library.filter((photo, j) => !libraryUsed[j]));
  if (ready) return { id: ready.id, source: "library", dishName, library, verified: [] };
  const searches = await Promise.all(words.slice(0, 3).map((_, i) => searchPixabay(env, words.slice(i).join(" "))));
  // Only photos tagged with the dish itself (the last word: "quesadilla", not "beef" or "cheese"), most specific
  // search first, each once; among those, more matching words go first (a stable sort keeps search order).
  const tagged = (hit, word) => hit.tags.toLowerCase().includes(word.replace(/e?s$/, ""));
  // More of the search words, then tags that say it's a served meal.
  const score = (hit) => words.filter((word) => tagged(hit, word)).length + (SERVED.some((word) => tagged(hit, word)) ? 0.5 : 0);
  const hits = [...new Map(searches.flat().map((hit) => [hit.id, hit])).values()]
    .filter((hit) => standIn || tagged(hit, words.at(-1)))
    // A photo with meat or seafood the dish doesn't have is a different dish: shrimp pasta isn't spinach pasta.
    .filter((hit) => !PROTEINS.some((meat) => tagged(hit, meat) && !title.includes(meat.replace(/e?s$/, ""))))
    // Growing plants and raw ingredients aren't a cooked dish.
    .filter((hit) => !RAW.some((word) => tagged(hit, word)))
    .sort((a, b) => score(b) - score(a));
  // Each photo goes to one dish only, so similar titles don't share a picture.
  const used = await claimed(hits.map((hit) => hit.id));
  const free = hits.filter((hit, j) => !used[j] && !library.some((photo) => photo.id === hit.id));
  const found = (hit, source, verified) => {
    return { id: hit.id, url: hit.largeImageURL, image: hit.webformatURL, source, dishName, library, verified };
  };
  if (standIn) {
    const first = await firstOwned(free, 6 * 3600);
    return first ? found(first, "standin", []) : { miss: "no-candidates" };
  }
  const open = free.filter((hit) => !taken.has(hit.id));
  // The best-ranked free photo is held for this dish at once: it may stand in before the check ends, and a dish
  // picked in the same moment must not stand in with the same photo.
  const held = await firstOwned(open, 6 * 3600);
  if (!held) return { miss: "no-candidates" };
  onRanked?.(held);
  const closest = () => found(held, "standin", []);
  // Photos already looked at for this dish and turned down are never sent to the checker again.
  const rejected = useLibrary ? JSON.parse(await env.PHOTOS.get(`rejected:${dishName}`) ?? "[]") : [];
  const candidates = open.filter((hit) => !rejected.includes(hit.id)).slice(0, 6);
  if (candidates.length === 0) return { miss: "none-exact", closest };
  // Looked at, not guessed from tags: only photos that really show this dish count.
  const exact = await exactPhotos(env, dishName, title, candidates);
  if (exact === null) return { miss: "checker-busy", closest };
  const turnedDown = candidates.filter((hit) => !exact.includes(hit)).map((hit) => hit.id);
  if (useLibrary && turnedDown.length) {
    await env.PHOTOS.put(`rejected:${dishName}`, JSON.stringify([...new Set([...rejected, ...turnedDown])]));
  }
  let pick = null;
  for (const hit of exact) {
    // The held photo is already this dish's; its claim just stops lapsing.
    const ours = hit.id === held.id
      ? !claims || await env.CLAIMS.get(env.CLAIMS.idFromName("photos")).claim(hit.id, title)
      : await owns(hit.id);
    if (ours) { pick = hit; break; }
  }
  return pick ? found(pick, "search", exact.map((hit) => hit.id)) : { miss: "none-exact", closest };
}

// Saves a Choice as this dish's photo and marks it claimed, or null if it can't be had. Library photos carry no
// link, since links expire, so Pixabay is asked for a fresh one.
// Pixabay asks for searches to be cached 24 h; the same dish searched again then costs no request.
async function searchPixabay(env, q) {
  const saved = await env.PHOTOS.get(`search:${q}`, "json");
  if (saved) return saved;
  const hits = await fetch(`https://pixabay.com/api/?key=${env.PIXABAY_KEY}&image_type=photo&category=food` +
    `&orientation=horizontal&safesearch=true&per_page=20&q=${encodeURIComponent(q)}`,
    { headers: { "user-agent": "PantryApp/1.0 (recipe photos)" } })
    .then((response) => (response.ok ? response.json() : {})).then((json) => json.hits, () => undefined);
  if (!hits) return [];
  const kept = hits.map(({ id, tags, previewURL, webformatURL, largeImageURL }) =>
    ({ id, tags, previewURL, webformatURL, largeImageURL }));
  await env.PHOTOS.put(`search:${q}`, JSON.stringify(kept), { expirationTtl: 24 * 3600 });
  return kept;
}

async function keep(env, title, choice, ttl) {
  const fresh = () => fetch(`https://pixabay.com/api/?key=${env.PIXABAY_KEY}&id=${choice.id}`,
    { headers: { "user-agent": "PantryApp/1.0 (recipe photos)" } })
    .then((r) => (r.ok ? r.json() : {}), () => ({})).then((found) => found.hits?.[0]?.largeImageURL);
  const get = async (url) => (url ? fetch(url) : { ok: false, headers: new Headers() });
  let image = await get(choice.url ?? await fresh());
  // A link from a cached search can have expired; a fresh one comes from looking the photo up by id.
  if (!image.ok && choice.url) image = await get(await fresh());
  // Pixabay answers "Rate limit exceeded" as text when busy; that must never be saved as the dish's photo.
  if (!image.ok || !image.headers.get("content-type")?.startsWith("image/")) return null;
  const bytes = await image.arrayBuffer();
  const options = ttl ? { expirationTtl: ttl } : {};
  await Promise.all([env.PHOTOS.put(`dish:${title}`, bytes, options), env.PHOTOS.put(`claimed:${choice.id}`, title, options)]);
  return bytes;
}

// Gemini looks at the photos and says which show exactly this dish: the photos that do, [] for none, or null when
// it's busy. The newer Flash-Lite is asked first; the other, which has its own quota, only if that one fails.
async function exactPhotos(env, dishName, title, hits) {
  if (hits.length === 0) return [];
  if (!env.GEMINI_KEY) return groqExactPhotos(env, dishName, title, hits).catch(() => null);
  const images = await Promise.all(hits.map(async (hit) => {
    const bytes = new Uint8Array(await (await fetch(hit.webformatURL.replace("_640", "_340"))).arrayBuffer());
    return { inline_data: { mime_type: "image/jpeg", data: bytes.toBase64() } };
  }));
  const body = JSON.stringify({
    contents: [{ parts: [{ text: `These are photos 0 to ${hits.length - 1}. Which of them show exactly ` +
      `"${dishName}" (from a recipe called "${title}"), cooked and served? It must be the same kind of dish (a ` +
      "hamburger is not a sandwich, raclette is not pasta, a buffet or a table of foods is not one dish, plain rice " +
      "is not fried rice) with its main named ingredient visible, and no meat or seafood the dish doesn't have. " +
      "Raw ingredients, text, or any doubt mean no." }, ...images] }],
    generationConfig: { responseMimeType: "application/json", responseSchema: { type: "OBJECT",
      properties: { exact: { type: "ARRAY", items: { type: "INTEGER" } } }, required: ["exact"] } },
  });
  // One budget for every try: a model that hangs (seen at 6 s) must not push the photo past the 3-5 s goal.
  const deadline = Date.now() + 3_500;
  const ask = async (model, key) => {
    // A model and key out of quota stay out until the daily reset; skipping them saves a round trip each.
    if (geminiOut.get(model + key) > Date.now()) throw new Error(`${model} out`);
    const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
      { method: "POST", body, signal: AbortSignal.timeout(Math.max(1, Math.min(2_000, deadline - Date.now()))),
        headers: { "content-type": "application/json", "x-goog-api-key": key } });
    if (response.status === 429) geminiOut.set(model + key, Date.now() + 15 * 60_000);
    if (!response.ok) throw new Error(`${model} ${response.status}`);
    return JSON.parse((await response.json()).candidates[0].content.parts[0].text).exact;
  };
  try {
    // One model at a time: asking both at once used two of the free daily requests scans also need.
    // GEMINI_KEY_2 (optional) is only asked once both models are out on the first key.
    let exact;
    for (const key of [env.GEMINI_KEY, env.GEMINI_KEY_2].filter(Boolean)) {
      // Latest first: it answered in about 1 s while 3.5 took 1.5-2 s or hung (measured 2026-11-23).
      exact = await ask("gemini-flash-lite-latest", key).catch(() => ask("gemini-3.5-flash-lite", key)).catch(() => null);
      if (exact) break;
    }
    if (!exact) throw new Error("gemini busy");
    return [...new Set(exact)].filter((i) => hits[i]).map((i) => hits[i]);
  } catch {
    return groqExactPhotos(env, dishName, title, hits).catch(() => null);
  }
}

// Gemini's free quota is out: Groq's vision model looks instead. Its free tier allows one
// minute's worth of 7,000 input tokens, and each photo costs about 1,800, so each dish of a 3-recipe batch
// sends only its best-ranked photo.
async function groqExactPhotos(env, dishName, title, hits) {
  if (!env.GROQ_KEY) return null;
  hits = hits.slice(0, GROQ_PHOTOS);
  const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
    method: "POST",
    signal: AbortSignal.timeout(5_000),
    headers: { "content-type": "application/json", authorization: `Bearer ${env.GROQ_KEY}` },
    body: JSON.stringify({
      model: "qwen/qwen3.8-27b",
      messages: [{ role: "user", content: [
        { type: "text", text: `These are photos 0 to ${hits.length - 1}. Which show exactly "${dishName}" (from a ` +
          `recipe called "${title}"), cooked and served? It must be the same kind of dish with its main named ` +
          "ingredient visible, one dish not a table of foods, and no meat or seafood the dish doesn't have. Raw " +
          'ingredients, text, or any doubt mean no. Answer only with JSON like {"exact":[0]}.' },
        ...hits.map((hit) => ({ type: "image_url", image_url: { url: hit.previewURL } })),
      ] }],
      response_format: { type: "json_object" },
      max_tokens: 30,
    }),
  });
  if (!response.ok) throw new Error(`groq ${response.status}`);
  const exact = JSON.parse((await response.json()).choices[0].message.content).exact ?? [];
  return [...new Set(exact)].filter((i) => hits[i]).map((i) => hits[i]);
}
const GROQ_PHOTOS = 1;

async function scan(request, env) {
  const photo = new Uint8Array(await request.arrayBuffer());
  if (photo.length === 0 || photo.length > 15_000_000) return new Response("Bad photo", { status: 400 });
  const hints = new URL(request.url).searchParams.get("hints")?.slice(0, 1000);

  const prompt = hints ? `${SCAN_PROMPT} This user has corrected past scans: ${hints}.` : SCAN_PROMPT;
  const image = photo.toBase64();
  let text, failure;
  // The second key's own quota is used once the first key's is gone, before the weaker Groq backup.
  for (const key of [env.GEMINI_KEY, env.GEMINI_KEY_2].filter(Boolean)) {
    if (text) break;
    text = await readTwice(env, key, {
        contents: [{ parts: [
          { text: prompt },
          { inline_data: { mime_type: "image/jpeg", data: image } },
        ] }],
        generationConfig: {
          responseMimeType: "application/json",
          responseSchema: {
            type: "OBJECT",
            properties: { items: { type: "ARRAY", items: {
              type: "OBJECT",
              properties: { name: { type: "STRING" }, count: { type: "INTEGER" }, amount: { type: "NUMBER" },
                unit: { type: "STRING", enum: ["g", "kg", "ml", "L", "lb", "oz", "none"] } },
              required: ["name", "count", "amount", "unit"],
            } } },
            required: ["items"],
          },
        },
      }).catch((error) => { failure = error; });
  }
  if (!text) {
    if (!env.GROQ_KEY || new URL(request.url).searchParams.has("gemini")) throw failure;
    text = await groqScan(env, prompt, image);  // Gemini's free quota ran out or Google is down
  }
  return new Response(text, { headers: { "content-type": "application/json" } });
}

// Flash-Lite sometimes stops after the first few things it sees, so two reads run at once and their lists are
// merged. They use two Flash-Lite versions, each with its own free quota and capacity, so one being busy
// doesn't sink the scan. The second gets 0.5 s more than the first: answers land within 0.4 s of each other, and
// waiting longer only waited on a busy model's retry.
async function readTwice(env, key, request) {
  const reads = ["gemini-flash-lite-latest", "gemini-3.5-flash-lite"]
    .map((model) => gemini(env, request, 2_500, 5_000, model, key).then((text) => JSON.parse(text).items));
  const first = await Promise.any(reads).catch((error) => { throw new Error(error.errors.map(String).join(" | ")); });
  const both = await Promise.race([Promise.allSettled(reads), new Promise((resolve) => setTimeout(resolve, 500))]);
  const lists = both ? both.filter((r) => r.status === "fulfilled").map((r) => r.value) : [first];
  const merged = new Map();
  for (const item of lists.flat()) {
    const key = item.name.trim().toLowerCase();
    const seen = merged.get(key);
    merged.set(key, { ...item, ...seen, name: key, count: Math.max(item.count, seen?.count ?? 0),
      ...(!seen?.amount && item.amount ? { amount: item.amount, unit: item.unit } : {}) });
  }
  // "butter" next to "salted butter" is the same thing; keep the more specific name.
  const names = [...merged.keys()];
  const items = [...merged.values()].filter(({ name }) =>
    !names.some((other) => other !== name && (other.endsWith(` ${name}`) || other.startsWith(`${name} `))));
  return JSON.stringify({ items });
}

async function groqScan(env, prompt, image) {
  const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
    method: "POST",
    signal: AbortSignal.timeout(10_000),
    headers: { "content-type": "application/json", authorization: `Bearer ${env.GROQ_KEY}` },
    body: JSON.stringify({
      model: "qwen/qwen3.8-27b",
      messages: [{ role: "user", content: [
        { type: "text", text: `${prompt} Answer only with JSON like {"items":[{"name":"egg","count":6,"amount":0,"unit":""},{"name":"skim milk","count":0,"amount":3.8,"unit":"L"}]}.` },
        { type: "image_url", image_url: { url: `data:image/jpeg;base64,${image}` } },
      ] }],
      response_format: { type: "json_object" },
      max_tokens: 500,  // the free tier allows 1,000 output tokens a minute on this model
    }),
  });
  if (!response.ok) throw new Error(`groq ${response.status}: ${(await response.text()).slice(0, 300)}`);
  // Qwen sometimes answers with the bare list instead of {"items": [...]}.
  const answer = JSON.parse((await response.json()).choices[0].message.content);
  return JSON.stringify(Array.isArray(answer) ? { items: answer } : answer);
}

const RECIPE_RULES = "You are a home cook writing recipes for a cookbook. Pick the few ingredients from the user's list that " +
  "make a real, well-known kind of dish; it doesn't need to use them all. Use only the ingredients the user lists, " +
  "plus basic staples: salt, pepper, oil, and water. Never add other ingredients. Name each ingredient exactly as " +
  "it appears in the user's list. Give an amount for every ingredient, for 2 servings, in the same order. " +
  "Write 5 to 8 steps a beginner can follow without guessing: how to cut things, the heat level, how many " +
  "minutes, and what it should look, smell or feel like when it's done." +
  " photo is the 2 or 3 words you'd type into a stock-photo site to find this finished dish as served: its one " +
  "main visible ingredient, then the most common name for the kind of dish, which always comes last, like " +
  "\"spinach omelette\", \"beef tacos\", \"egg fried rice\", \"chicken stir fry\", \"cheese quesadilla\" or " +
  "\"grilled cheese sandwich\". No cooking words like easy, quick or homemade.";

async function recipes(request, env, ctx) {
  const { ingredients, maxMinutes, excluding } = await request.json();
  if (!Array.isArray(ingredients) || ingredients.length === 0) return new Response("Missing ingredients", { status: 400 });
  const list = (items, n) => items.slice(0, n).map((item) => String(item).slice(0, 60)).join(", ");
  let rules = "";
  if (Number.isInteger(maxMinutes)) rules += ` It must take at most ${maxMinutes} minutes in total.`;
  if (Array.isArray(excluding) && excluding.length) rules += ` Don't suggest any of these: ${list(excluding.slice(-40), 40)}.`;
  // Three short requests at once are about 3x faster than one long one; each gets its own kind of dish so
  // the three don't repeat each other.
  const kinds = ["breakfast, like an egg dish, toast or pancakes, never pasta", "lunch: a salad, sandwich, wrap, soup or " +
    "rice bowl, never pasta", "a dinner main course"];
  // Each recipe's photo is made as soon as that recipe is written, so the app's photo requests find it saved.
  const results = await Promise.allSettled(kinds.map((kind) => oneRecipe(env,
    `Write 1 recipe for ${kind}. Choose from these ingredients: ${list(ingredients, 80)}.${rules}`)
    .then(async (recipe) => { await quickPhoto(env, ctx, recipe.title, recipe.photo); return recipe; })));
  // The same title twice is one dish shown twice, with one photo.
  const found = [...new Map(results.filter((r) => r.status === "fulfilled")
    .map((r) => [r.value.title.toLowerCase(), r.value])).values()];
  if (found.length === 0) throw results[0].reason;
  return Response.json({ recipes: found });
}

const RECIPE_SCHEMA = {
  type: "object",
  properties: {
    title: { type: "string" },
    minutes: { type: "integer" },
    difficulty: { type: "string", enum: ["Easy", "Medium", "Hard"] },
    ingredients: { type: "array", items: { type: "string" } },
    amounts: { type: "array", items: { type: "string" } },
    steps: { type: "array", items: { type: "string" } },
    photo: { type: "string" },
  },
  required: ["title", "minutes", "difficulty", "ingredients", "amounts", "steps", "photo"],
  additionalProperties: false,
};

// Groq (free, ~1 s) first; once its free daily limit is used up, or without a key, Gemini (~5 s).
async function oneRecipe(env, prompt) {
  if (env.GROQ_KEY) {
    try {
      return { ...(await groq(env, prompt)), by: "groq" };
    } catch (error) {
      console.log(String(error));
    }
  }
  return { ...(await geminiRecipe(env, prompt)), by: "gemini" };
}

async function groq(env, prompt) {
  const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
    method: "POST",
    signal: AbortSignal.timeout(6_000),
    headers: { "content-type": "application/json", authorization: `Bearer ${env.GROQ_KEY}` },
    body: JSON.stringify({
      model: "openai/gpt-oss-120b",
      reasoning_effort: "low",
      messages: [{ role: "system", content: RECIPE_RULES }, { role: "user", content: prompt }],
      response_format: { type: "json_schema", json_schema: { name: "recipe", strict: true, schema: RECIPE_SCHEMA } },
    }),
  });
  if (!response.ok) throw new Error(`groq ${response.status}: ${(await response.text()).slice(0, 300)}`);
  return JSON.parse((await response.json()).choices[0].message.content);
}

async function geminiRecipe(env, prompt) {
  const text = await gemini(env, {
    systemInstruction: { parts: [{ text: RECIPE_RULES }] },
    contents: [{ parts: [{ text: prompt }] }],
    generationConfig: {
      responseMimeType: "application/json",
      responseSchema: {
        type: "OBJECT",
        properties: {
          title: { type: "STRING" },
          minutes: { type: "INTEGER" },
          difficulty: { type: "STRING", enum: ["Easy", "Medium", "Hard"] },
          ingredients: { type: "ARRAY", items: { type: "STRING" } },
          amounts: { type: "ARRAY", items: { type: "STRING" } },
          steps: { type: "ARRAY", items: { type: "STRING" } },
          photo: { type: "STRING" },
        },
        required: ["title", "minutes", "difficulty", "ingredients", "amounts", "steps", "photo"],
      },
    },
  }, 3_000, 12_000);
  return JSON.parse(text);
}

// Flash-Lite answers fast. When Google is overloaded it can hang, so if it hasn't answered in `hedge` ms
// (or has failed) Flash is asked too, and whichever answers first wins. Each call gives up after `timeout` ms.
async function gemini(env, request, hedge, timeout, model = "gemini-flash-lite-latest", key = env.GEMINI_KEY) {
  const body = JSON.stringify(request);
  const ask = async (model) => {
    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
      { method: "POST", body, signal: AbortSignal.timeout(timeout),
        headers: { "content-type": "application/json", "x-goog-api-key": key } });
    if (!response.ok) throw new Error(`${model} ${response.status}: ${(await response.text()).slice(0, 300)}`);
    return (await response.json()).candidates[0].content.parts[0].text;
  };
  let answered = false;
  const lite = ask(model);
  lite.then(() => { answered = true; }, () => {});
  // Flash also starts right away if Flash-Lite fails, like when its free daily quota is used up.
  const backup = new Promise((resolve) => { setTimeout(resolve, hedge); lite.catch(resolve); })
    .then(() => (answered ? lite : ask("gemini-flash-latest")));
  try {
    return await Promise.any([lite, backup]);
  } catch (error) {
    // Out of quota (429) stays out until the daily reset, so waiting and retrying only adds time.
    if (error.errors.every((e) => String(e).includes(" 429"))) throw error;
    // Google's "high demand" 503s are per model, so one more try goes right away to a newer Flash-Lite with its own capacity.
    try {
      return await ask("gemini-3.5-flash-lite");
    } catch (retry) {
      throw new Error([...error.errors, retry].map(String).join(" | "));
    }
  }
}

