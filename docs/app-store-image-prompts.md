# Pantry App Store image prompts

These prompts are for ChatGPT (or any image model that takes text prompts). They make six App Store screenshots and one header, in the same style as Uber Eats' App Store listing, in Pantry's colors.

## How to use this file

1. Open a new ChatGPT chat.
2. Paste the **Style rules** section as your first message, and send it.
3. For each image, **attach its screenshot from `docs/screenshots/`** (the heading says which one), paste the prompt, and send. Image 2 and the header have no screenshot.
4. Check the phone screen against your real screenshot. ChatGPT sometimes changes words or photos in it. If it did, reply: "Put my screenshot back on the phone exactly as I attached it. Don't change anything in it."
5. If ChatGPT keeps changing the screenshot, send the prompt without attaching it. You'll get a magenta screen, and you place the real screenshot over it in Canva or Figma.
6. If an image drifts from the others, reply: "Same style as image 1. Fix: <what's wrong>."
7. Check every headline for spelling.
8. Export each screenshot at exactly 1320 x 2868 PNG, and the header at 3840 x 2160.

Apple rejects screenshots that show app screens the app doesn't have, so the phone must show your real screen, not one the AI drew.

---

## Style rules

Paste this whole section first.

```
I'm making App Store screenshots for my iPhone app "Pantry". It's an AI recipe app: you take a photo of your fridge, AI lists the ingredients, then it writes recipes from what you have.

I'll send you 7 image prompts, one at a time. Make every image follow these rules exactly, so all 7 look like one matching set.

STYLE: bold, clean food-delivery app marketing, like a big food delivery brand's App Store screenshots. Flat, confident, lots of breathing room. Not cartoon, not 3D render, not glossy, not AI-art looking.

BACKGROUND: one flat solid green, hex #4CC27A, filling the whole image. No gradient, no texture, no pattern, no vignette, no shadows on the background.

HEADLINE TYPE: very bold geometric sans-serif, like Plus Jakarta Sans ExtraBold or Uber Move Bold. Pure black #000000. Tight letter spacing. Large: the main word is about 14% of the image height. Left-aligned for the first two images, centered for the rest. Spell every word exactly as I write it, with no extra words.

DIVIDER: on images that have one, a thin solid black horizontal line, about 0.4% of the image height thick, running the full width of the image from the left edge to the right edge, with a solid white circle (no outline, no shadow) centered on the line. Inside the circle is one small flat-color icon, simple and friendly, in black, deep green #006E32 and one accent color.

PHONE: a modern iPhone with thin, even black bezels and a Dynamic Island, shown straight-on and perfectly flat unless I say it's tilted. When I attach a screenshot, put that exact screenshot on the phone screen, filling it edge to edge. Do not redraw, restyle, translate, crop out or change anything in it: every word, photo, icon and color must stay exactly as in my screenshot. It is a real screen from my app. If I don't attach one, fill the screen with solid flat magenta #FF00FF.

FOOD: real, photorealistic food, cut out cleanly like stickers, with no drop shadow and no background around it. Bright natural studio light, rich color, sharp focus, natural imperfections (crumbs, oil sheen, herb flecks), shot like a Canon 5D with a 100mm macro lens. Food items are cropped by the image edges and overlap the phone frame, so they feel like they're bursting into the scene. Use 1 or 2 food items per image unless I say otherwise.

NEVER INCLUDE: people, hands, logos, brand names, watermarks, extra text, UI elements outside the phone, emoji, sparkles, glows, gradients, lens flares, plates floating with shadows, or cartoon food.

SIZE: portrait, 1320 x 2868 pixels (about 9:19.5), unless I say otherwise.

Reply "Ready" and wait for my first prompt.
```

---

## Image 1. Snap (uses `1-pantry.png`)

```
Image 1 of 7. Portrait 1320x2868. I attached 1-pantry.png: put it on the phone screen exactly as it is.

Top 24%: the headline, left-aligned with a left margin of 6% of the width, in two lines:
Line 1, very large: "Snap your fridge."
Line 2, about 40% of line 1's size, same black, bold: "AI fridge scanner"

No divider line or circle on this image.

The phone: large, tilted 12 degrees clockwise, its top-left corner bleeding off the left edge of the image, filling the lower 76% of the height. My attached screenshot on the screen, unchanged.

Food: half an avocado with the pit in, cut face toward the viewer, cropped by the bottom-left corner and overlapping the phone's bottom edge. A brown egg and a lemon floating near the top-right, partly cropped by the right edge.
```

## Image 2. Hero collage, no phone

```
Image 2 of 7. Portrait 1320x2868.

Top 26%: the headline, left-aligned with a left margin of 6% of the width, three lines, all the same very large size:
"DINNER FROM"
"WHAT YOU'VE"
"GOT."

No phone, no divider line, no circle.

Below the headline, a floating collage of photorealistic cut-out food, each item at a slightly different angle, with generous green space between them:
- Center, the largest item: a plate of tomato bruschetta seen from a 45-degree angle, four slices of toasted bread topped with diced red tomato and fresh basil.
- Top right: two brown eggs.
- Middle left, cropped by the left edge: a bunch of fresh spinach.
- Lower right, cropped by the right edge: a wedge of aged cheddar.
- Bottom center, cropped by the bottom edge: a head of garlic and a curl of fresh pasta.
- Scattered: three cherry tomatoes on the vine.
```

## Image 3. Recipes (uses `2-recipes.png`)

