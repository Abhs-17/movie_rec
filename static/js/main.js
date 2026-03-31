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
