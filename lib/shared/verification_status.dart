/// Display names for the status values stored in the verifications collection.
/// The stored values stay as they are; only the wording shown to patients changes.
String verificationStatusLabel(String status) {
  switch (status) {
    case 'Authentic':
      return 'Verified';
    case 'Under Review':
      return 'Not recognised';
    case 'Expired':
      return 'Expired';
    default:
      return status;
  }
}