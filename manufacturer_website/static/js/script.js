// script.js — manufacturer dashboard client-side behaviour

document.addEventListener("DOMContentLoaded", () => {
  autoDismissFlashMessages();
  validateRegisterForm();
});

// Fade out flash/success/error banners after a few seconds
function autoDismissFlashMessages() {
  const flashes = document.querySelectorAll(".flash");
  flashes.forEach((el) => {
    setTimeout(() => {
      el.style.transition = "opacity 0.4s ease";
      el.style.opacity = "0";
      setTimeout(() => el.remove(), 400);
    }, 4000);
  });
}

// Make sure expiry date is after manufacture date before letting the
// registration form submit. Server-side validation still runs regardless -
// this is just to catch the mistake earlier for the user.
function validateRegisterForm() {
  const form = document.getElementById("register-form");
  if (!form) return;

  form.addEventListener("submit", (event) => {
    const manufactureInput = form.querySelector('input[name="manufacture_date"]');
    const expiryInput = form.querySelector('input[name="expiry_date"]');

    if (manufactureInput.value && expiryInput.value) {
      const manufactureDate = new Date(manufactureInput.value);
      const expiryDate = new Date(expiryInput.value);

      if (expiryDate <= manufactureDate) {
        event.preventDefault();
        showFieldError(expiryInput, "Expiry date must be after the manufacture date.");
      }
    }
  });
}

function showFieldError(inputEl, message) {
  clearFieldError(inputEl);

  const errorEl = document.createElement("span");
  errorEl.className = "field__error";
  errorEl.style.color = "#C0392B";
  errorEl.style.fontSize = "12px";
  errorEl.textContent = message;

  inputEl.insertAdjacentElement("afterend", errorEl);
  inputEl.style.borderColor = "#C0392B";
}

function clearFieldError(inputEl) {
  const next = inputEl.nextElementSibling;
  if (next && next.classList.contains("field__error")) {
    next.remove();
  }
  inputEl.style.borderColor = "";
}
