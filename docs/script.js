(() => {
  const nodes = document.querySelectorAll(
    ".section-head, .feature-rail article, .scene-list li, .split > *, .steps li, .hero-copy, .hero-visual, .poster-grid figure"
  );
  nodes.forEach((el) => el.classList.add("reveal"));

  const io = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.classList.add("visible");
          io.unobserve(entry.target);
        }
      });
    },
    { threshold: 0.14, rootMargin: "0px 0px -6% 0px" }
  );

  nodes.forEach((el) => io.observe(el));
  document.querySelectorAll(".hero-copy, .hero-visual").forEach((el) => {
    requestAnimationFrame(() => el.classList.add("visible"));
  });

  const dict = {
    zh: {
      "nav.gallery": "海报",
      "nav.features": "功能",
      "nav.scenes": "场景",
      "nav.start": "开始",
      "hero.eyebrow": "v1.1 · macOS · Intel & Apple Silicon",
      "hero.lede": "精准控制每一寸气流。最大转速、单风扇手调，以及会跟着你工作方式变化的智能场景。",
      "hero.ctaDownload": "下载 1.1",
      "hero.ctaSource": "查看源码",
      "hero.note": "Signal Night 全新配色 · 菜单栏更快识别 · 一键授权实控",
      "gallery.title": "产品海报",
      "gallery.sub": "为官网与发布页准备的界面海报，展示控制方式与场景引擎。",
      "gallery.dash": "主界面 · 实机读数",
      "gallery.modes": "四种控制方式",
      "gallery.scenes": "六种开箱场景",
      "features.title": "为一台真正在干活的 Mac 而设计",
      "features.sub": "不是一堆开关，而是四种控制方式与一套可扩展的场景引擎。",
      "f1.t": "最大转速",
      "f1.p": "一键拉满全部风扇，编译、导出、游戏掉温时立刻加压。",
      "f2.t": "手动调节",
      "f2.p": "逐风扇滑动设定目标 RPM，读数与滑杆实时对应。",
      "f3.t": "系统自动",
      "f3.p": "随时把温控交还 macOS SMC，安全收尾。",
      "f4.t": "场景模式",
      "f4.p": "按温度曲线运行，并可联动 App 与夜间时段。",
      "scenes.title": "六种开箱即用的场景",
      "scenes.sub": "从静音办公到极速散热，覆盖你一天里最常见的热负载。",
      "s1.t": "静音办公",
      "s1.p": "文档与会议，优先低噪",
      "s2.t": "影音观影",
      "s2.p": "安静优先，温度略升也可接受",
      "s3.t": "创作渲染",
      "s3.p": "Xcode / Final Cut / PS 自动加压",
      "s4.t": "游戏竞技",
      "s4.p": "高风量压制帧率掉温",
      "s5.t": "极速散热",
      "s5.p": "全风扇最大，极限降温",
      "s6.t": "夜间静音",
      "s6.p": "23:00–07:00 自动压转速",
      "arch.title": "双架构原生",
      "arch.sub": "Universal Binary，同一套界面与场景引擎同时服务 Apple Silicon 与 Intel。底层按芯片映射风扇键值，菜单栏与程序坞图标一并就绪。",
      "start.title": "三步开始",
      "start.sub": "克隆仓库，用 Xcode 运行；实控风扇时授权管理员权限。",
      "step1.t": "克隆",
      "step2.t": "运行",
      "step2.p": "Xcode 选择 My Mac，⌘R。首次可先体验界面与场景逻辑。",
      "step3.t": "授权实控",
      "step3.p": "在 App 内点击「授权管理员权限」，输入密码后即可写入 SMC 真正调速。",
      fineprint: "长时间手动控温后，请切回「系统自动」。Apple Silicon（尤其 M3/M4）可能受 thermalmonitord 约束，MacFan 已内置解锁流程。",
      langBtn: "EN"
    },
    en: {
      "nav.gallery": "Posters",
      "nav.features": "Features",
      "nav.scenes": "Scenes",
      "nav.start": "Start",
      "hero.eyebrow": "v1.1 · macOS · Intel & Apple Silicon",
      "hero.lede": "Precise airflow control. Max speed, per-fan manual tuning, and scenes that follow how you work.",
      "hero.ctaDownload": "Download 1.1",
      "hero.ctaSource": "View Source",
      "hero.note": "Signal Night palette · clearer menu bar · one-tap admin auth",
      "gallery.title": "Product posters",
      "gallery.sub": "Marketing shots for the site and release page — modes and scene engine.",
      "gallery.dash": "Dashboard · live readings",
      "gallery.modes": "Four control modes",
      "gallery.scenes": "Six built-in scenes",
      "features.title": "Built for a Mac that actually works hard",
      "features.sub": "Not a pile of toggles — four control modes and an extensible scene engine.",
      "f1.t": "Max Speed",
      "f1.p": "Push every fan to the limit for compile, export, or gaming heat.",
      "f2.t": "Manual",
      "f2.p": "Set target RPM per fan with live feedback.",
      "f3.t": "System Auto",
      "f3.p": "Hand thermal control back to macOS SMC anytime.",
      "f4.t": "Scenes",
      "f4.p": "Temperature curves plus app linking and night schedules.",
      "scenes.title": "Six scenes ready out of the box",
      "scenes.sub": "From silent office to arctic max — cover a full day of heat loads.",
      "s1.t": "Silent Office",
      "s1.p": "Docs and meetings, noise first",
      "s2.t": "Media Lounge",
      "s2.p": "Quiet first, mild heat OK",
      "s3.t": "Creator Burst",
      "s3.p": "Boost for Xcode / Final Cut / PS",
      "s4.t": "Game Arena",
      "s4.p": "High airflow against frame drops",
      "s5.t": "Arctic Max",
      "s5.p": "All fans at maximum",
      "s6.t": "Night Owl",
      "s6.p": "Quieter overnight curve",
      "arch.title": "Native on both architectures",
      "arch.sub": "One Universal Binary for Apple Silicon and Intel. Chip-aware SMC keys, menu bar, and Dock icon included.",
      "start.title": "Start in three steps",
      "start.sub": "Clone, run in Xcode, then authorize admin for live writes.",
      "step1.t": "Clone",
      "step2.t": "Run",
      "step2.p": "Pick My Mac in Xcode and press ⌘R. Explore UI and scenes first.",
      "step3.t": "Authorize",
      "step3.p": "Tap “Authorize Administrator”, enter your password, then write SMC for real control.",
      fineprint: "After long manual sessions, switch back to System Auto. Apple Silicon (esp. M3/M4) may be constrained by thermalmonitord — MacFan includes unlock flow.",
      langBtn: "中文"
    }
  };

  let lang = localStorage.getItem("macfan.siteLang") || "zh";
  const apply = () => {
    const table = dict[lang] || dict.zh;
    document.documentElement.lang = lang === "zh" ? "zh-Hans" : "en";
    document.querySelectorAll("[data-i18n]").forEach((el) => {
      const key = el.getAttribute("data-i18n");
      if (table[key]) el.textContent = table[key];
    });
    const btn = document.getElementById("langToggle");
    if (btn) btn.textContent = table.langBtn;
  };

  document.getElementById("langToggle")?.addEventListener("click", () => {
    lang = lang === "zh" ? "en" : "zh";
    localStorage.setItem("macfan.siteLang", lang);
    apply();
  });
  apply();
})();
