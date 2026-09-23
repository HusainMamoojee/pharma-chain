# Manufacturer Dashboard (Website)

This is the manufacturer-facing website — separate from the Flutter mobile app.
Built with Flask, HTML, CSS and JavaScript (no PHP), as agreed with Hussain.

## Run it locally

```bash
python -m venv venv
source venv/bin/activate      # on Windows: venv\Scripts\activate
pip install -r requirements.txt
python app.py
```

Then open http://127.0.0.1:5000

## Connecting to real Firestore

Right now the app runs in **demo mode** (in-memory data, no persistence)
because there's no Firebase service account key yet. To connect it to the
same Firestore database as the mobile app:

1. Firebase Console → Project Settings → Service Accounts → **Generate new private key**
2. Save the downloaded file as `serviceAccountKey.json` in this folder
   (it's already in `.gitignore` — never commit it)
3. Restart the app — it will detect the key automatically and switch out of demo mode

## Structure

```
manufacturer_website/
├── app.py                  # Flask routes + Firestore/demo data logic
├── templates/               # Jinja HTML templates
│   ├── base.html            # sidebar layout, loads style.css + script.js
│   ├── dashboard.html
│   ├── register.html
│   ├── products.html
│   └── product_detail.html
├── static/
│   ├── css/style.css        # all styling, one file per Kayla's request
│   ├── js/script.js         # all JS, one file per Kayla's request
│   └── qrcodes/             # generated QR code images
└── requirements.txt
```

## What's implemented (Deliverable 4 evidence)

- Product registration form (FR3) → saves to Firestore `medicines` collection
- Unique medicine ID + QR code generation (FR4)
- Product list + detail view showing the generated QR code
- Demo-mode fallback so the UI works before Firebase credentials exist

## Not yet implemented

- Firebase Authentication / login for manufacturers (currently open access)
- Editing/deleting a registered product
- Supply-chain event creation from this side (currently mobile-app-only per the design)

Don't claim these as done in the report until they're actually built and tested.
