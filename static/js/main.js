// Auto-dismiss flash messages
document.querySelectorAll('.flash').forEach(el => {
  setTimeout(() => {
    el.style.transition = 'opacity .5s';
    el.style.opacity = '0';
    setTimeout(() => el.remove(), 500);
  }, 4000);
});

// Poster URL live preview on add_movie page
const posterInput = document.querySelector('input[name="poster_url"]');
if (posterInput) {
  posterInput.addEventListener('input', () => {
    let prev = document.getElementById('poster-preview');
    if (!prev) {
      prev = document.createElement('img');
      prev.id = 'poster-preview';
      prev.style.cssText = 'width:80px;border-radius:6px;margin-top:.5rem;display:block;border:1px solid var(--border)';
      posterInput.parentNode.appendChild(prev);
    }
    prev.src = posterInput.value;
    prev.onerror = () => prev.style.display = 'none';
    prev.onload  = () => prev.style.display = 'block';
  });
}

// Trailer preview on hover for movie cards
function extractYouTubeVideoId(url) {
  if (!url) return null;
  try {
    const parsed = new URL(url);
    if (parsed.hostname.includes('youtu.be')) {
      return parsed.pathname.replace('/', '') || null;
    }
    if (parsed.hostname.includes('youtube.com')) {
      return parsed.searchParams.get('v');
    }
  } catch (e) {
    return null;
  }
  return null;
}

const canHover = window.matchMedia('(hover: hover)').matches;
if (canHover) {
  const hoverCards = [...document.querySelectorAll('.movie-card[data-trailer-url]')]
    .filter((card) => extractYouTubeVideoId(card.dataset.trailerUrl));

  if (hoverCards.length) {
    const preview = document.createElement('div');
    preview.className = 'trailer-hover-preview';
    preview.innerHTML = [
      '<div class="trailer-hover-head">',
      '  <span class="dot"></span>',
      '  <span class="title"></span>',
      '</div>',
      '<div class="trailer-hover-frame"></div>'
    ].join('');
    document.body.appendChild(preview);

    const titleEl = preview.querySelector('.title');
    const frameEl = preview.querySelector('.trailer-hover-frame');
    let showTimer = null;

    const placePreviewNearCard = (card) => {
      const rect = card.getBoundingClientRect();
      const gap = 12;
      const previewWidth = Math.min(360, window.innerWidth - 24);
      let left = rect.right + gap;

      // If there is no room on the right side, show on the left.
      if (left + previewWidth > window.innerWidth - 12) {
        left = rect.left - previewWidth - gap;
      }

      // Clamp to viewport bounds.
      left = Math.max(12, Math.min(left, window.innerWidth - previewWidth - 12));
      let top = rect.top;
      top = Math.max(12, Math.min(top, window.innerHeight - 230));

      preview.style.left = `${left}px`;
      preview.style.top = `${top}px`;
      preview.style.right = 'auto';
      preview.style.bottom = 'auto';
      preview.style.width = `${previewWidth}px`;
    };

    const hidePreview = () => {
      window.clearTimeout(showTimer);
      preview.classList.remove('show');
      frameEl.innerHTML = '';
    };

    hoverCards.forEach((card) => {
      card.addEventListener('mouseenter', () => {
        const videoId = extractYouTubeVideoId(card.dataset.trailerUrl || '');
        if (!videoId) return;
        window.clearTimeout(showTimer);
        showTimer = window.setTimeout(() => {
          placePreviewNearCard(card);
          titleEl.textContent = card.dataset.movieTitle || 'Trailer Preview';
          frameEl.innerHTML = `<iframe src="https://www.youtube.com/embed/${videoId}?autoplay=1&mute=1&controls=0&rel=0&modestbranding=1&playsinline=1" title="Trailer preview" allow="autoplay; encrypted-media" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>`;
          preview.classList.add('show');
        }, 280);
      });

      card.addEventListener('mouseleave', hidePreview);
    });

    window.addEventListener('scroll', hidePreview, { passive: true });
    window.addEventListener('resize', hidePreview);
  }
}
