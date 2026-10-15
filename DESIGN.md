# Cuan Mobile — Design Direction
> Per anti-ai-slop-ui skill process. This document is written BEFORE any UI code.

## 1. Classification
Mobile app screens — personal finance companion (native mobile, portrait, thumb-first).

## 2. Product Context
- **Product**: Cuan mobile — personal finance tracker for Indonesian users.
- **Target user**: Indonesian individuals managing daily money (same as web).
- **Primary actions**: (1) glance at balance, (2) chat with AI to log spending — the signature "super power", (3) check budgets.
- **Trust requirement**: HIGH — this is their money.
- **Emotional tone**: calm, intimate, premium. Like a private banker, not a game.
- **Constraint from user**: UI/UX must be DIFFERENT from the website.

## 3. Visual Direction: "Midnight Ledger"
A dark-first, chat-centric private-banking aesthetic. Deliberately NOT the web's
light editorial dashboard (light bg, sidebar nav, KPI card grid).

- **Mood**: precise, sober, high-trust, intimate. Quiet confidence after dark.
- **Palette**:
  - Base: deep green-black `#0B0F0E` (never pure black, never purple/indigo)
  - Surface: `#141A17` cards on base; borders `white 8%`
  - Text: warm paper-white `#F2F5F3`; muted `#8A938E`
  - Accent (single, restrained): brand teal `#5EEAD4` — reserved for the AI
    assistant and primary actions only
  - Semantic: income `#4ADE80`, expense `#F87171`
- **Typography**:
  - Display: serif (Georgia/system serif) — ONLY for the balance hero. This is
    the distinctive editorial signature, shared with web but used differently.
  - UI: system sans. Numerals: tabular, tightly set.
  - No Inter/Geist-as-default thinking; system fonts are a deliberate native choice.
- **Radius**: 20px cards, 28px bottom sheets, pill inputs. Not "rounded on everything" —
  list rows are flush, sheets are the roundest element.
- **Icon style**: Lucide-style outline icons (via `lucide_icons` package), 1.75 stroke.

## 4. Layout Strategy (mobile-native, not a shrunk dashboard)
- **Bottom navigation** (5 tabs): Home, Activity, **Assistant (center, raised)**,
  Budgets, Accounts. The Assistant is the centerpiece — the "super power".
- **Home = "one big object"**: balance hero (serif, animated count) → AI prompt
  bar ("Ceritakan pengeluaranmu…", tappable → Assistant) → month in/out strip →
  recent activity list. NO KPI card grid (that's the web's pattern).
- **Sheets, not dialogs**: all creation flows (add transaction, add budget) use
  native bottom sheets.
- **Assistant tab**: full chat UI — suggestion chips, streaming replies, transaction
  result cards inline.

## 5. Motion Rules (functional only)
- Balance count-up on load (communicates "computed live").
- Chat message streaming (communicates "AI is working").
- Bottom-sheet slide (native platform convention).
- No scroll reveals, no gradient text animation, no decorative blobs.
- Respect `prefers-reduced-motion` via Flutter's accessibility (disable animations
  when needed).

## 6. Anti-Slop Check (pre-build)
- [x] Not a default shadcn/Material demo? Yes — custom dark theme, custom nav.
- [x] Purple/indigo accent? No — teal, product-justified (brand).
- [x] Gradient hero text? No — solid serif.
- [x] Hero + 3 cards + CTA? No — chat-centric home.
- [x] Emoji as icons? No — Lucide outlines.
- [x] Glassmorphism everywhere? No — solid surfaces.
- [x] Bento grid? No.
- [x] Identical cards, equal weight? Home has clear hierarchy (hero → AI → list).

## 7. API Contract (backend: https://cuan-core.akudong85.workers.dev)
- Auth: `POST /auth/api/sign-in/email` { email, password } → cookie session.
  Flutter: `dio` + `cookie_jar` persistent cookies.
- `GET /api/accounts` → accounts list + balances.
- `GET /api/transactions?limit=` → recent transactions.
- `GET /api/dashboard/stats` (or summary) → month income/expense.
- `GET /api/budgets?month=YYYY-MM` → budgets + progress.
- `GET /api/categories` → categories.
- `POST /api/chat/` { message, locale: "id", history: [], timezone } → AI reply.
- `POST /api/transactions` → create transaction.
