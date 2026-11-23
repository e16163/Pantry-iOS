// Pantry's free backend on Cloudflare Workers.
//   GET  /photo?title=Garlic%20Butter%20Steak  -> an AI-made JPEG of that dish (or its saved Pixabay photo), kept in KV
//   POST /scan?hints=... (JPEG body; hints are the user's past fixes) -> {"items":[{"name":"egg","count":6}]}
//   POST /recipes {"ingredients":["egg"],"maxMinutes":30,"excluding":["Omelette"]} -> {"recipes":[...3 recipes]}
// Deploy: npx wrangler deploy (from this folder)

// Plain, real-photo wording: words like "moody" or "saturated" make it look AI-made.
const STYLE = "real photo taken with a DSLR for a food delivery app menu, as actually served at a good " +
  "restaurant, 45 degree angle, natural daylight, true-to-life colors, real textures, crumbs and " +
  "imperfections, simple plate on a wooden table, no text, no hands";

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
  const title = url.searchParams.get("title") ?? "";
  if (!title.trim()) return new Response("Missing title", { status: 400 });
  const headers = { "content-type": "image/jpeg", "cache-control": "public, max-age=31536000, immutable" };
  return new Response(await dishPhoto(env, title), { headers });
}

// A real stock photo of the dish, found with the photo search the recipe AI wrote ("spinach omelette"), else with
// the title. When no photo is tagged with the dish, a picture is made from the title (capped at 3 s).
async function dishPhoto(env, rawTitle, query) {
  const title = rawTitle.trim().toLowerCase().replace(/\s+/g, " ").slice(0, 120);
  const known = await env.PHOTOS.get(`dish:${title}`, "arrayBuffer");
  if (known) return known;
  const stock = env.PIXABAY_KEY && await stockPhoto(env, title, query).catch(() => null);
  if (stock) return stock;
  const saved = await env.PHOTOS.get(`made:${title}`, "arrayBuffer");
  if (saved) return saved;
  try {
    return await Promise.race([madePhoto(env, title),
      new Promise((_, reject) => setTimeout(reject, 3_000, new Error("picture took over 3 s")))]);
  } catch (error) {
    // Free pictures used up for the day: the closest stock photo beats a blank card.
    const close = env.PIXABAY_KEY && await stockPhoto(env, title, query, true).catch(() => null);
    if (!close) throw error;
    return close;
  }
}

// The best-matching Pixabay photo no other dish has, in about a second: searches "garlic butter steak", then
// "butter steak", then "steak". Pixabay asks that photos be copied to our own server, so they're kept in KV.
const PROTEINS = ["shrimp", "prawn", "chicken", "beef", "pork", "bacon", "ham", "sausage", "salmon", "tuna", "fish",
  "meat", "lamb", "turkey", "crab", "lobster", "steak", "mussels", "squid"];
const RAW = ["raw", "plant", "garden", "growing", "grow", "harvest", "field", "seedling", "agriculture", "market",
  "ingredient", "uncooked", "isolated", "dough", "farm", "organic"];
const DISHES = ["soup", "stew", "chili", "salad", "taco", "burrito", "bowl", "pasta", "noodle", "spaghetti", "curry",
  "sandwich", "toast", "pizza", "burger", "smoothie", "pancake", "waffle", "omelette", "omelet", "rice", "cake", "pie",
  "wrap", "quesadilla", "fry", "hash", "skewer", "kebab", "dumpling", "roll", "risotto", "casserole", "frittata",
  "scramble", "bake", "gratin", "lasagna", "salmon", "steak", "bruschetta", "muffin", "porridge", "oatmeal"];
// Photos being saved by this server right now, so two dishes at once don't both take the same one.
const taking = new Set();
const SERVED = ["dish", "plate", "meal", "dinner", "lunch", "breakfast", "served", "cuisine", "delicious", "tasty"];

