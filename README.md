# Fridge-to-Recipe

An iOS app that recommends recipes from ingredients you already have. Type your ingredients in (or snap a photo of your fridge), and get meals you can make without buying anything. Built for the F26 iOS Bootcamp.

**Stack:** Swift, SwiftUI, SwiftData, Foundation Models (on-device AI), PhotosUI, Vision + Core ML. No accounts, no paid APIs.

- 📋 **Task board:** https://github.com/users/e16163/projects/3
- 🗺️ **Plan & decisions:** [PLAN.md](PLAN.md)

## Requirements

| | |
|---|---|
| Xcode | 27.2 or later (the project file was created with 27.2) |
| iOS | 26.0 or later |
| AI recipes | An Apple Intelligence device (iPhone 15 Pro or newer) with Apple Intelligence turned on. **Test recipe generation on a real iPhone:** the iOS 27 simulator on a macOS 26 Mac reports the model as available but every request fails. |

## Getting started

1. Clone the repo and open `iOS App.xcodeproj`.
2. Pick an iPhone simulator and press **⌘R**.
3. Run the unit tests with **⌘U**. They live in `iOS AppTests/` and use Swift Testing.

**Running on your own iPhone:** select the **iOS App** target → **Signing & Capabilities** → choose your **Team** (your personal Apple ID works). Xcode handles the rest. Don't commit signing changes unless the team agrees on one setup.

## Project structure

```
iOS App/
├── MyApp.swift        App entry point
├── RootView.swift     Tab bar: Pantry · Suggest · Saved
└── Features/
    ├── Pantry/        Ingredient list, manual add, photo → review
    ├── Suggest/       Filters, recipe cards, recipe detail
    └── Saved/         Saved recipes
```

More folders (`Models/`, `AI/`, `Resources/`, `Features/Cook/`) get added as their cards land. See the architecture section in [PLAN.md](PLAN.md#architecture).

## How we work

There are no fixed roles: anyone takes any card. Full rules are in [PLAN.md → How we work](PLAN.md#how-we-work). The short version:

1. On the [board](https://github.com/users/e16163/projects/3), take the highest-priority **Todo** card whose "Depends on" cards are done.
2. **Assign yourself** and move it to **In Progress**.
3. Create a branch, do the work, and open a PR. Move the card to **In Review**.
4. A teammate reviews within 24 hours. Merging the PR closes the card.

### Branch names

`<type>/<issue#>-<short-name>`, for example `feature/59-manual-entry`.

| Type | Use for |
|---|---|
| `feature/` | App features |
| `fix/` | Bug fixes |
| `spike/` | Time-boxed experiments (may never merge) |
| `chore/` | Setup, tooling, docs |

### Pull requests

- Keep them small (under ~300 lines).
- Put `Closes #N` in the description so the card closes when it merges.
- Include screenshots for UI changes and steps to test.
- Make sure it builds before asking for review.
