## Neon Arena – Esports Tournament Platform

Production-ready full-stack esports tournament platform inspired by Battlefy/Challengermode.

- **Frontend**: React, Vite, Tailwind CSS, Framer Motion, Axios, React Router
- **Backend**: Node.js, Express, MongoDB Atlas, Mongoose, JWT, bcrypt
- **Deployment**: Frontend on Vercel, backend on Render, database on MongoDB Atlas

### 1. Project structure

- `server/` – Express REST API (JWT auth, tournaments, wallet, admin)
- `client/` – React SPA with neon dark UI, player flows + admin panel

### One-click local run (Windows)

Double-click `RUN_NEON_ARENA.cmd`.

It will:

- install root + client + server dependencies (first run)
- create `server/.env` and `client/.env` from examples if missing
- start backend + frontend together

URLs:

- Frontend: `http://localhost:5173`
- Backend: `http://localhost:5000`

### 2. Backend (`server/`)

#### 2.1. Install & env

```bash
cd server
npm install
cp .env.example .env
```

Set in `.env`:

- **Core**
  - `NODE_ENV=development` (or `production` in Render)
  - `PORT=5000`
  - `API_BASE_PATH=/api`
- **CORS**
  - `CORS_ORIGINS=http://localhost:5173` (add your Vercel URL in production)
- **MongoDB Atlas**
  - `MONGODB_URI=` connection string from Atlas
- **JWT**
  - `JWT_ACCESS_SECRET=` long random string
  - `JWT_ACCESS_EXPIRES_IN=7d`
- **Admin seed**
  - `ADMIN_EMAIL=admin@arena.com`
  - `ADMIN_PASSWORD=ChangeThisAdminPassword123!`
  - `ADMIN_USERNAME=admin`

#### 2.2. Seed database

```bash
cd server
npm run seed
```

This will:

- Create an initial **admin user** (from `ADMIN_*` vars) with wallet + leaderboard entry
- Create **sample tournaments** for BGMI, Free Fire, Valorant, CS2

#### 2.3. Run backend locally

```bash
cd server
npm run dev
```

API runs on `http://localhost:5000` with:

- `GET /health` – health check
- `GET /api` – API metadata

Key routes (non-exhaustive):

- **Auth**
  - `POST /api/auth/register`
  - `POST /api/auth/login`
  - `GET /api/auth/me`
- **User**
  - `GET /api/user/profile`
  - `PATCH /api/user/profile`
  - `GET /api/user/history`
- **Wallet (mock payment)**
  - `GET /api/wallet/summary`
  - `GET /api/wallet/transactions`
  - `POST /api/wallet/deposit-mock`
  - `POST /api/wallet/withdraw`
- **Tournaments**
  - `GET /api/tournaments` (filters: game, type, status, search, min/max entry fee)
  - `GET /api/tournaments/:id`
  - `POST /api/tournaments/:id/join` (auth)
- **Matches / prize distribution (admin)**
  - `GET /api/matches/:tournamentId`
  - `POST /api/matches/:tournamentId/results`
  - `POST /api/matches/:tournamentId/declare-winners`
- **Notifications**
  - `GET /api/notifications`
  - `PATCH /api/notifications/:id/read`
- **Leaderboard**
  - `GET /api/leaderboard?limit=50`
- **Admin**
  - `GET /api/admin/analytics`
  - `GET /api/admin/users`
  - `PATCH /api/admin/users/:userId`
  - `POST /api/admin/tournaments`
  - `PATCH /api/admin/tournaments/:tournamentId`
  - `DELETE /api/admin/tournaments/:tournamentId`
  - `GET /api/admin/withdrawals?status=pending`
  - `POST /api/admin/withdrawals/:txId/approve`
  - `POST /api/admin/withdrawals/:txId/reject`
  - `POST /api/admin/broadcast`

Security:

- JWT Bearer tokens (`Authorization: Bearer <token>`)
- `requireAuth` middleware + `requireAdmin` for admin-only routes
- Banned users are blocked at auth middleware level

Wallet logic:

- `deposit-mock` increases wallet `balance` and creates an **approved** `deposit` transaction
- `withdraw`:
  - Creates **pending** `withdrawal` transaction
  - Moves amount into `wallet.locked` (reserved)
- Admin `approve`:
  - Decreases `balance` and `locked`
  - Marks transaction `approved`
  - Sends **withdrawal_approved** notification
- Admin `reject`:
  - Decreases `locked` only
  - Marks transaction `rejected`

Match / prize distribution:

- Admin uploads `placements` (place, userIds[], kills, points)
- Declaring winners:
  - Computes prize allocation using tournament `prizePool` and `prizeDistribution` (1st/2nd/3rd)
  - Credits winners’ wallets and creates `prize` transactions
  - Updates `User.stats` (matches, wins, kills, earnings)
  - Updates `LeaderboardEntry` (wins, kills, points)
  - Sends notifications to winners

### 3. Frontend (`client/`)

#### 3.1. Install & env

```bash
cd client
npm install
```