async function stockPhoto(env, title, query, anyDish = false) {
  // Words that describe the cooking, not the dish, only confuse a photo search.
  const filler = /^(quick|easy|simple|homemade|classic|best|cheesy|creamy|spicy|crispy|savory|fresh|hearty|light|healthy|veggie|loaded|one|pan|skillet|style|with|and|&|on|the|a|of|in)$/;
  const words = String(query || title).toLowerCase().split(/[^a-z]+/).filter((word) => word && !filler.test(word));
  // The dish goes last ("pasta mushroom" searches as "mushroom pasta"), since searches drop words from the front.
  const dish = words.findLast((word) => DISHES.includes(word.replace(/e?s$/, "")));
  if (dish) words.push(...words.splice(words.indexOf(dish), 1));
  const searches = await Promise.all(words.slice(0, 3).map((_, i) =>
    fetch(`https://pixabay.com/api/?key=${env.PIXABAY_KEY}&image_type=photo&category=food` +
      `&orientation=horizontal&safesearch=true&per_page=20&q=${encodeURIComponent(words.slice(i).join(" "))}`,
      { headers: { "user-agent": "PantryApp/1.0 (recipe photos)" } })
      .then((response) => (response.ok ? response.json() : {})).then((json) => json.hits ?? [], () => [])));
  // Only photos tagged with the dish itself (the last word: "quesadilla", not "beef" or "cheese"), most specific
  // search first, each once; among those, more matching words go first (a stable sort keeps search order).
  const tagged = (hit, word) => hit.tags.toLowerCase().includes(word.replace(/e?s$/, ""));
  // More of the search words, then tags that say it's a served meal.
  const score = (hit) => words.filter((word) => tagged(hit, word)).length + (SERVED.some((word) => tagged(hit, word)) ? 0.5 : 0);
  const hits = [...new Map(searches.flat().map((hit) => [hit.id, hit])).values()]
    .filter((hit) => anyDish || tagged(hit, words.at(-1)))
    // A photo with meat or seafood the dish doesn't have is a different dish: shrimp pasta isn't spinach pasta.
    .filter((hit) => !PROTEINS.some((meat) => tagged(hit, meat) && !title.includes(meat.replace(/e?s$/, ""))))
    // Growing plants and raw ingredients aren't a cooked dish.
    .filter((hit) => !RAW.some((word) => tagged(hit, word)))
    .sort((a, b) => score(b) - score(a));
  // Each photo goes to one dish only, so similar titles don't share a picture.
  const used = await Promise.all(hits.map((hit) => env.PHOTOS.get(`claimed:${hit.id}`)));
  const free = hits.filter((hit, j) => !used[j]).slice(0, 10);
  const choice = anyDish ? 0 : await pickByTags(env, title, free);
  if (choice < 0) return null;
  // Taken here at once, with no wait in between, so dishes looked up at the same moment can't pick the same one.
  const pick = [free[choice], ...free].find((hit) => hit && !taking.has(hit.id));
  if (!pick) return null;
  taking.add(pick.id);
  const image = await fetch(pick.largeImageURL);
  // Pixabay answers "Rate limit exceeded" as text when busy; that must never be saved as the dish's photo.
  if (!image.ok || !image.headers.get("content-type")?.startsWith("image/")) return null;
  const bytes = await image.arrayBuffer();
  await Promise.all([env.PHOTOS.put(`dish:${title}`, bytes), env.PHOTOS.put(`claimed:${pick.id}`, title)]);
  return bytes;
}

// Tags show what my filters miss: "raclette" or "sea urchin" next to "pasta" or "salmon". Groq reads each photo's
// tags and picks the one showing exactly this dish as served, -1 for none, in about half a second. If it's slow
// or down, the best-ranked photo (0) is used.
async function pickByTags(env, title, hits) {
  if (hits.length === 0) return -1;
  if (!env.GROQ_KEY) return 0;
  try {
    const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
      method: "POST",
      signal: AbortSignal.timeout(1_500),
      headers: { "content-type": "application/json", authorization: `Bearer ${env.GROQ_KEY}` },
      body: JSON.stringify({
        model: "openai/gpt-oss-20b",  // its own free limits, so picking photos never slows recipe writing
        reasoning_effort: "low",
        messages: [{ role: "user", content: `A recipe is called "${title}". These stock photos are described by ` +
          `their tags:\n${hits.map((hit, i) => `${i}: ${hit.tags}`).join("\n")}\nWhich one most likely shows ` +
          "exactly this finished dish, cooked and served? Tags naming a different dish (a burger for a sandwich, " +
          "raclette for pasta), meat or seafood the recipe doesn't have, or raw ingredients rule a photo out. " +
          "Answer -1 if none fits." }],
        response_format: { type: "json_schema", json_schema: { name: "pick", strict: true, schema: {
          type: "object", properties: { photo: { type: "integer" } }, required: ["photo"], additionalProperties: false } } },
      }),
    });
    if (!response.ok) return 0;
    const { photo } = JSON.parse((await response.json()).choices[0].message.content);
    return photo >= 0 && photo < hits.length ? photo : -1;
  } catch {
    return 0;
  }
}

