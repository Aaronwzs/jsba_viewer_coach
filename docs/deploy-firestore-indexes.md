Deploy Firestore Indexes (GitHub Actions)

This repository includes a workflow that deploys `firestore.indexes.json` to a Firebase project.

Setup

1. Create a CI service account and generate a token:
   - Install firebase-tools locally: `npm install -g firebase-tools`
   - Login and generate a token: `firebase login:ci` (this prints a token you can copy)

2. In your GitHub repository, add the following secrets:
   - `FIREBASE_TOKEN` — the token from `firebase login:ci`
   - `FIREBASE_PROJECT` — the Firebase project id (e.g. `juniorshuttlers-stag`)

Usage

- Manually: Go to the Actions tab -> Deploy Firestore Indexes -> Run workflow. Select branch `main`.
- Automatically: The workflow runs on pushes to `main`.

Notes

- The workflow runs `firebase deploy --only firestore:indexes --project $FIREBASE_PROJECT`.
- Make sure the token corresponds to an account with permission to deploy Firestore indexes.
