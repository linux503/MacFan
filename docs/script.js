(() => {
  "use strict";

  document.documentElement.classList.add("js-ready");

  const storage = {
    get(key, fallback) {
      try { return localStorage.getItem(key) ?? fallback; } catch { return fallback; }
    },
    set(key, value) {
      try { localStorage.setItem(key, value); } catch { /* file:// or private mode */ }
    }
  };
  const revealNodes = document.querySelectorAll(".reveal");
  revealNodes.forEach((el, i) => {
    const parent = el.parentElement;
    const siblings = parent ? [...parent.querySelectorAll(":scope > .reveal")] : [];
    const idx = siblings.indexOf(el);
    if (idx >= 0) {
      el.style.setProperty("--reveal-delay", `${Math.min(idx * 80, 320)}ms`);
    }
  });
  const io = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.classList.add("visible");
          io.unobserve(entry.target);
        }
      });
    },
    { threshold: 0.1, rootMargin: "0px 0px -4% 0px" }
  );
  revealNodes.forEach((el) => io.observe(el));
  document.querySelectorAll(".hero-copy").forEach((el) => {
    requestAnimationFrame(() => el.classList.add("visible"));
  });

  const nav = document.getElementById("nav");
  const onScroll = () => nav?.classList.toggle("scrolled", window.scrollY > 20);
  window.addEventListener("scroll", onScroll, { passive: true });
  onScroll();

  const burger = document.getElementById("navBurger");
  const navLinks = document.querySelector(".nav-links");
  burger?.addEventListener("click", () => {
    const open = navLinks?.classList.toggle("open");
    burger.classList.toggle("open", open);
    burger.setAttribute("aria-expanded", String(!!open));
  });
  navLinks?.querySelectorAll("a").forEach((a) => {
    a.addEventListener("click", () => {
      navLinks.classList.remove("open");
      burger?.classList.remove("open");
      burger?.setAttribute("aria-expanded", "false");
    });
  });

  const cpuEl = document.getElementById("liveCpu");
  const rpmEl = document.getElementById("liveRpm");
  if (cpuEl && rpmEl) {
    let cpu = 47, rpm = 2460;
    setInterval(() => {
      cpu = Math.max(42, Math.min(56, cpu + (Math.random() - 0.5) * 2));
      rpm = Math.max(2200, Math.min(2800, rpm + (Math.random() - 0.5) * 70));
      cpuEl.textContent = `${Math.round(cpu)}°`;
      rpmEl.textContent = String(Math.round(rpm));
    }, 1800);
  }

  const dict = {
    zh: {
      "nav.showcase": "界面",
      "nav.features": "功能",
      "nav.scenes": "场景",
      "nav.start": "开始",
      "nav.download": "下载",
      "hero.badge": "原生 macOS",
      "hero.title1": "让 Mac 的风扇",
      "hero.title2": "听你的",
      "hero.lede": "原生 SwiftUI 风扇控制。实机读数，一键授权，真正写入 SMC。",
      "hero.ctaDownload": "免费下载",
      "hero.ctaSource": "GitHub",
      "showcase.tag": "界面",
      "showcase.title": "打开就能看懂的原生界面",
      "showcase.sub": "铝色日光海报：侧边栏切模式，主面板看温度、风扇与曲线。",
      "gallery.modes": "四种控制方式",
      "gallery.scenes": "六种开箱场景",
      "features.tag": "控制",
      "features.title": "四种方式，一种直觉",
      "features.sub": "不必在系统设置里翻找。",
      "f1.t": "最大转速",
      "f1.p": "编译、导出、游戏掉温——一键拉满全部风扇，立刻加压散热。",
      "f2.t": "手动调节",
      "f2.p": "逐风扇滑动设定 RPM，读数与滑杆实时对应。",
      "f3.t": "系统自动",
      "f3.p": "随时交还 macOS SMC 温控，安全收尾。",
      "f4.t": "场景模式",
      "f4.p": "按温度曲线运行，支持 App 联动与夜间调度。",
      "f4.a": "App 联动",
      "f4.b": "夜间调度",
      "f4.c": "温度曲线",
      "scenes.tag": "场景",
      "scenes.title": "六种场景，覆盖全天",
      "scenes.sub": "从静音办公到极速散热，Mac 一天里的热负载都有对应策略。",
      "s1.t": "静音办公", "s1.p": "文档与会议，优先低噪",
      "s2.t": "影音观影", "s2.p": "安静优先，温度略升也可",
      "s3.t": "创作渲染", "s3.p": "Xcode / Final Cut 自动加压",
      "s4.t": "游戏竞技", "s4.p": "高风量压制帧率掉温",
      "s5.t": "极速散热", "s5.p": "全风扇最大，极限降温",
      "s6.t": "夜间静音", "s6.p": "23:00–07:00 自动压转速",
      "arch.tag": "原生",
      "arch.title": "双架构，一份 App",
      "arch.sub": "Universal Binary 同时服务 Apple Silicon 与 Intel。芯片感知 SMC 键值、菜单栏快捷入口、实机读数。",
      "arch.live": "实机读数",
      "start.tag": "开始",
      "start.title": "三步上手",
      "start.sub": "下载、放到应用程序、授权——不用 Xcode。",
      "step1.t": "下载",
      "step1.p": "获取 Universal Binary，Apple Silicon 与 Intel 都能用。",
      "step2.t": "拖到应用程序",
      "step2.p": "拖进「应用程序」。若提示无法打开，右键图标选择「打开」。",
      "step3.t": "授权实控",
      "step3.p": "点击授权并输入密码，助手以 LaunchDaemon 写入 SMC。",
      "start.dev": "开发者可从 GitHub 克隆源码。",
      fineprint: "长时间手动控温后，请切回「系统自动」。Apple Silicon（M3/M4）可能受 thermalmonitord 约束，MacFan 已内置解锁流程。",
      "cta.title": "让 Mac 凉下来",
      "cta.sub": "免费开源 · MIT · Intel & Apple Silicon",
      "cta.download": "立即下载",
      "footer.download": "下载",
      langBtn: "EN",
      "meta.title": "MacFan — 精准控制 Mac 风扇",
      "meta.description": "MacFan 是原生 macOS 风扇控制工具。最大转速、单风扇手动调节、场景模式，支持 Apple Silicon 与 Intel。",
      "meta.ogTitle": "MacFan — 精准控制 Mac 风扇",
      "meta.ogDescription": "原生 SwiftUI 风扇控制 · 实机读数 · 一键授权写入 SMC",
      "alt.hero": "MacFan 应用界面",
      "alt.showcaseHome": "MacFan 主界面",
      "alt.modes": "四种控制方式",
      "alt.scenes": "六种智能场景",
      "alt.dashboard": "Dashboard 全景",
      "alt.start": "三步上手"
    },
    en: {
      "nav.showcase": "UI",
      "nav.features": "Features",
      "nav.scenes": "Scenes",
      "nav.start": "Start",
      "nav.download": "Download",
      "hero.badge": "Native macOS",
      "hero.title1": "Make your Mac's fans",
      "hero.title2": "obey you",
      "hero.lede": "Native SwiftUI fan control. Live readings, one-tap auth, real SMC writes.",
      "hero.ctaDownload": "Free Download",
      "hero.ctaSource": "GitHub",
      "showcase.tag": "Interface",
      "showcase.title": "A native UI you can read at a glance",
      "showcase.sub": "Daylight aluminum stills: sidebar modes, dashboard temps, fans, and curves.",
      "gallery.modes": "Four control modes",
      "gallery.scenes": "Six built-in scenes",
      "features.tag": "Control",
      "features.title": "Four modes, one intuition",
      "features.sub": "No digging in System Settings.",
      "f1.t": "Max Speed",
      "f1.p": "Compile, export, game — push every fan to the limit instantly.",
      "f2.t": "Manual",
      "f2.p": "Set target RPM per fan with live slider feedback.",
      "f3.t": "System Auto",
      "f3.p": "Hand thermal control back to macOS SMC anytime.",
      "f4.t": "Scenes",
      "f4.p": "Temperature curves with app linking and night schedules.",
      "f4.a": "App linking",
      "f4.b": "Night schedule",
      "f4.c": "Temp curves",
      "scenes.tag": "Scenes",
      "scenes.title": "Six scenes, full day",
      "scenes.sub": "From silent office to arctic max — every heat load covered.",
      "s1.t": "Silent Office", "s1.p": "Docs & meetings, noise first",
      "s2.t": "Media Lounge", "s2.p": "Quiet first, mild heat OK",
      "s3.t": "Creator Burst", "s3.p": "Boost for Xcode / Final Cut",
      "s4.t": "Game Arena", "s4.p": "High airflow vs frame drops",
      "s5.t": "Arctic Max", "s5.p": "All fans at maximum",
      "s6.t": "Night Owl", "s6.p": "Quieter 23:00–07:00 curve",
      "arch.tag": "Native",
      "arch.title": "Two chips, one app",
      "arch.sub": "Universal Binary for Apple Silicon & Intel. Chip-aware SMC, menu bar shortcuts, live readings.",
      "arch.live": "Live readings",
      "start.tag": "Get Started",
      "start.title": "Up in three steps",
      "start.sub": "Download, move to Applications, authorize — no Xcode required.",
      "step1.t": "Download",
      "step1.p": "Grab the Universal Binary for Apple Silicon and Intel.",
      "step2.t": "Move to Applications",
      "step2.p": "Drop it in Applications. If macOS blocks it, right-click the icon and choose Open.",
      "step3.t": "Authorize",
      "step3.p": "Tap authorize, enter your password. A LaunchDaemon writes SMC for real.",
      "start.dev": "Developers can clone the source from GitHub.",
      fineprint: "After long manual sessions, switch back to System Auto. Apple Silicon (M3/M4) may be constrained by thermalmonitord — MacFan includes unlock flow.",
      "cta.title": "Cool your Mac down",
      "cta.sub": "Free & open source · MIT · Intel & Apple Silicon",
      "cta.download": "Download now",
      "footer.download": "Download",
      langBtn: "中文",
      "meta.title": "MacFan — Precise Mac Fan Control",
      "meta.description": "MacFan is a native macOS fan controller. Max speed, per-fan manual tuning, scene modes — Apple Silicon & Intel.",
      "meta.ogTitle": "MacFan — Precise Mac Fan Control",
      "meta.ogDescription": "Native SwiftUI fan control · live readings · one-tap SMC authorization",
      "alt.hero": "MacFan app interface",
      "alt.showcaseHome": "MacFan dashboard",
      "alt.modes": "Four control modes",
      "alt.scenes": "Six smart scenes",
      "alt.dashboard": "Dashboard panorama",
      "alt.start": "Get started in three steps"
    }
  };

  let lang = storage.get("macfan.siteLang", "zh");
  const apply = () => {
    const table = dict[lang] || dict.zh;
    document.documentElement.lang = lang === "zh" ? "zh-Hans" : "en";
    document.title = table["meta.title"] || document.title;
    const desc = document.querySelector('meta[name="description"]');
    if (desc && table["meta.description"]) desc.setAttribute("content", table["meta.description"]);
    const ogTitle = document.querySelector('meta[property="og:title"]');
    if (ogTitle && table["meta.ogTitle"]) ogTitle.setAttribute("content", table["meta.ogTitle"]);
    const ogDesc = document.querySelector('meta[property="og:description"]');
    if (ogDesc && table["meta.ogDescription"]) ogDesc.setAttribute("content", table["meta.ogDescription"]);
    document.querySelectorAll("[data-i18n]").forEach((el) => {
      const key = el.getAttribute("data-i18n");
      if (table[key]) el.textContent = table[key];
    });
    document.querySelectorAll("[data-i18n-alt]").forEach((el) => {
      const key = el.getAttribute("data-i18n-alt");
      if (table[key]) el.setAttribute("alt", table[key]);
    });
    const btn = document.getElementById("langToggle");
    if (btn) btn.textContent = table.langBtn;
    document.querySelectorAll("[data-more-apps]").forEach((el) => {
      el.setAttribute("data-lang", lang);
    });
    if (window.Linux503MoreApps) window.Linux503MoreApps.refresh();
  };

  apply();

  document.getElementById("langToggle")?.addEventListener("click", () => {
    lang = lang === "zh" ? "en" : "zh";
    storage.set("macfan.siteLang", lang);
    apply();
    fetch("version.json")
      .then((r) => (r.ok ? r.json() : null))
      .then((data) => {
        const badgeEl = document.getElementById("heroBadge");
        if (!badgeEl || !data?.version) return;
        const suffix = lang === "zh" ? "原生 macOS" : "Native macOS";
        badgeEl.textContent = `v${data.version} · ${suffix}`;
      })
      .catch(() => {});
  });
})();

(() => {
  const versionEl = document.getElementById("heroVersion");
  const badgeEl = document.getElementById("heroBadge");
  const footerEl = document.getElementById("footerMeta");
  fetch("version.json")
    .then((r) => (r.ok ? r.json() : null))
    .then((data) => {
      if (!data?.version) return;
      const macos = data.min_macos ? ` · macOS ${data.min_macos}+` : "";
      if (versionEl) versionEl.textContent = `v${data.version}${macos}`;
      if (footerEl) footerEl.textContent = `MacFan · MIT · v${data.version}`;
      if (badgeEl) {
        const lang = document.documentElement.lang.startsWith("zh") ? "zh" : "en";
        const suffix = lang === "zh" ? "原生 macOS" : "Native macOS";
        badgeEl.textContent = `v${data.version} · ${suffix}`;
      }
      const zip = `assets/MacFan-${data.version}-macos.zip`;
      document.querySelectorAll('a[href*="macos.zip"]').forEach((a) => {
        a.setAttribute("href", zip);
      });
    })
    .catch(() => {});
})();
