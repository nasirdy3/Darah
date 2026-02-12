# Darah (Dara) — Flutter Android (Offline)

This is a production-ready Flutter project for the Nigerian/African strategy board game **Darah/Dara**.

## Build on phone (Cloud build) — GitHub Actions
1. Create a GitHub repo (e.g. `darah-android`).
2. Upload this entire folder.
3. Open **Actions** tab → run workflow **Build Android APK**.
4. Download the artifact `darah-release-apk` → install `app-release.apk` on your Android phone.

## Rules implemented
- Placement: cannot create 3-in-a-row.
- Movement: orthogonal step only.
- Dara: exact 3-in-row → capture one opponent seed.
- 4+ in a row is illegal.
- Multiple Daras from one move are **allowed**.
- Win: opponent has < 3 seeds OR no legal moves.

## Settings
- Board size: 5×5 or 6×6
- VS AI toggle
- AI level (1–100)
- Choose player colors