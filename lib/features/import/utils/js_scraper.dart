class JsScraper {
  /// JavaScript injected into study-set pages to extract flashcard data.
  /// Returns encodeURIComponent'd JSON to avoid WebView escaping issues.
  static const String scrapeScript = '''
    (function() {
      var cards = [];
      var title = '';
      var seen = {};

      function addCard(term, definition, imageUrl) {
        term = (term || '').toString().trim();
        definition = (definition || '').toString().trim();
        if (!term || !definition) return;
        var key = term + '\\n' + definition;
        if (seen[key]) return;
        seen[key] = true;
        cards.push({
          term: term,
          definition: definition,
          imageUrl: imageUrl || ''
        });
      }

      function pickText(value) {
        if (value == null) return '';
        if (typeof value === 'string' || typeof value === 'number') {
          return String(value).trim();
        }
        if (Array.isArray(value)) {
          var parts = [];
          for (var i = 0; i < value.length; i++) {
            var t = pickText(value[i]);
            if (t) parts.push(t);
          }
          return parts.join(' ').trim();
        }
        if (typeof value === 'object') {
          var directKeys = [
            'plainText', 'text', 'word', 'value', 'label', 'name',
            'prompt', 'answer', 'question', 'title'
          ];
          for (var j = 0; j < directKeys.length; j++) {
            var dk = directKeys[j];
            if (value[dk] != null) {
              var direct = pickText(value[dk]);
              if (direct) return direct;
            }
          }
          if (value.richText != null) {
            var rich = pickText(value.richText);
            if (rich) return rich;
          }
        }
        return '';
      }

      function extractTermDefinition(item) {
        if (!item || typeof item !== 'object') return null;

        var term = '';
        var definition = '';
        var imageUrl = '';

        term = pickText(
          item.termText || item.term || item.word || item.prompt || item.left || item.question
        );
        definition = pickText(
          item.definitionText || item.definition || item.meaning || item.right || item.answer || item.explanation
        );

        if ((!term || !definition) && Array.isArray(item.cardSides) && item.cardSides.length >= 2) {
          term = term || pickText(item.cardSides[0]);
          definition = definition || pickText(item.cardSides[1]);
        }

        if ((!term || !definition) && Array.isArray(item.sides) && item.sides.length >= 2) {
          term = term || pickText(item.sides[0]);
          definition = definition || pickText(item.sides[1]);
        }

        if ((!term || !definition) && item.word && typeof item.word === 'object') {
          term = term || pickText(item.word);
          definition = definition || pickText(item.definition || item.meaning);
        }

        if (item.imageUrl) imageUrl = String(item.imageUrl);
        if (item.image && item.image.url) imageUrl = String(item.image.url);

        if (!term || !definition) return null;
        return { term: term, definition: definition, imageUrl: imageUrl };
      }

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

            // Try full terms array first (usually complete, not just visible items)
            var terms = [];
            if (sp && sp.set && Array.isArray(sp.set.terms)) {
              terms = sp.set.terms;
            } else if (sp && Array.isArray(sp.terms)) {
              terms = sp.terms;
            }
            for (var i = 0; i < terms.length; i++) {
              var td = extractTermDefinition(terms[i]);
              if (td) addCard(td.term, td.definition, td.imageUrl);
            }

            // Fallback: scan card-like collections in redux state
            if (cards.length === 0 && state.cards && typeof state.cards === 'object') {
              Object.keys(state.cards).forEach(function(key) {
                var value = state.cards[key];
                if (Array.isArray(value)) {
                  value.forEach(function(item) {
                    var td = extractTermDefinition(item);
                    if (td) addCard(td.term, td.definition, td.imageUrl);
                  });
                } else if (value && typeof value === 'object') {
                  Object.keys(value).forEach(function(innerKey) {
                    var td = extractTermDefinition(value[innerKey]);
                    if (td) addCard(td.term, td.definition, td.imageUrl);
                  });
                }
              });
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