Create `client/.env`:

```bash
VITE_API_URL=http://localhost:5000/api
```

Later, on Vercel, set this to your Render backend URL, e.g.:

```bash
VITE_API_URL=https://your-render-service.onrender.com/api
```

#### 3.2. Run frontend locally

```bash
cd client
npm run dev
```

Open `http://localhost:5173`.

Pages:

- `/` – landing (hero, featured tournaments, games grid, community CTA)
- `/login` – login (JWT-based)
- `/register` – registration (with referral code)
- `/tournaments` – list + search + filters (game, type, status, fee)
- `/tournaments/:id` – tournament detail with countdown, lobby info, join flow
- `/wallet` – wallet summary + deposit mock + withdrawal request + history
- `/profile` – user profile, stats, gaming IDs JSON, tournament history
- `/leaderboard` – global ranking (wins/kills/points)
- `/notifications` – notifications (join, win, withdrawal approved, broadcast)
- `/admin` – admin dashboard (role-protected)

Auth:

- JWT stored in `localStorage` using `AuthProvider` and `useAuth`
- Axios (`src/lib/api.js`) injects `Authorization` header automatically

Admin dashboard (`/admin`):

- **Analytics tab**
  - Total users
  - Total revenue (sum of approved deposits)
  - Active tournaments (upcoming/live)
  - Pending withdrawal requests
- **Tournaments tab**
  - Create new tournaments (game, type, entry fee, prize pool, slots, start time)
  - See all tournaments and delete if needed
- **Withdrawals tab**
  - View pending withdrawal requests
  - Approve / reject (updates wallet + notifications)
- **Users tab**
  - List users with wins/kills/banned status
  - Ban / unban users
- **Broadcast tab**
  - Create global announcements (shown in Notifications page)

UI / UX:

- Dark, neon, glassmorphism aesthetic (`arena-bg`, `glass`, `btn-neon` in `src/index.css`)
- Framer Motion transitions on page enter and featured content
- Responsive, mobile-first layout
- Discord / WhatsApp CTAs on landing (href placeholders – wire to your actual links)

### 4. Deployment

#### 4.1. MongoDB Atlas

1. Create a **free cluster** in MongoDB Atlas.
2. Create a database user + password.
3. Get the connection string from Atlas, e.g.:

   `mongodb+srv://<user>:<password>@cluster0.xxxxx.mongodb.net/neon-arena`

4. Put this value into `server/.env` as `MONGODB_URI`.

#### 4.2. Backend on Render

1. Push this repo to GitHub.
2. In Render, create a new **Web Service**:
   - Connect the repo
   - Root directory: `server`
   - Runtime: Node 18+
   - Build command: `npm install`
   - Start command: `npm start`
3. In Render **Environment**:
   - Add all vars from `server/.env` (use secure values for production)
4. Deploy and note the Render URL, e.g.:

   `https://neon-arena-api.onrender.com`

5. Set `CORS_ORIGINS` to include your Vercel client URL.

#### 4.3. Frontend on Vercel

1. In Vercel, create new project from the same GitHub repo.
2. Root directory: `client`.
3. Build command: `npm run build`.
4. Output directory: `dist`.
5. Environment variable:

   - `VITE_API_URL=https://neon-arena-api.onrender.com/api`

6. Deploy – Vercel will host the SPA at e.g. `https://neon-arena.vercel.app`.

#### 4.4. Production notes

- Use **HTTPS** for both Vercel and Render.
- For JWT secrets, use long random strings stored ONLY in env.
- In MongoDB Atlas, restrict IP ranges if possible or use VPC peering.
- Optional: add rate limits per route group if traffic grows.

### 5. Local end-to-end test checklist

1. Start MongoDB Atlas and configure `MONGODB_URI`.
2. Backend:
   - `cd server && npm install`
   - Configure `.env`
   - `npm run seed`
   - `npm run dev`
3. Frontend:
   - `cd client && npm install`
   - Create `client/.env` with `VITE_API_URL=http://localhost:5000/api`
   - `npm run dev`
4. Flows to verify:
   - Register + login
   - View tournaments, join one (entry fee deducted)
   - Wallet deposit via Razorpay + withdrawal request
   - Admin login with seeded admin credentials
   - Admin approves withdrawal (wallet balance/locked update + notification)
   - Admin uploads match placements & declares winners (prizes + stats + leaderboard)
   - Leaderboard / notifications / profile stats update correctly

### 6. Razorpay setup (required for real deposits)

Add these to `server/.env` (Render environment variables in production):

- `RAZORPAY_KEY_ID`
- `RAZORPAY_KEY_SECRET`
- `RAZORPAY_WEBHOOK_SECRET`

Client does not need the key directly — it is returned from `POST /api/payments/create-order`.

API:

- `POST /api/payments/create-order` (auth) → returns `order.id` + `keyId`
- `POST /api/payments/verify-payment` (auth) → verifies signature and credits `wallet.depositBalance`
- `POST /api/payments/webhook` (no auth) → server-side confirmation (recommended in production)

