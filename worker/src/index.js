// Pantry's free backend on Cloudflare Workers.
//   GET  /photo?title=Garlic%20Butter%20Steak  -> a JPEG of the dish, made once and then served from KV
//   POST /scan?hints=... (JPEG body; hints are the user's past fixes) -> {"items":[{"name":"egg","count":6}]}
//   POST /recipes {"ingredients":["egg"],"maxMinutes":30,"excluding":["Omelette"]} -> {"recipes":[...3 recipes]}
// Deploy: npx wrangler deploy (from this folder)

// Plain, real-photo wording: words like "moody" or "saturated" make it look AI-made.
const STYLE = "real photo taken with a DSLR for a food delivery app menu, as actually served at a good " +
  "restaurant, 45 degree angle, natural daylight, true-to-life colors, real textures, crumbs and " +
  "imperfections, simple plate on a wooden table, no text, no hands";

const SCAN_PROMPT = "List every food ingredient you can see in this photo of a fridge, pantry or kitchen counter. " +
  "Only things you can actually see; skip containers, brands and non-food items. Read labels on jars, cartons " +
  "and cans. Use plain grocery names in the singular, lowercase, like \"egg\", \"bell pepper\" or \"soy sauce\". " +
  "count is how many separate pieces you can count, or 0 if it isn't countable, like milk or rice.";

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    try {
      if (request.method === "GET" && url.pathname === "/photo") return await photo(url, env);
      if (request.method === "POST" && url.pathname === "/scan") return await scan(request, env);
      if (request.method === "POST" && url.pathname === "/recipes") return await recipes(request, env);
    } catch (error) {
      return Response.json({ error: String(error) }, { status: 502 });
    }
    return new Response("Not found", { status: 404 });
  },
};

async function photo(url, env) {
  const title = (url.searchParams.get("title") ?? "").trim().toLowerCase().replace(/\s+/g, " ").slice(0, 120);
  if (!title) return new Response("Missing title", { status: 400 });
  const headers = { "content-type": "image/jpeg", "cache-control": "public, max-age=31536000, immutable" };
  const saved = await env.PHOTOS.get(title, "arrayBuffer");
  if (saved) return new Response(saved, { headers });

  // FLUX.2 klein 4B: much more realistic than FLUX.1 schnell, still about 190 free pictures a day at this size.
  const form = new FormData();
  form.append("prompt", `${title}, ${STYLE}`);
  form.append("width", "768");
  form.append("height", "512");
  const body = new Response(form);
  const { image } = await env.AI.run("@cf/black-forest-labs/flux-2-klein-4b", {
    multipart: { body: body.body, contentType: body.headers.get("content-type") },
  });
  const bytes = Uint8Array.from(atob(image), (c) => c.charCodeAt(0));
  await env.PHOTOS.put(title, bytes);
  return new Response(bytes, { headers });
}

async function scan(request, env) {
  const photo = new Uint8Array(await request.arrayBuffer());
  if (photo.length === 0 || photo.length > 15_000_000) return new Response("Bad photo", { status: 400 });
  const hints = new URL(request.url).searchParams.get("hints")?.slice(0, 1000);
  let base64 = "";
  for (let i = 0; i < photo.length; i += 0x8000) base64 += String.fromCharCode(...photo.subarray(i, i + 0x8000));

  const text = await gemini(env, {
        contents: [{ parts: [
          { text: hints ? `${SCAN_PROMPT} This user has corrected past scans: ${hints}.` : SCAN_PROMPT },
          { inline_data: { mime_type: "image/jpeg", data: btoa(base64) } },
        ] }],
        generationConfig: {
          responseMimeType: "application/json",
          responseSchema: {
            type: "OBJECT",
            properties: { items: { type: "ARRAY", items: {
              type: "OBJECT",
              properties: { name: { type: "STRING" }, count: { type: "INTEGER" } },
              required: ["name", "count"],
            } } },
            required: ["items"],
          },
        },
      }, 2_500, 8_000);
  return new Response(text, { headers: { "content-type": "application/json" } });
}

const RECIPE_RULES = "You are a home cook writing recipes for a cookbook. Use only the ingredients the user lists, " +
  "plus basic staples: salt, pepper, oil, and water. Never add other ingredients. Name each ingredient exactly as " +
  "it appears in the user's list. Give an amount for every ingredient, for 2 servings, in the same order. " +
  "Write 5 to 8 steps a beginner can follow without guessing: how to cut things, the heat level, how many " +
  "minutes, and what it should look, smell or feel like when it's done.";

async function recipes(request, env) {
  const { ingredients, maxMinutes, excluding } = await request.json();
  if (!Array.isArray(ingredients) || ingredients.length === 0) return new Response("Missing ingredients", { status: 400 });
  const list = (items, n) => items.slice(0, n).map((item) => String(item).slice(0, 60)).join(", ");
  let rules = "";
  if (Number.isInteger(maxMinutes)) rules += ` It must take at most ${maxMinutes} minutes in total.`;
  if (Array.isArray(excluding) && excluding.length) rules += ` Don't suggest any of these: ${list(excluding.slice(-40), 40)}.`;
  // Three short requests at once are about 3x faster than one long one; each gets its own kind of dish so
  // the three don't repeat each other.
  const kinds = ["a breakfast or brunch dish", "a quick lunch or snack", "a dinner main course"];
  const results = await Promise.allSettled(kinds.map((kind) => oneRecipe(env,
    `My ingredients: ${list(ingredients, 80)}. Suggest 1 recipe: ${kind}.${rules}`)));
  const found = results.filter((r) => r.status === "fulfilled").map((r) => r.value);
  if (found.length === 0) throw results[0].reason;
  return Response.json({ recipes: found });
}

async function oneRecipe(env, prompt) {
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
        },
        required: ["title", "minutes", "difficulty", "ingredients", "amounts", "steps"],
      },
    },
  }, 3_000, 12_000);
  return JSON.parse(text);
}

// Flash-Lite answers fast. When Google is overloaded it can hang, so if it hasn't answered in `hedge` ms
// Flash is asked too, and whichever answers first wins. Each call gives up after `timeout` ms.
async function gemini(env, request, hedge, timeout) {
  const body = JSON.stringify(request);
  const ask = async (model) => {
    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
      { method: "POST", body, signal: AbortSignal.timeout(timeout),
        headers: { "content-type": "application/json", "x-goog-api-key": env.GEMINI_KEY } });
    if (!response.ok) throw new Error(`${model} ${response.status}: ${(await response.text()).slice(0, 300)}`);
    return (await response.json()).candidates[0].content.parts[0].text;
  };
  let done = false;
  const lite = ask("gemini-flash-lite-latest").finally(() => { done = true; });
  const backup = new Promise((resolve) => setTimeout(resolve, hedge))
    .then(() => (done ? lite : ask("gemini-flash-latest")));
  try {
    return await Promise.any([lite, backup]);
  } catch (error) {
    throw new Error(error.errors.map(String).join(" | "));
  }
}
