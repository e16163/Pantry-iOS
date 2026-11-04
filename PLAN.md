# Fridge-to-Recipe App: 3-Week Plan

An iOS app that recommends recipes from ingredients you already have. Snap a photo of your fridge or type ingredients in, and get meals you can make without buying anything.

**Stack:** Swift, SwiftUI, PhotosUI, Foundation Models, SwiftData, Vision (possibly). No auth, no paid APIs.

## Before you start: two decisions

1. **Lower the deployment target to iOS 26.0.** The Foundation Models framework has been around since iOS 26. At 27.2, only phones on the newest iOS can run the demo build.
2. **Treat photo recognition as the riskiest feature and test it in the first two days.** Options, best first:
   - **A.** If the Foundation Models version on your OS takes image input, use it. Check this on a real device.
   - **B.** Use Vision's `ClassifyImageRequest`. It runs on every device and knows many food labels, but it guesses whole-image labels and doesn't find each item.
   - **C.** Use manual entry only, with fast autocomplete. This one must work no matter what.

   Whichever you pick, **detected items always go to a review screen** where the user can confirm, edit or delete them.

Foundation Models only runs on Apple Intelligence devices (iPhone 15 Pro or newer, with Apple Intelligence turned on). Check `SystemLanguageModel.default.availability` and use the fallback below.

## Architecture

```
iOS App/
├── Models/            SwiftData: PantryItem, SavedRecipe
├── AI/                RecipeGenerator (LanguageModelSession + @Generable types)
│                      IngredientDetector (whatever the spike picks)
├── Features/
│   ├── Pantry/        list, manual add, photo → review
│   ├── Suggest/       filters, recipe cards, detail
│   ├── Cook/          step-by-step mode
│   └── Saved/
└── Resources/         fallback_recipes.json (~30 recipes)
```

**Data**
- `PantryItem`: name, category, addedAt, expiresAt? (stretch)
- `SavedRecipe`: title, minutes, difficulty, ingredients [String], steps [String], savedAt
- `@Generable struct RecipeSuggestion`: title, summary, minutes, difficulty, ingredientsUsed, steps

**Prompting rule:** "Use only these ingredients, plus pantry staples (salt, pepper, oil, water)." After generation, check in code that each recipe's `ingredientsUsed` is a subset of the pantry, and drop or flag recipes that aren't.

**Fallback:** If the model is unavailable, match the pantry against `fallback_recipes.json` by ingredient overlap.

**Screens:** 3 tabs.
- **Pantry:** list, + manual add, camera/photo button → review sheet
- **Suggest:** time filter (≤15 / 30 / 60 min) → Generate → streaming recipe cards → detail → Save / Start Cooking
- **Saved:** saved recipes → detail

**Cook mode:** one step per page, large text, the screen stays awake (`isIdleTimerDisabled`).

## Timeline

### Week 1 (Nov 3–9): Foundation + spikes
- [ ] Set the deployment target, folder structure, tab shell → verify: builds on device
- [ ] Photo spike (A vs B) on real hardware with 5 real fridge photos → verify: write down the results and decide
- [ ] Foundation Models spike: hard-coded ingredients → `[RecipeSuggestion]` → verify: 3 valid recipes in under 10 seconds
- [ ] SwiftData models and Pantry CRUD with manual entry → verify: items survive an app relaunch

### Week 2 (Nov 10–16): Core loop
- [ ] `RecipeGenerator` with the time filter, streaming, and the subset check
- [ ] Recipe cards and detail view, plus save/unsave
- [ ] Photo → detect → review → add to pantry
- [ ] Model-unavailable fallback with the bundled JSON
- → verify: on device, photo → pantry → recipes → save works end to end

### Week 3 (Nov 17–23): Finish + demo
- [ ] Cook mode
- [ ] Empty, loading and error states; accessibility pass (Dynamic Type, VoiceOver labels)
- [ ] Visual polish: recipe card design, app icon
- [ ] Stretch: expiration dates, then "use soon" items placed first in the prompt
- [ ] **Feature freeze 2 days before the demo**, bug bash, rehearse the demo script

## GitHub Projects setup
- Columns: Backlog → This Week → In Progress → Review → Done
- One issue per checkbox above, with labels `feature`, `spike`, `bug`, `stretch` and a milestone per week
- Small PRs into `main`, with one teammate reviewing each

## Risks

| Risk | Mitigation |
|---|---|
| Photo detection is poor | Review screen; manual entry stays the main path |
| Demo phone lacks Apple Intelligence | Confirm the demo device in week 1; bundled-recipe fallback |
| Model makes up ingredients | Subset check plus prompt rules |
| Slow generation | Stream results; ask for 3 recipes, not 10 |
| Scope creep | Expiration tracking stays stretch-only until week 3 |

## Demo script (2 min)
1. Take a photo of the fridge and fix one wrong item on the review screen.
2. Set the filter to ≤30 min and generate.
3. Open a recipe, save it, then start cook mode.
4. Show the Saved tab.

## Open questions
- Team size and how to split the work (e.g. Pantry/photo, AI/recipes, UI/cook mode)
- Exact demo date (sets the freeze date)
- Who has an Apple Intelligence-capable iPhone for testing?
