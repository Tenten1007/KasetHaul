# KasetHaul — Agricultural Freight Marketplace

A two-sided marketplace that matches farmers who need to move their harvest with truck owners who have spare capacity. Built for Mae Chaem district, Chiang Mai, where farmers currently find trucks by word of mouth — paying broker fees of 10–15% with no price transparency and no way to track their goods.

**Senior capstone project — still in development.**

<p align="left">
  <img src="https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-0175C2?logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/BLoC-02569B?logoColor=white" alt="BLoC">
  <img src="https://img.shields.io/badge/Cloud%20Firestore-FFCA28?logo=firebase&logoColor=black" alt="Cloud Firestore">
</p>

---

## What it does

| Feature | Detail |
|---|---|
| **Competitive bidding** | Clients post a job; contractors bid against each other. The client picks on price and rating — no broker sets the price. Platform fee is 3% (1.5% from each side). |
| **7-stage job tracking** | `waiting for contractor` → `assigned` → `arrived at pickup` → `goods collected` → `in transit` → `arrived at drop-off` → `delivered`, with proof attached at each handover. |
| **In-app wallet** | Funds are held when a job is assigned and released to the contractor only after delivery is confirmed. |
| **Identity verification** | Phone OTP for every user, plus Thai ID verification for contractors. |
| **Truck management** | Contractors register multiple trucks; the app checks whether a truck matches a job's requirements before allowing a bid. |
| **Two-way reviews** | Both sides rate each other after a job closes. |
| **Admin dashboard** | User review, truck approval, and platform reporting. |

Three user roles: **Client**, **Contractor**, **Administrator**.

---

## Tech

- **Flutter + Dart** — 47 screens, 177 Dart files
- **BLoC** for state management — every screen loads its state through a BLoC, never by calling a repository directly from the UI
- **Cloud Firestore** — 14 data models, with security rules in [`app/firestore.rules`](app/firestore.rules)
- **Firebase Auth** — phone OTP
- **Google Maps SDK** — pickup/drop-off selection and route display

## Structure

```
app/lib/
├── core/           config, theme, routing
├── models/         14 data models
├── features/       auth · job · wallet · truck · review · profile · notification
│   └── <feature>/
│       ├── bloc/   business logic
│       └── pages/  screens
└── shared/         reusable widgets
Mockup/             HTML mockups the UI was built from
```

## How it was designed

The system was specified before any code was written: a full SRS with **39 use case specifications**, use case diagrams, class diagrams, sequence diagrams and an ER diagram. Screens were mocked up in HTML first (see [`Mockup/`](Mockup/)) and then implemented to match.

The problem itself came from field research — the team interviewed farmers in Mae Chaem and collected data on real freight jobs before deciding what to build. That research was presented at **Startup Thailand League 2026** and **Research to Market (R2M) #14**, where the project represented Maejo University.

---

## Running it

```bash
cd app
flutter pub get
flutter run
```

Requires your own Firebase project and a Google Maps API key. Put the Maps key in `app/android/local.properties`:

```properties
MAPS_API_KEY=your_key_here
```

`build.gradle.kts` reads it from there and injects it into the manifest at build time, so the key never lands in version control.

---

## Status

In active development as a final-year project. The bidding, job tracking, wallet and review flows are implemented; some admin and reporting screens are still being built.

Built by [Thatchaphon Saengsonthaweesak](https://github.com/Tenten1007) — Information Technology, Maejo University.
