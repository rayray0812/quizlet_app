class JsScraper {
  /// JavaScript injected into study-set pages to extract flashcard data.
  /// Returns encodeURIComponent'd JSON to avoid WebView escaping issues.
  static const String scrapeScript = '''
    (function() {
      var cards = [];
      var title = '';

      // Strategy 1: __NEXT_DATA__ dehydrated redux state
      try {
        var nd = document.getElementById('__NEXT_DATA__');
        if (nd) {
          var parsed = JSON.parse(nd.textContent);
          var pp = parsed.props && parsed.props.pageProps;
          if (pp && pp.dehydratedReduxStateKey) {
            var state = JSON.parse(pp.dehydratedReduxStateKey);
            var sp = state.setPage;
            if (sp && sp.set && sp.set.title) {
              title = sp.set.title;
            }
            // Terms might be in setPage.originalOrder + termIdToQuestionMap
            if (sp && sp.originalOrder && sp.originalOrder.length > 0) {
              // Not sure of structure, skip to DOM
            }
          }
        }
      } catch(e) {}

      // Strategy 2: DOM ??pair TermText within each SetPageTerm container
      if (cards.length === 0) {
        var containers = document.querySelectorAll('[class*="SetPageTerm"]');
        containers.forEach(function(container) {
          var texts = container.querySelectorAll('.TermText');
          if (texts.length >= 2) {
            var img = container.querySelector('img');
            cards.push({
              term: texts[0].innerText.trim(),
              definition: texts[1].innerText.trim(),
              imageUrl: img ? img.src : ''
            });
          }
        });
      }

      // Strategy 3: Flat TermText pairing
      if (cards.length === 0) {
        var allTermTexts = document.querySelectorAll('.TermText');
        for (var i = 0; i < allTermTexts.length; i += 2) {
          if (i + 1 < allTermTexts.length) {
            cards.push({
              term: allTermTexts[i].innerText.trim(),
              definition: allTermTexts[i + 1].innerText.trim(),
              imageUrl: ''
            });
          }
        }
      }

      // Strategy 4: data-testid selectors
      if (cards.length === 0) {
        var rows = document.querySelectorAll('.SetPageTerms-term, .SetPageTerm-content');
        rows.forEach(function(row) {
          var texts = row.querySelectorAll('[data-testid="TextContent"]');
          if (texts.length >= 2) {
            var img = row.querySelector('img');
            cards.push({
              term: texts[0].innerText.trim(),
              definition: texts[1].innerText.trim(),
              imageUrl: img ? img.src : ''
            });
          }
        });
      }

      // Get title if not found yet
      if (!title) {
        var titleEl = document.querySelector('.SetPage-titleWrapper h1, [data-testid="set-title"], .UIHeading--one');
        if (titleEl) {
          title = titleEl.innerText.trim();
        } else {
          title = document.title.replace(' Flashcards', '').trim();
        }
      }

      var result = JSON.stringify({ title: title, cards: cards });
      return encodeURIComponent(result);
    })();
  ''';
}


