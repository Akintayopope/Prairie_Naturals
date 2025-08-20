//= require active_admin/base
//= require chartkick
//= require_self


(function () {
  var script = document.createElement("script");
  script.src = "https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js";
  script.defer = true;
  document.head.appendChild(script);
})();






  // Password toggle
  document.addEventListener("DOMContentLoaded", function () {
    const toggle = document.getElementById("togglePassword");
    const pwd = document.getElementById("password");
    const icon = document.getElementById("toggleIcon");
    if (toggle && pwd && icon) {
      toggle.addEventListener("click", () => {
        const isHidden = pwd.type === "password";
        pwd.type = isHidden ? "text" : "password";
        icon.className = isHidden ? "bi bi-eye-slash" : "bi bi-eye";
      });
    }


    const form = document.getElementById("adminLoginForm");
    const overlay = document.getElementById("loadingOverlay");
    if (form && overlay) {
      form.addEventListener("submit", () => {
        overlay.hidden = false;
      }, { passive: true });
    }


    const card = document.querySelector(".login-card");
    if (card) {
      document.addEventListener("mousemove", (e) => {
        const r = card.getBoundingClientRect();
        const x = e.clientX - (r.left + r.width / 2);
        const y = e.clientY - (r.top + r.height / 2);
        card.style.transform = `perspective(1000px) rotateY(${x / 60}deg) rotateX(${-y / 60}deg) translateY(-6px)`;
      });
      document.addEventListener("mouseleave", () => {
        card.style.transform = "perspective(1000px) rotateY(0) rotateX(0) translateY(0)";
      });
    }


    const requiredInputs = document.querySelectorAll("#adminLoginForm input[required]");
    requiredInputs.forEach((el) => {
      el.addEventListener("blur", () => {
        if (!el.checkValidity()) {
          el.classList.add("is-invalid");
        } else {
          el.classList.remove("is-invalid");
          el.classList.add("is-valid");
        }
      });
      el.addEventListener("input", () => el.classList.remove("is-invalid", "is-valid"));
    });
  });

