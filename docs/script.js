(() => {
  const nodes = document.querySelectorAll(
    ".section-head, .feature-rail article, .scene-list li, .split > *, .steps li, .hero-copy, .hero-visual"
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
    { threshold: 0.16, rootMargin: "0px 0px -8% 0px" }
  );

  nodes.forEach((el) => io.observe(el));

  // Hero appears immediately
  document.querySelectorAll(".hero-copy, .hero-visual").forEach((el) => {
    requestAnimationFrame(() => el.classList.add("visible"));
  });
})();