```
Image 3 of 7. Portrait 1320x2868. I attached 2-recipes.png: put it on the phone screen exactly as it is.

Top 13%: the headline "Recipes", centered, very large.
Just under it, centered, about 30% of the headline size, bold black: "Photo to recipe in seconds"

At 21% from the top: the divider. The full-width thin black line, with a white circle centered on it. Icon in the circle: a flat camera with a small spark above it.

The phone: upright, centered, front view, its top edge at 26% from the top and its bottom cropped by the bottom edge of the image. My attached screenshot on the screen, unchanged.

Food: a slice of lasagna cropped by the right edge at mid-height, overlapping the phone's right side. A bowl of fried rice with egg cropped by the bottom-left corner.
```

## Image 4. Recipe detail (uses `3-recipe.png`)

```
Image 4 of 7. Portrait 1320x2868. I attached 3-recipe.png: put it on the phone screen exactly as it is.

Top 13%: the headline "Cook what you have", centered, very large (shrink it to fit on one line, or two lines if needed).
Just under it, centered, about 30% of the headline size, bold black: "Recipes from your ingredients"

At 21% from the top: the divider. The full-width thin black line, with a white circle centered on it. Icon in the circle: a flat checklist with green ticks.

The phone: upright, centered, front view, its top edge at 26% from the top and its bottom cropped by the bottom edge of the image. My attached screenshot on the screen, unchanged.

Food: three cherry tomatoes on the vine cropped by the left edge near the top of the phone. A sprig of fresh basil and a halved garlic bulb cropped by the bottom-right corner, overlapping the phone.
```

## Image 5. Cook (uses `4-cooking.png`)

```
Image 5 of 7. Portrait 1320x2868. I attached 4-cooking.png: put it on the phone screen exactly as it is.

Top 13%: the headline "Cook", centered, very large.
Just under it, centered, about 30% of the headline size, bold black: "Step-by-step cooking mode"

At 21% from the top: the divider. The full-width thin black line, with a white circle centered on it. Icon in the circle: a flat frying pan with a fried egg in it.

The phone: upright, centered, front view, its top edge at 26% from the top and its bottom cropped by the bottom edge of the image. My attached screenshot on the screen, unchanged.

Food: a sunny-side-up egg cropped by the left edge near the top of the phone. Below the middle of the phone, large and overlapping its lower half: a twirl of garlic butter pasta on a fork, cropped by the right edge, with a sprig of rosemary.
```

## Image 6. Save (uses `5-favorites.png`)

```
Image 6 of 7. Portrait 1320x2868. I attached 5-favorites.png: put it on the phone screen exactly as it is.

Top 13%: the headline "Save", centered, very large.
Just under it, centered, about 30% of the headline size, bold black: "Your favorite recipes"

At 21% from the top: the divider. The full-width thin black line, with a white circle centered on it. Icon in the circle: a flat red heart.

The phone: upright, centered, front view, its top edge at 26% from the top and its bottom cropped by the bottom edge of the image. My attached screenshot on the screen, unchanged.

Food: a slice of strawberry cheesecake cropped by the right edge near the top of the phone. A taco with fresh salsa cropped by the bottom-left corner, overlapping the phone.
```

## Image 7. Header

```
Image 7 of 7. This one is LANDSCAPE, 3840x2160 (16:9), not portrait.

Same flat green #4CC27A background, same photorealistic cut-out food style. No phone, no divider, no circle.

Left 45% of the image: completely empty green, with no food and no text. I'll put the app name there.

Right 55%: a loose, airy collage of cut-out ingredients at slight angles, cropped by the top, right and bottom edges: a plate of tomato bruschetta (the largest item, center of the right half), a curl of fresh pasta, half an avocado, two brown eggs, cherry tomatoes on the vine, a lemon, and a few basil leaves.

Keep anything important away from all four edges by at least 10%, because the App Store crops this image differently on iPhone, iPad and Mac.

No text anywhere in this image.
```

---

## Which screenshot goes where

| Order | Image | Real screenshot to place | Headline |
|---|---|---|---|
| 1 | Image 1 | `1-pantry.png` | Snap your fridge. / AI fridge scanner |
| 2 | Image 2 | none | Dinner from what you've got. |
| 3 | Image 3 | `2-recipes.png` | Recipes / Photo to recipe in seconds |
| 4 | Image 4 | `3-recipe.png` | Cook what you have / Recipes from your ingredients |
| 5 | Image 5 | `4-cooking.png` | Cook / Step-by-step cooking mode |
| 6 | Image 6 | `5-favorites.png` | Save / Your favorite recipes |
| Header | Image 7 | none | none |

The first three are what people see in search results, so keep them in this order.

## Where the style comes from

From Uber Eats' six App Store screenshots (US listing, checked November 24, 2026):

- **Background.** One flat brand green, with no gradient.
- **Headline.** One large word in black, in a heavy geometric sans-serif: Browse, Order, Track, Enjoy.
- **Divider.** A thin black line across the full width, under the word, with a white circle and a small icon on it.
- **Phone.** A real app screen in a plain black iPhone, standing straight, in the lower two thirds.
- **Food.** Real food photos cut out like stickers (pizza, watermelon, cake, poke bowl), cropped by the edges and overlapping the phone. One or two per screenshot.
- **First two screenshots.** These are bolder. One has a tilted phone with food bursting in, and one is a food collage with no phone under a big headline.

Pantry uses its own green, #4CC27A, from the app's accent color in dark mode, and its own words. No Uber Eats names, logos, fonts or photos are copied.
