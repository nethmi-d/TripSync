# TripSync Image Service

Cloudflare Worker that securely manages Cloudinary assets. Firebase ID tokens
identify the caller, while Cloudinary credentials remain in Worker secrets.

## Profile-photo behavior

- Uploads overwrite `tripsync/users/{uid}/profile/avatar`.
- Edits do not create abandoned profile-photo assets.
- Account deletion calls the Worker before deleting Firestore/Auth data.

## Local setup

1. Copy `.dev.vars.example` to `.dev.vars`.
2. Add the Cloudinary cloud name, API key, and API secret.
3. Run `npm install`.
4. Run `npm run dev`.

Use the local URL in Flutter:

```powershell
flutter run --dart-define=IMAGE_SERVICE_URL=http://10.0.2.2:8787
```

`10.0.2.2` lets an Android emulator access the host machine.

## Deploy

Authenticate Wrangler, then store secrets:

```powershell
npx wrangler secret put CLOUDINARY_CLOUD_NAME
npx wrangler secret put CLOUDINARY_API_KEY
npx wrangler secret put CLOUDINARY_API_SECRET
npm run deploy
```

Run Flutter using the resulting `workers.dev` URL:

```powershell
flutter run --dart-define=IMAGE_SERVICE_URL=https://your-worker.workers.dev
```

Never commit `.dev.vars`, Cloudinary API secrets, or Wrangler authentication
files.
