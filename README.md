# TOUCHLINE — The Road to Glory

A premium, portrait-first football management career game by **ForgeFrame Studio**.

## Play

Open `index.html` in a modern browser, or deploy the repository with **GitHub Pages** (Settings → Pages → Deploy from a branch → `main` / root). On a phone, use portrait orientation and optionally add the website to your home screen.

No build tools, dependencies, API keys, or backend are required. Career progress is saved using browser localStorage, so use the same browser and device to continue. Clearing site data will erase the career.

## Playable v0.1

- Take fictional **Northbridge FC** from the bottom division toward the top flight.
- Complete 14-match league seasons against seven clubs.
- Promotion for top-two finishes; relegation for the bottom two where applicable.
- Manage transfers: buy, sell, and scout fictional players. Transfer spending affects club finances and wage bills.
- Choose from 4-3-3, 4-4-2, and 3-5-2, plus mentality and pressing.
- Tactical ratings, player quality, morale, and fitness influence match outcomes.
- Invest in stadium expansion for greater matchday revenue.
- Improve the academy for youth development and scouting.
- Improve training facilities and change development focus.
- Collect results, prize income, league standings and club news.
- Autosave career progression locally.

## Design direction

Dark navy and emerald, warm gold accents, premium editorial typography, portrait touch navigation, no external image dependencies.

## Important v0.1 scope

This is a **playable prototype**, not a complete commercial release. Match action is currently presented as a result and event timeline, not animated 2D player movement. Teams and player names are fictional; there are no licensed clubs, logos, or databases. Transfers are direct purchases and sales without negotiations, contracts, or competing bidders yet.

## Development roadmap

1. More believable scouting and negotiating: bid/ask prices, counteroffers, player preferences, release clauses, contracts and free agents.
2. Squad depth, lineup editing, player roles, injuries and substitutions.
3. Expanded league pyramid, promotion playoffs, cup competitions and richer multi-season AI club logic.
4. Financial progression: board expectations, sponsorship, recurring wages and stadium attendance modelling.
5. Academy intake, staff recruitment, youth potential, morale, training schedules and club identity.
6. A richer 2D match engine with highlights, shots, possession, substitutions and in-game tactical changes.
7. Offline-capable PWA packaging, accessibility and Android APK builds.

## Repository

`index.html` contains the self-contained HTML, CSS and JavaScript game. The main loop uses deterministic pseudo-random seeds within match calculations and saves to localStorage.

© ForgeFrame Studio.