// FLUX.1 schnell: about 1.5 s a picture, where FLUX.2 klein looked a little more real but took 5 s or more.
async function madePhoto(env, title) {
  const make = () => env.AI.run("@cf/black-forest-labs/flux-1-schnell", { prompt: `${title}, ${STYLE}`, steps: 4 });
  // Now and then one waits 10 s in Cloudflare's queue, so a second try starts at 1.5 s and the first one back wins.
  const first = make();
  const second = new Promise((resolve) => { setTimeout(resolve, 1_500); first.catch(resolve); }).then(make);
  const { image } = await Promise.any([first, second]).catch((error) => { throw new Error(error.errors.map(String).join(" | ")); });
  const bytes = Uint8Array.fromBase64(image);  // native decode; a JS loop ran past the free plan's CPU limit
  await env.PHOTOS.put(`made:${title}`, bytes);
  return bytes;
}

async function scan(request, env) {
  const photo = new Uint8Array(await request.arrayBuffer());
  if (photo.length === 0 || photo.length > 15_000_000) return new Response("Bad photo", { status: 400 });
  const hints = new URL(request.url).searchParams.get("hints")?.slice(0, 1000);
  let base64 = "";
  for (let i = 0; i < photo.length; i += 0x8000) base64 += String.fromCharCode(...photo.subarray(i, i + 0x8000));

  const prompt = hints ? `${SCAN_PROMPT} This user has corrected past scans: ${hints}.` : SCAN_PROMPT;
  const image = btoa(base64);
  let text;
  try {
    text = await readTwice(env, {
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
      });
  } catch (error) {
    if (!env.GROQ_KEY || new URL(request.url).searchParams.has("gemini")) throw error;
    text = await groqScan(env, prompt, image);  // Gemini's free quota ran out or Google is down
  }
  return new Response(text, { headers: { "content-type": "application/json" } });
}

// Flash-Lite sometimes stops after the first few things it sees, so two reads run at once and their lists are
// merged. They use two Flash-Lite versions, each with its own free quota and capacity, so one being busy
// doesn't sink the scan. The second gets 1.5 s more than the first, so a slow one doesn't hold up the scan.
async function readTwice(env, request) {
  const reads = ["gemini-flash-lite-latest", "gemini-3.5-flash-lite"]
    .map((model) => gemini(env, request, 2_500, 5_000, model).then((text) => JSON.parse(text).items));
  const first = await Promise.any(reads).catch((error) => { throw new Error(error.errors.map(String).join(" | ")); });
  const both = await Promise.race([Promise.allSettled(reads), new Promise((resolve) => setTimeout(resolve, 1_500))]);
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

async function recipes(request, env) {
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
    .then(async (recipe) => { await dishPhoto(env, recipe.title, recipe.photo).catch(() => {}); return recipe; })));
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
async function gemini(env, request, hedge, timeout, model = "gemini-flash-lite-latest") {
  const body = JSON.stringify(request);
  const ask = async (model) => {
    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
      { method: "POST", body, signal: AbortSignal.timeout(timeout),
        headers: { "content-type": "application/json", "x-goog-api-key": env.GEMINI_KEY } });
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
    // Google's "high demand" 503s come and go, so one more try goes to a newer Flash-Lite with its own capacity.
    await new Promise((resolve) => setTimeout(resolve, 1_000));
    try {
      return await ask("gemini-3.5-flash-lite");
    } catch (retry) {
      throw new Error([...error.errors, retry].map(String).join(" | "));
    }
  }
}

