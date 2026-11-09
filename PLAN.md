# Fridge-to-Recipe App: Project Plan

An iOS app that recommends recipes from ingredients you already have. Type ingredients in or snap a photo of your fridge, and get meals you can make without buying anything.

**Stack:** Swift, SwiftUI, PhotosUI, Foundation Models, SwiftData, Vision + Core ML. No auth, no paid APIs.

**Board:** https://github.com/users/e16163/projects/3. It's the source of truth for tasks; this file holds the plan and decisions.

_Last updated Nov 9. Week 1 went into planning, so the build is compressed into Nov 10–23._

## Decisions

| # | Decision | Status |
|---|---|---|
| 1 | Demo is ~Nov 23; feature freeze Fri Nov 21 | ✅ |
| 2 | Demo device: e16163's Apple Intelligence iPhone | ✅ |
| 3 | No fixed roles: pull-based Kanban (see [How we work](#how-we-work)) | ✅ |
| 4 | Minimum iOS 26.0 (Foundation Models' first release) | ✅ Done |
| 5 | Recipes come from Foundation Models; bundled `fallback_recipes.json` when the model is unavailable | ✅ |
| 6 | Keep full scope except stretch goals (expiration dates, expiring-first, dietary prefs, cook timers): closed, reopen if ahead | ✅ |
| 7 | Photo detection: pre-trained **YOLOv8 (Open Images V7) Core ML model** + **Vision text recognition** for packaging labels. Final call in #53 after spikes; hard cutoff **Nov 18** | 🟡 Pending spikes |
| 8 | Is ambervermaa on the team? (repo invite pending, not on the project) | 🟡 Open |

Mentor feedback (Nov 9): prioritize manual entry and recipe recommendations; fridge scanning is a bonus. The plan follows this: manual entry is the guaranteed path, and photo detection always goes through a review sheet.

## Timeline

| Date | Checkpoint |
|---|---|
| **Tue Nov 11** | App runs on a phone with 3 tabs; AI test returns recipes |
| **Sat Nov 15** | ⭐ **Core loop works on device:** type ingredients → generate → open → save. This alone is a passable demo. |
| **Tue Nov 18** | **Photo cutoff:** if detection isn't reliable, demo with manual entry only |
| **Fri Nov 21** | **Feature freeze:** bug fixes only |
| **~Nov 23** | Demo |

### Week 2 (Nov 10–16): Foundation + core loop
- [ ] Setup: deployment target ✅, `.gitignore`, folder structure, tab shell
- [ ] Spikes: Foundation Models recipe generation; YOLO vs Vision detection → decision
- [ ] SwiftData models; pantry list + manual entry with autocomplete
- [ ] `RecipeGenerator`, pantry-only validation, normalization, fallback recipes, availability check
- [ ] Suggest screen, recipe cards, detail view, Saved tab
- [ ] Camera / PhotosPicker capture
- → verify: on device, type ingredients → recipes → save works end to end

### Week 3 (Nov 17–23): Photo, polish, demo
- [ ] IngredientDetector + review sheet (cutoff Nov 18)
- [ ] Streaming results, cook mode
- [ ] Empty/loading/error states, accessibility, app icon, visual polish
- [ ] Unit tests, bug bash, freeze, demo build, rehearsal, backup video

## How we work

1. **Pull, don't wait.** Take the highest-priority card in **Todo** (P0 → P1 → P2) whose "Depends on" cards are Done.
2. **Assign yourself** and move it to **In Progress**. The **My Cards** view shows yours.
3. **Max 2 cards In Progress per person.**
4. **Unblockers first.** Critical path:
   `#46/#47/#48 setup → #56 models → #54 AI spike → #62 RecipeGenerator → #68 Suggest`
   `#58 pantry list → #59 manual entry` · `#69 card → #70 detail → #71 Saved`
5. **Avoid collisions:** check In Progress; comment on the card if you'll touch the same screen as someone else.
6. **Feature PRs:** small (<300 lines), `Closes #N` in the body, one teammate reviews within 24 h, card → **In Review**.
7. **Merge to `main` at least daily.**
8. **Daily check-in** in the team channel: done / next / blocked.

## Architecture

```
iOS App/
├── Models/            SwiftData: PantryItem, SavedRecipe
├── AI/                RecipeGenerator (LanguageModelSession + @Generable types)
│                      IngredientDetector (YOLO Core ML + Vision text recognition)
├── Features/
│   ├── Pantry/        list, manual add, photo → review
│   ├── Suggest/       filters, recipe cards, detail
│   ├── Cook/          step-by-step mode
│   └── Saved/
└── Resources/         fallback_recipes.json (~30 recipes), ingredients.json
```

**Data**
- `PantryItem`: name, category, addedAt
- `SavedRecipe`: title, minutes, difficulty, ingredients [String], steps [String], savedAt
- `@Generable struct RecipeSuggestion`: title, summary, minutes, difficulty, ingredientsUsed, steps

**Prompting rule:** "Use only these ingredients, plus pantry staples (salt, pepper, oil, water)." After generation, check in code that each recipe's `ingredientsUsed` is a subset of the pantry, and drop or flag recipes that aren't.

**Fallback:** If `SystemLanguageModel.default.availability` isn't available, match the pantry against `fallback_recipes.json` by ingredient overlap.

**Photo detection:** run a pre-trained YOLOv8 model (Open Images V7, about 600 classes including many foods), exported to Core ML (`yolo export model=yolov8n-oiv7.pt format=coreml nms=True`), through Vision. Add `RecognizeTextRequest` to read packaging labels ("MILK", "salsa"). Map labels to ingredient names, normalize them, and always show the review sheet.

**Screens:** 3 tabs.
- **Pantry:** list, + manual add, camera/photo button → review sheet
- **Suggest:** time filter (≤15 / 30 / 60 min) → Generate → streaming recipe cards → detail → Save / Start Cooking
- **Saved:** saved recipes → detail

**Cook mode:** one step per page, large text, the screen stays awake (`isIdleTimerDisabled`).

## Risks

| Risk | Mitigation |
|---|---|
| Photo detection is poor | Review sheet; manual entry is the primary path; Nov 18 cutoff |
| Model invents ingredients | Pantry-only validation |
| Model unavailable on a device | Fallback recipes + availability check |
| Slow generation | Streaming; 3 recipes per request |
| Lost Week 1 | Core loop checkpoint Sat Nov 15; stretch goals cut |

## Demo script (2 min)
1. Take a photo of the fridge and fix one wrong item on the review screen (or type ingredients if photo was cut).
2. Set the filter to ≤30 min and generate.
3. Open a recipe, save it, then start cook mode.
4. Show the Saved tab.
