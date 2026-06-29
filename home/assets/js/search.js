(function() {
  document.addEventListener('keydown', function(e) {
    if (e.key === '/') {
      const active = document.activeElement;
      if (active && (active.tagName === 'INPUT' || active.tagName === 'TEXTAREA' || active.isContentEditable)) {
        return;
      }
      const searchBox = document.getElementById('site-search');
      if (searchBox) {
        e.preventDefault();
        searchBox.focus();
      }
    }
  });

  document.addEventListener('DOMContentLoaded', function() {
    const searchBox = document.getElementById('site-search');
    if (!searchBox) return;

    searchBox.addEventListener('focus', function() {
      if (!window.LaFamilleSearchIndex) {
        fetch('/search.json')
          .then(res => res.json())
          .then(data => {
            window.LaFamilleSearchIndex = data;
          })
          .catch(err => console.error('Error fetching search index:', err));
      }
    }, { once: true });

    let debounceTimer;
    searchBox.addEventListener('input', function(e) {
      clearTimeout(debounceTimer);
      debounceTimer = setTimeout(() => {
        handleSearch(e.target.value);
      }, 50);
    });
  });

  const escapeHTMLMap = {
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#39;'
  };

  function escapeHTML(str) {
    if (typeof str !== 'string') return '';
    return str.replace(/[&<>"']/g, match => escapeHTMLMap[match]);
  }

  function html(strings, ...values) {
    let out = strings[0];
    for (let i = 1; i < strings.length; i++) {
      out += escapeHTML(String(values[i - 1])) + strings[i];
    }
    return out;
  }

  function handleSearch(query) {
    const resultsList = document.getElementById('search-results-list');
    if (!resultsList) return;

    if (!query) {
      resultsList.innerHTML = '';
      resultsList.classList.add('hidden');
      return;
    }

    if (!window.LaFamilleSearchIndex) return;

    const lowerQuery = query.toLowerCase();
    const results = window.LaFamilleSearchIndex.filter(item => {
      const tMatch = item.t && String(item.t).toLowerCase().includes(lowerQuery);
      const gMatch = item.g && String(item.g).toLowerCase().includes(lowerQuery);
      const sMatch = item.s && String(item.s).toLowerCase().includes(lowerQuery);
      return tMatch || gMatch || sMatch;
    }).slice(0, 7);

    if (results.length === 0) {
      resultsList.innerHTML = '<li class="p-2 text-base-content/50">No results found</li>';
    } else {
      resultsList.innerHTML = results.map(item => {
        const title = item.t || item.g || item.s || 'Untitled';
        const link = item.url || item.u || item.href || item.link || '#';
        return html`<li><a href="${link}">${title}</a></li>`;
      }).join('');
    }
    resultsList.classList.remove('hidden');
  }
})();
