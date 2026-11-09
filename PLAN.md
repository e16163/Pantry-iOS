# Fridge-to-Recipe App: Project Plan

An iOS app that recommends recipes from ingredients you already have. Type ingredients in or snap a photo of your fridge, and get meals you can make without buying anything.

**Stack:** Swift, SwiftUI, SwiftData, Foundation Models, PhotosUI, Vision. **Architecture: MVVM.** No auth, no paid APIs.

**Board:** https://github.com/users/e16163/projects/3. It's the source of truth for tasks; this file holds the plan and decisions.

_Last updated Nov 9: restructured into MVVM build-up layers._

## How we build: layers

We build the app **up in layers**. First the simplest version of the whole flow (the skeleton), then each layer makes it better. **After every layer, and every merged PR, the app works and can be demoed.** If time runs out, we cut the top layers, not half-built features.

| Layer | Dates | Goal | Cards |
|---|---|---|---|
| **L0 Foundation** | Nov 3–9 | Project setup, data models, ingredients list | #46–49, #55, #56, #57 |
| **L1 Skeleton** | Nov 9–10 | Bare-bones end-to-end flow: type ingredients → generate → open → save → Saved tab | #95, #54 |
| **L2 Core features** | Nov 10–14 | Make each screen real: autocomplete, category grouping, time filter, pantry-only validation, design, recipe cards | #58–61, #64, #67–71 |
| **L3 Reliability** | Nov 14–16 | Works everywhere and never feels broken: fallback recipes, error handling, streaming, empty states, unit tests | #62, #63, #65, #66, #75, #77 |
| **L4 Photo input** | Nov 16–18 | Fridge photo → detected ingredients → review sheet. **Hard cutoff Nov 18** | #51–53, #72–74 |
| **L5 Cook mode & polish** | Nov 18–20 | Step-by-step cook mode, accessibility, icon, visual polish | #76, #78–80 |
| **L6 Ship** | Nov 21–23 | Bug bash, freeze (Nov 21), demo build, rehearsal | #85–88, #50 |

**Rules for layers**
- Only the **current layer** is in **Todo**. The next one moves from Backlog when the current one is nearly done.
- Within a layer, take cards whose "Depends on" are Done, P0 first.
- A card **adds to what exists**. It never rebuilds a screen from scratch.

## Architecture: MVVM

```
iOS App/
├── MyApp.swift                 Creates the ModelContainer
├── RootView.swift              Creates one ViewModel per tab; TabView
├── Models/                     MODEL: SwiftData @Model types, IngredientCatalog
├── Services/                   MODEL: RecipeGenerator (AI), later FallbackRecipes, IngredientDetector
├── Resources/                  ingredients.json, later fallback_recipes.json
└── Features/
    ├── Pantry/                 PantryView + PantryViewModel
    ├── Suggest/                SuggestView + SuggestViewModel
    ├── RecipeDetail/           RecipeDetailView + RecipeDetailViewModel
    ├── Saved/                  SavedView + SavedViewModel
    └── Cook/                   (L5) CookView + CookViewModel
```

| Layer | What goes there | Rules |
|---|---|---|
| **Model** | `@Model` types (`PantryItem`, `SavedRecipe`) and services (`RecipeGenerator`) | No SwiftUI. Services don't know about screens. |
| **ViewModel** | One `@Observable @MainActor final class` per screen | Owns the screen's state and actions. Talks to `ModelContext` and services. **No SwiftUI views.** |
| **View** | SwiftUI | Displays view-model state and calls view-model methods. **Never touches `ModelContext` or services directly.** |

**Conventions**
- View models receive the `ModelContext` in `init` and fetch with `FetchDescriptor`. We don't use `@Query`, because it puts data access in views.
- A view model that opens another screen creates that screen's view model (`detailViewModel(for:)`), so views never need the context.
- Mutating methods reload their list (`load()`) after inserting or deleting.
- **New feature = view model first, then view.** Logic in a view model can be unit-tested without the UI (#75).
- Every code card on the board has a **"Where it goes (MVVM)"** section naming the files it touches.

## Decisions

| # | Decision | Status |
|---|---|---|
| 1 | Demo is ~Nov 23; feature freeze Fri Nov 21 | ✅ |
| 2 | Demo device: e16163's Apple Intelligence iPhone | ✅ |
| 3 | No fixed roles: pull-based Kanban | ✅ |
| 4 | Minimum iOS 26.0 | ✅ Done |
| 5 | Recipes from Foundation Models; bundled fallback recipes when the model is unavailable | ✅ |
| 6 | Stretch goals (expiration, expiring-first, dietary, timers) cut; reopen if ahead | ✅ |
| 7 | **MVVM**, built up in layers starting from a skeleton | ✅ |
| 8 | Photo detection: Foundation Models image input on iOS 27+ (found in SDK, #51) vs YOLO/Vision; decide in #53; cutoff Nov 18 | 🟡 Needs a test on the demo iPhone |

**Spike results (#54):** recipe generation takes about 8 s for 3 recipes and sometimes invents ingredients (1 of 6 used chicken that wasn't in the pantry), so pantry-only validation (#64) is in L2.

Mentor feedback (Nov 9): prioritize manual entry and recipe recommendations; fridge scanning is a bonus. The layers follow this: photo input is L4, after the core works.

## How we work

1. Take the highest-priority **Todo** card whose "Depends on" cards are Done.
2. **Assign yourself**, move it to **In Progress**. The **My Cards** view shows yours. Max 2 in progress per person.
3. Branch `feature/<issue#>-short-name`, build it (view model first), open a PR with `Closes #N`, move the card to **In Review**.
4. One teammate reviews within 24 h. Merge to `main` at least daily.
5. Daily check-in in the team channel: done / next / blocked.

## Risks

| Risk | Mitigation |
|---|---|
| Model invents ingredients | Pantry-only validation (#64, L2) |
| Model unavailable on a device | Fallback recipes + availability check (L3) |
| Slow generation (~8 s) | Streaming (#63, L3) |
| Photo detection is poor | Review sheet; manual entry is primary; cutoff Nov 18 |
| Running out of time | Layers: every layer ships a working app, so we cut from the top |

## Demo script (2 min)
1. Add ingredients (photo with one fix on the review sheet, or typed if photo was cut).
2. Set the filter to ≤30 min and generate.
3. Open a recipe, save it, start cook mode.
4. Show the Saved tab.
