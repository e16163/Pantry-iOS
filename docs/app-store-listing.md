# App Store Connect listing

Everything to paste into App Store Connect for Pantry 1.0. Character limits are Apple's; every field here fits. Fields marked "you fill" need your own details.

## App Information

| Field | Value |
|---|---|
| Name (30) | Pantry: AI for Recipes |
| Subtitle (30) | Fridge scanner & meal ideas |
| Primary category | Food & Drink |
| Secondary category | Lifestyle |
| Bundle ID | com.bendoan.iOSApp |
| SKU | pantry-ios-1 |
| Content rights | Yes, it contains third-party content, and you have the rights to use it. Recipe photos come from Pixabay, whose license allows use in apps without attribution. |

Apple searches the name most, so it carries the main search terms: AI, recipe, photo. The subtitle adds new ones (fridge, scanner, meal, idea) instead of repeating the name. If the name is taken, try "Pantry: AI Fridge Recipes" or "Pantry AI: Photo to Recipe".

## Pricing and availability

- Price: Free.
- Availability: all countries, unless Google's free Gemini terms rule out the EU, UK and Switzerland. Check that before you pick countries.
- Remove China mainland. China requires AI apps to use a model registered with its Cyberspace Administration (CAC) and to enter its filing number. Gemini and Groq aren't registered there, and Gemini isn't offered in China. With China mainland removed, answer "No" to "Does your app offer AIGC services in China mainland?"

## Age rating

Answer "None" or "No" to every question. Pantry has no violence, mature themes, gambling, contests, unrestricted web access, user-generated content, messaging or purchases. The result is 4+.

## App Privacy

Privacy policy URL: https://pantry.supersaladstinger.workers.dev/privacy

Data collection: "Yes, we collect data from this app." Then pick these two types, with the same answers for each:

| Data type | Used for | Linked to the user | Used for tracking |
|---|---|---|---|
| Photos or Videos | App Functionality | No | No |
| Other User Content (the ingredient list) | App Functionality | No | No |

Both count as collected because Pantry's server passes them to Google Gemini or Groq, and Google's free tier may keep them. Nothing else counts. Pantry has no accounts, analytics, ads or tracking, and the server doesn't store IP addresses.

## Version 1.0

**Promotional text (170).** Apple doesn't use this for search, so it carries no keywords. It's the first text under the screenshots and you can change it any time without a new build, so it's written to get the download.

> Snap your fridge and AI writes 3 recipes from what you already have, each with a real photo and a step-by-step cooking mode. Free, with no account and no ads.

**Description (4000)**

> Take a photo of your fridge and get recipes for what's in it.
>
> Pantry uses AI to read your photo and list the ingredients it sees, with counts like 6 eggs or 1 L of milk. Then AI writes three recipes that use only what you have, each with a photo of the dish and steps you can follow. It's for the moment you open the fridge and don't know what to make.
>
> HOW IT WORKS
>
> 1. Take a photo of your fridge, pantry, counter or grocery bags.
> 2. Check the list. Fix anything the AI got wrong and Pantry remembers it for next time.
> 3. Tap Find recipes. Pick 15 minutes, 30 minutes, an hour or any time.
> 4. Open a recipe and tap Start cooking.
>
> WHAT YOU GET
>
> AI fridge scanner. Snap a photo instead of typing a list. Pantry reads labels on jars, cartons and cans, so it knows skim milk from oat milk.
>
> AI recipe generator. Every recipe uses only your ingredients plus salt, pepper, oil and water, so you don't need to shop. Each one has amounts for 2 servings and 5 to 8 steps that say the heat, the time and what it looks like when it's done. Tap More recipes for three new ones.
>
> A real photo of every dish. Each recipe shows a stock photo of the finished dish, not an AI drawing.
>
> Cooking mode. One step per screen in large text, so you can follow along at the stove.
>
> Favorites. Tap the heart to keep a recipe.
>
> Siri. Say "Add to my pantry in Pantry" or "What can I cook with Pantry".
>
> PRIVACY
>
> Your pantry and favorites stay on your iPhone. No accounts, no ads, no tracking. Pantry asks before your first scan, then sends each photo to an AI service to read it and doesn't keep it. Without a connection, Pantry uses Apple Intelligence on iPhones that support it, plus a built-in recipe book.

