# App Store Connect listing

Everything to paste into App Store Connect for Pantry 1.0. Character limits are Apple's; every field here fits. Fields marked "you fill" need your own details.

## App Information

| Field | Value |
|---|---|
| Name (30) | Pantry: Fridge to Recipes |
| Subtitle (30) | Scan your fridge, cook dinner |
| Primary category | Food & Drink |
| Secondary category | Lifestyle |
| Bundle ID | com.bendoan.iOSApp |
| SKU | pantry-ios-1 |
| Content rights | Yes, it contains third-party content, and you have the rights to use it. Recipe photos come from Pixabay, whose license allows use in apps without attribution. |

If the name is taken, try "Pantry Chef: Fridge Recipes" or "Fridge to Fork: Pantry Recipes".

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

> Take a photo of your fridge and Pantry lists what's in it. Then get three recipes that use what you have, with a photo and step-by-step instructions.

**Description (4000)**

> Pantry finds recipes you can make with what's already in your kitchen.
>
> Take a photo of your fridge, pantry or groceries and Pantry lists the ingredients it sees, with counts like 6 eggs or 1 L of milk. Check the list, fix anything it got wrong, and add it all with one tap. Pantry remembers your fixes for next time. You can also type ingredients in.
>
> Tap Find recipes and Pantry writes three recipes that use only what you have, plus salt, pepper, oil and water. Pick 15 minutes, 30 minutes, an hour or any time. Each recipe has a photo of the dish, the amount of every ingredient for 2 servings, and 5 to 8 steps that tell you the heat, the time and what it looks like when it's done. Tap More recipes for three more.
>
> Start cooking opens one step at a time in large text, so you can follow along at the stove. Tap the heart to save a recipe to Favorites.
>
> With Siri, say "Add to my pantry in Pantry" or "What can I cook with Pantry".
>
> Your pantry and favorites stay on your iPhone. Pantry has no accounts, no ads and no tracking. Photos you scan go to an AI service to read them, and Pantry asks before your first scan. Without a connection, Pantry uses Apple Intelligence on iPhones that support it, plus a built-in recipe book.

**Keywords (100).** Commas, no spaces. The name and subtitle words are already searchable, so they aren't repeated.

> ingredient,meal,leftover,food,grocery,kitchen,idea,cooking,healthy,quick,easy,supper,lunch,breakfast

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
