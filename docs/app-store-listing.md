# App Store Connect listing

Everything to paste into App Store Connect for Pantry 1.0. Character limits are Apple's; every field here fits. Fields marked "you fill" need your own details.

## App Information

| Field | Value |
|---|---|
| Name (30) | Pantry: AI Recipes From Photo |
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

**Promotional text (170).** You can change this any time without a new build.

> Point your camera at your fridge. AI finds the ingredients and writes recipes you can cook tonight, each with a photo of the dish and step-by-step instructions.

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

**Keywords (100).** Commas, no spaces, singular words. Apple combines these with the name and subtitle, so "generator" here plus "AI recipe" in the name matches a search for "ai recipe generator". Words already in the name or subtitle aren't repeated.

> generator,ingredient,food,cook,dinner,leftover,picture,camera,snap,chef,kitchen,dish,healthy,quick

**Support URL:** https://github.com/e16163/Pantry-iOS/issues

**Marketing URL:** leave empty.

**Copyright:** 2026 (you fill: your name or team name)

**What's New:** not shown for a first version.

## App Review Information

- Sign-in required: No.
- Contact name, phone and email: you fill.

**Notes for the reviewer**

> No account is needed.
>
> To try Pantry quickly, tap "Try a sample pantry" on the Pantry tab, then go to Suggest and tap Find recipes. Recipes take about 3 seconds.
>
> To scan, tap the camera button on the Pantry tab and take or choose a photo of food. The first scan asks permission to send the photo to an AI service (Google Gemini or Groq) through our server. Pantry doesn't store the photo.
>
> Recipe photos are licensed stock photos from Pixabay. Siri phrases: "Add to my pantry in Pantry" and "What can I cook with Pantry".

## Export compliance

Pantry uses only standard HTTPS, so it qualifies for the exemption. The project sets ITSAppUsesNonExemptEncryption to NO, so App Store Connect won't ask about it on each upload.

## Screenshots

The iPhone 6.9" set is required: 1320 x 2868 pixels, 3 to 10 screenshots. iPad screenshots are needed only if the app stays on iPad. A storyboard to approve:

1. "Scan your fridge." The scan result list.
2. "Get dinner from what you have." Three recipe cards with photos.
3. "Every step, start to finish." A recipe's ingredients and steps.
4. "Cook one step at a time." Cooking mode.
5. "Save your favorites." The Favorites tab.
