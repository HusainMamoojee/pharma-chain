"""
Manufacturer Dashboard - Flask backend
---------------------------------------
This is the WEBSITE side of the project (separate from the Flutter mobile app).
It lets a manufacturer register pharmaceutical products, which get saved to the
same Cloud Firestore database the mobile app reads from, and generates the QR
code identifier for each product (FR3 + FR4 from the requirements doc).

FIREBASE SETUP:
This app tries to connect to Firebase Admin SDK using a service account key.
If no key is found, it runs in DEMO MODE with an in-memory list instead, so
you can still build/test the UI before real credentials are added.

To connect for real:
1. Firebase Console -> Project Settings -> Service Accounts -> Generate new private key
2. Save the downloaded json file as: serviceAccountKey.json in this folder
3. NEVER commit that file to Git - add it to .gitignore
"""

import os
import uuid
from datetime import datetime

from flask import Flask, render_template, request, redirect, url_for, flash
import qrcode

app = Flask(__name__)
app.secret_key = "dev-secret-change-this"  # only for flash messages, not real security

QR_FOLDER = os.path.join(app.static_folder, "qrcodes")
os.makedirs(QR_FOLDER, exist_ok=True)

# ---------------------------------------------------------------------------
# Firebase connection (falls back to demo mode if not configured)
# ---------------------------------------------------------------------------
FIREBASE_READY = False
db = None

try:
    import firebase_admin
    from firebase_admin import credentials, firestore

    cred_path = os.path.join(os.path.dirname(__file__), "serviceAccountKey.json")
    if os.path.exists(cred_path):
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
        db = firestore.client()
        FIREBASE_READY = True
    else:
        print("[demo mode] serviceAccountKey.json not found - using in-memory data instead.")
except Exception as e:
    print(f"[demo mode] Firebase not available ({e}) - using in-memory data instead.")

# In-memory fallback store, used only when Firebase isn't connected yet
DEMO_MEDICINES = []


# ---------------------------------------------------------------------------
# Data access helpers - these hide whether we're talking to Firestore or the
# in-memory demo list, so the routes below don't need to care.
# ---------------------------------------------------------------------------
def save_medicine(data: dict) -> str:
    if FIREBASE_READY:
        doc_ref = db.collection("medicines").document(data["medicineId"])
        doc_ref.set(data)
    else:
        DEMO_MEDICINES.append(data)
    return data["medicineId"]


def get_all_medicines() -> list:
    if FIREBASE_READY:
        docs = db.collection("medicines").stream()
        return [doc.to_dict() for doc in docs]
    return list(reversed(DEMO_MEDICINES))


def get_medicine(medicine_id: str):
    if FIREBASE_READY:
        doc = db.collection("medicines").document(medicine_id).get()
        return doc.to_dict() if doc.exists else None
    return next((m for m in DEMO_MEDICINES if m["medicineId"] == medicine_id), None)


def generate_qr_code(medicine_id: str) -> str:
    """Generates a QR code image containing the medicineId and saves it.
    Returns the filename (relative to /static/qrcodes/)."""
    img = qrcode.make(medicine_id)
    filename = f"{medicine_id}.png"
    img.save(os.path.join(QR_FOLDER, filename))
    return filename


# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------
@app.route("/")
def dashboard():
    medicines = get_all_medicines()
    stats = {
        "total_products": len(medicines),
        "recent": medicines[:5],
    }
    return render_template(
        "dashboard.html",
        stats=stats,
        firebase_ready=FIREBASE_READY,
        active_page="dashboard",
    )


@app.route("/register", methods=["GET", "POST"])
def register():
    if request.method == "POST":
        name = request.form.get("name", "").strip()
        generic_name = request.form.get("generic_name", "").strip()
        batch_number = request.form.get("batch_number", "").strip()
        manufacture_date = request.form.get("manufacture_date", "")
        expiry_date = request.form.get("expiry_date", "")
        quantity = request.form.get("quantity", "").strip()
        manufacturer_name = request.form.get("manufacturer_name", "").strip()

        # Basic validation - keep it simple, expand as needed
        if not all([name, batch_number, manufacture_date, expiry_date, quantity, manufacturer_name]):
            flash("Please fill in all required fields.", "error")
            return render_template("register.html", active_page="register", form=request.form)

        medicine_id = f"MED-{uuid.uuid4().hex[:10].upper()}"

        medicine_data = {
            "medicineId": medicine_id,
            "name": name,
            "genericName": generic_name,
            "batchNumber": batch_number,
            "manufacturerName": manufacturer_name,
            "manufactureDate": manufacture_date,
            "expiryDate": expiry_date,
            "quantity": quantity,
            "qrCodeId": medicine_id,
            "currentStatus": "manufactured",
            "createdAt": datetime.utcnow().isoformat(),
        }

        save_medicine(medicine_data)
        generate_qr_code(medicine_id)

        flash(f"Product '{name}' registered successfully.", "success")
        return redirect(url_for("view_product", medicine_id=medicine_id))

    return render_template("register.html", active_page="register", form={})


@app.route("/products")
def products():
    medicines = get_all_medicines()
    return render_template(
        "products.html", medicines=medicines, active_page="products", firebase_ready=FIREBASE_READY
    )


@app.route("/products/<medicine_id>")
def view_product(medicine_id):
    medicine = get_medicine(medicine_id)
    if medicine is None:
        flash("Product not found.", "error")
        return redirect(url_for("products"))
    return render_template("product_detail.html", medicine=medicine, active_page="products")


if __name__ == "__main__":
    app.run(debug=True)
