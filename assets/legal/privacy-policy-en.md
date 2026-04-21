# Privacy Policy — Recall

**Last updated: 2026-04-21**
**Contact: ruiruiclips@gmail.com**

Recall ("the App") respects and protects the privacy of every user. This policy explains how we collect, use, store, and protect your personal data.

## 1. Data Collection

### 1.1 Guest Mode (No Login)
- **No personally identifiable information is collected.**
- All study sets, review records, and settings are stored on your device in an encrypted Hive database.
- No data is uploaded to any server.

### 1.2 Authenticated Mode (Optional)
We use Supabase for cloud sync. If you choose to sign in, we collect:
- **Account data**: email, hashed password (or OAuth provider ID)
- **Study content**: study sets, cards, review progress, review logs
- **Timestamps**: created/updated for sync conflict resolution

## 2. Third-Party Services

| Service | Purpose | Scope |
|---------|---------|-------|
| Supabase | Authentication + cloud sync | Login mode only |
| Google Gemini API | Photo-to-flashcard AI (optional) | User-provided API key; images sent directly to Google; we do not retain them |
| Groq Cloud | Photo-to-flashcard AI (optional) | User-provided API key; images sent directly to Groq; we do not retain them |
| Unsplash | Card image search (optional) | Only the search query |

**Important: AI API keys are stored exclusively on your device (FlutterSecureStorage). They are never uploaded to our servers.**

## 3. Device Permissions

| Permission | Purpose | Required |
|------------|---------|----------|
| Camera | Photo-to-flashcard | No (optional feature) |
| Photo library | Pick image from gallery | No |
| Notifications | Daily review reminder | No (user can disable) |
| Biometrics | Quick unlock | No |
| Network | Cloud sync, AI recognition | Yes (for those features) |

## 4. Data Retention

- **Guest mode**: Data lives on your device indefinitely until you delete it.
- **Authenticated mode**: Data lives in Supabase until you delete your account.

## 5. Your Rights

At any time you can:
- **Export data**: Settings → Account & Security → Export JSON backup.
- **Delete account**: Settings → Account & Security → Delete Account — removes all cloud data immediately.
- **Disable sync**: Sign out to stop cloud sync; local data is preserved.

## 6. Youth Protection

The App is primarily intended for high-school students. We:
- Do not ask for real names, addresses, or phone numbers.
- Do not collect precise location data.
- Do not display advertising.
- Recommend that users under 13 obtain parental consent before use.

## 7. Data Security

- Local: Hive + AES encryption (keys managed by FlutterSecureStorage).
- In transit: HTTPS/TLS 1.2+.
- Passwords: hashed with bcrypt by Supabase; never stored in plaintext.

## 8. Policy Changes

Material changes will be announced in-app.

## 9. Contact

Questions? Email ruiruiclips@gmail.com.
