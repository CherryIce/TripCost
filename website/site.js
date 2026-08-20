(() => {
  "use strict";

  const languageKey = "tripcost-site-language";
  const supportedLanguages = new Set(["zh", "en"]);
  const page = document.body.dataset.page || "home";

  const pageMetadata = {
    home: {
      zh: {
        title: "TripCost — 旅行真实消费成本助手",
        description:
          "TripCost 是免费的旅行真实消费成本助手：扫描价格、比较支付成本、识别 DCC 加价，并持续掌握旅行预算。",
      },
      en: {
        title: "TripCost — A True Travel Cost Assistant",
        description:
          "Scan local prices, compare payment costs, spot DCC markups, and keep your travel budget on track.",
      },
    },
    privacy: {
      zh: {
        title: "TripCost 隐私政策",
        description:
          "了解 TripCost 如何在设备本地处理旅行、消费、票据和汇率数据，以及可选的 iCloud 同步。",
      },
      en: {
        title: "TripCost Privacy Policy",
        description:
          "Learn how TripCost handles trips, expenses, receipts, and rate data on device, plus optional iCloud sync.",
      },
    },
  };

  function savedLanguage() {
    const queryLanguage = new URLSearchParams(window.location.search).get("lang");
    if (supportedLanguages.has(queryLanguage)) return queryLanguage;

    try {
      const saved = window.localStorage.getItem(languageKey);
      if (supportedLanguages.has(saved)) return saved;
    } catch (_) {
      // The site still works if local storage is unavailable.
    }

    return navigator.language.toLowerCase().startsWith("zh") ? "zh" : "en";
  }

  function updateInternalLinks(language) {
    document.querySelectorAll("[data-language-link]").forEach((link) => {
      const href = link.getAttribute("href");
      if (!href || href.startsWith("#") || href.startsWith("mailto:")) return;

      try {
        const url = new URL(href, window.location.href);
        if (url.protocol !== "http:" && url.protocol !== "https:" && url.protocol !== "file:") return;
        if (url.origin !== window.location.origin && url.protocol !== "file:") return;
        url.searchParams.set("lang", language);
        link.href = url.href;
      } catch (_) {
        // Leave a malformed or unsupported link unchanged.
      }
    });
  }

  function setLanguage(language, persist = true) {
    if (!supportedLanguages.has(language)) return;

    document.documentElement.lang = language === "zh" ? "zh-CN" : "en";

    document.querySelectorAll("[data-zh][data-en]").forEach((element) => {
      element.textContent = element.dataset[language];
    });

    document.querySelectorAll("[data-lang-choice]").forEach((button) => {
      button.setAttribute(
        "aria-pressed",
        String(button.dataset.langChoice === language),
      );
    });

    document.querySelectorAll("[data-policy-language]").forEach((block) => {
      block.hidden = block.dataset.policyLanguage !== language;
    });

    const metadata = pageMetadata[page]?.[language];
    if (metadata) {
      document.title = metadata.title;
      const description = document.querySelector('meta[name="description"]');
      if (description) description.content = metadata.description;
    }

    updateInternalLinks(language);

    if (persist) {
      try {
        window.localStorage.setItem(languageKey, language);
      } catch (_) {
        // The language remains active for the current page.
      }
    }
  }

  const initialLanguage = savedLanguage();
  setLanguage(initialLanguage, false);

  document.querySelectorAll("[data-lang-choice]").forEach((button) => {
    button.addEventListener("click", () => {
      setLanguage(button.dataset.langChoice);
    });
  });

  const header = document.querySelector("[data-header]");
  const updateHeader = () => {
    if (!header || page === "privacy") return;
    header.classList.toggle("is-scrolled", window.scrollY > 18);
  };
  updateHeader();
  window.addEventListener("scroll", updateHeader, { passive: true });

  const menuButton = document.querySelector("[data-menu-button]");
  const navigation = document.querySelector("[data-nav]");
  const closeMenu = () => {
    menuButton?.setAttribute("aria-expanded", "false");
    navigation?.classList.remove("is-open");
    document.body.classList.remove("menu-open");
  };

  menuButton?.addEventListener("click", () => {
    const willOpen = menuButton.getAttribute("aria-expanded") !== "true";
    menuButton.setAttribute("aria-expanded", String(willOpen));
    navigation?.classList.toggle("is-open", willOpen);
    document.body.classList.toggle("menu-open", willOpen);
  });

  navigation?.querySelectorAll("a").forEach((link) => {
    link.addEventListener("click", closeMenu);
  });

  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape") closeMenu();
  });

  document.querySelectorAll("[data-current-year]").forEach((element) => {
    element.textContent = String(new Date().getFullYear());
  });
})();