**Keywords (100).** Commas, no spaces, singular words. Apple combines these with the name and subtitle, so "generator" here plus "AI recipe" in the name matches a search for "ai recipe generator". Words already in the name or subtitle aren't repeated. "Food" is here even though the category is Food & Drink, because it's not clear how much Apple counts the category name, and "ai food" and "food generator" are the searches that matter most. "AI" sits in the name, so the keywords add the words people pair with it: assistant, generator, scan. "Photo" moved here from the old name.

> generator,ingredient,cook,dinner,leftover,picture,camera,snap,scan,photo,assistant,food,easy,planner

**Support URL:** https://github.com/e16163/Pantry-iOS/issues

**Marketing URL:** leave empty.

**Copyright:** 2026 (you fill: your name or team name)

**What's New:** not shown for a first version.

## App Review Information

- Sign-in required: No.
- Contact name, phone and email: you fill.

**Notes for the reviewer.** This answers Apple's Guideline 2.1 "Information Needed" request point by point. Attach the screen recording in the Attachment box under App Review Information.

> 1. SCREEN RECORDING
> Attached. Recorded on a physical iPhone running the latest iOS. It starts at launch from the Home Screen and shows the full flow: sample pantry, scanning a photo, editing the ingredient list, finding recipes, a recipe's detail, cooking mode, and favorites. Pantry has no accounts, no login, no user-generated content shared with other users, and no paid content or in-app purchases.
>
> 2. PURPOSE AND AUDIENCE
> Pantry is for home cooks who open the fridge and don't know what to make. You take a photo of your fridge or pantry, AI lists the ingredients, and then AI writes three recipes that use only what you already have. It saves a trip to the store and cuts food waste. Each recipe has amounts, a photo of the dish, step-by-step instructions, and a cooking mode with one large step per screen.
>
> 3. HOW TO USE IT
> No login, credentials or sample files are needed.
> - Quick test: on the Pantry tab, tap "Try a sample pantry". Go to the Suggest tab and tap Find recipes. Recipes take about 3 seconds. Tap a recipe, then Start cooking. Tap the heart to save it to the Favorites tab.
> - Scanning: on the Pantry tab, tap the camera button and take or choose a photo of food. The first scan asks permission to send the photo to an AI service. You can edit or delete any ingredient it finds.
> - Siri: "Add to my pantry in Pantry" and "What can I cook with Pantry".
>
> 4. EXTERNAL SERVICES
> - Cloudflare Workers: our own server, which forwards requests to the AI services. It doesn't store photos or IP addresses.
> - Google Gemini API: reads ingredient photos and writes recipes.
> - Groq API: backup AI service for the same two jobs when Gemini is unavailable.
> - Pixabay API: licensed stock photos of each finished dish. Pixabay's license allows use in apps without attribution.
> - Apple Intelligence (Foundation Models), on supported iPhones, writes recipes on-device when there's no connection. A built-in recipe book is the last fallback.
> Pantry uses no authentication, payment, analytics, advertising or tracking services.
>
> 5. REGIONAL DIFFERENCES
> Pantry works the same in every region where it's offered. It is not offered in China mainland, because the AI services it uses aren't registered there.
>
> 6. REGULATED INDUSTRY OR THIRD-PARTY MATERIAL
> Pantry isn't in a regulated industry. The only third-party material is the Pixabay stock photos, used under the Pixabay Content License. Recipes are general cooking instructions, not medical or nutrition advice.

## Export compliance

Pantry uses only standard HTTPS, so it qualifies for the exemption. The project sets ITSAppUsesNonExemptEncryption to NO, so App Store Connect won't ask about it on each upload.

## Screenshots

The iPhone 6.9" set is required: 1320 x 2868 pixels, 3 to 10 screenshots. iPad screenshots are needed only if the app stays on iPad. A storyboard to approve:

Captions use the words people search for. Some ASO tools report that Apple reads screenshot text for search since June 2025. Apple hasn't confirmed it, but clear captions help downloads either way.

1. "AI fridge scanner. Snap a photo, get your ingredients." The scan result list.
2. "Photo to recipe in seconds." Three recipe cards with photos.
3. "Recipes from what you already have." A recipe's ingredients and steps.
4. "Step-by-step cooking mode." Cooking mode.
5. "Save your favorite recipes." The Favorites tab.
