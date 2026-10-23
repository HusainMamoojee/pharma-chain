# PharmaChain

A mobile app that lets patients check whether a medicine batch is genuine, and lets supply-chain staff hand batches over with a verifiable record. Batch and custody records are kept on a permissioned Hyperledger Fabric ledger.

Final-year project, Eduvos ITMDA3 (Faculty of Information Technology).

**Team:** Husain Mamoojee, [Team member 2], [Team member 3]

## What it does

**Patients**
- Scan a QR code on the pack, or type the batch code.
- See Verified, Expired or Not recognised, with the product, manufacturer and expiry date.
- See the batch's journey through the supply chain.
- Review recent verifications and report suspected counterfeits.

**Staff (manufacturers, distributors, pharmacies)**
- Sign in with email, password and two-factor authentication.
- Start a transfer of custody to another organisation, and confirm receipt of an incoming batch.
- View inventory, dispatches (including awaiting receipt) and an audit log for their own organisation.
- Export the audit log as CSV.

**Admins (web portal, separate repository)**
- Register organisations and mint batches.

## Architecture

```
Flutter app ──┐
              ├──> Gateway (Node.js + Express, HTTPS) ──> Hyperledger Fabric 2.5
Web portal ───┘            │                               (channel: mychannel,
                           └──> Firebase Auth + Firestore    chaincode: pharmachain)
```

- The apps never talk to the ledger directly. The gateway verifies the user's Firebase token, then reads or writes the ledger.
- The ledger is the source of truth for batch authenticity and custody.
- Firestore holds display data: organisation names, user profiles, activity logs (`scan_logs`), verification history and reports.
- The gateway and Fabric test network run on a single Azure virtual machine (South Africa North).

Related repository: [pharma-chain-web](https://github.com/HusainMamoojee/pharma-chain-web) (admin portal).

## Tech stack

| Part | Technology |
|---|---|
| Mobile app | Flutter (Dart), go_router, mobile_scanner |
| Auth and data | Firebase Authentication, Cloud Firestore |
| Gateway | Node.js, Express, served over HTTPS by Caddy |
| Ledger | Hyperledger Fabric 2.5, JavaScript chaincode, Docker |

## Getting started

### Prerequisites
- Flutter SDK (stable) and Xcode (iOS) or Android Studio (Android)
- A physical phone is recommended, because the scanner needs a camera
- Access to the project's Firebase project (`pharma-chain-e4cc2`)
- The gateway virtual machine must be running

### Run

```bash
git clone https://github.com/HusainMamoojee/pharma-chain.git
cd pharma-chain
flutter pub get
flutter run
```

The app points at the project's hosted gateway by default. To use a different gateway:

```bash
flutter run --dart-define=GATEWAY_URL=https://your-gateway.example.com
```

### Install a release build on an iPhone

```bash
flutter devices                       # find the device id
flutter run --release -d <device id>
```

Apps installed with a free Apple ID expire after 7 days.

## Project structure

```
lib/
  core/            theme (colours, text styles) and router
  features/
    auth/          login and registration (patients)
    staff_auth/    staff login, two-factor, dashboard
    verification/  scanner, result and counterfeit screens
    home/          patient home and recent verifications
    history/       verification history
    reports/       counterfeit reports
    staff_scan/    staff scanner
    custody/       transfer of custody
    inventory/     staff inventory
    dispatches/    outgoing and incoming transfers
    audit/         audit log and CSV export
    profile/       profile and settings
  services/        auth_service, gateway_service
```

## Known limitations

- A photocopied QR code still verifies, because the code identifies the batch, not the individual pack. Per-pack serial numbers are future work.
- This is a prototype: test passwords are used, two-factor secrets are stored in Firestore, and the Firestore rules allow any signed-in user to read and write.
- One test network on one server. A real deployment would have each organisation run its own peer.
- The ledger is append-only, so batches cannot be deleted.

## Future work

- Per-pack serial numbers
- Public-chain anchoring of ledger records
- Batch recall alerts and expiry notifications
- Tighter Firestore rules and managed secrets

