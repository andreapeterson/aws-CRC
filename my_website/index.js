const header = document.querySelector('.site-header');
const menuButton = document.querySelector('.menu-toggle');
const siteNav = document.querySelector('.site-nav');

function closeMenu() {
  if (!menuButton || !siteNav) return;
  menuButton.setAttribute('aria-expanded', 'false');
  siteNav.classList.remove('open');
  document.body.classList.remove('menu-open');
}

menuButton?.addEventListener('click', () => {
  const isOpen = menuButton.getAttribute('aria-expanded') === 'true';
  menuButton.setAttribute('aria-expanded', String(!isOpen));
  siteNav.classList.toggle('open', !isOpen);
  document.body.classList.toggle('menu-open', !isOpen);
});

siteNav?.querySelectorAll('a').forEach((link) => link.addEventListener('click', closeMenu));

window.addEventListener('scroll', () => {
  header?.classList.toggle('scrolled', window.scrollY > 12);
}, { passive: true });

const revealObserver = 'IntersectionObserver' in window
  ? new IntersectionObserver((entries, observer) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return;
        entry.target.classList.add('visible');
        observer.unobserve(entry.target);
      });
    }, { threshold: 0.12 })
  : null;

document.querySelectorAll('.reveal').forEach((element) => {
  if (revealObserver) revealObserver.observe(element);
  else element.classList.add('visible');
});

const visitorCounters = document.querySelectorAll('.counter-number');

async function updateVisitorCount() {
  if (!visitorCounters.length) return;
  try {
    const response = await fetch('https://mgkp5gmdeq2zh2vd6kntspfjn40tdtvo.lambda-url.us-east-1.on.aws/');
    if (!response.ok) throw new Error(`Visitor API returned ${response.status}`);
    const count = await response.json();
    visitorCounters.forEach((counter) => {
      counter.textContent = Number(count).toLocaleString();
    });
  } catch (error) {
    visitorCounters.forEach((counter) => {
      counter.textContent = 'Live on production';
    });
    console.info('Visitor count unavailable:', error);
  }
}

const year = document.getElementById('year');
if (year) year.textContent = new Date().getFullYear();

updateVisitorCount();
