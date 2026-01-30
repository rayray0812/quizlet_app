class JsScraper {
  /// JavaScript to inject into Quizlet pages to extract flashcard data.
  /// Uses multiple fallback selectors since Quizlet changes DOM frequently.
  static const String scrapeScript = '''
    (function() {
      var cards = [];

      // Strategy 1: Modern Quizlet layout (2024+)
      var termElements = document.querySelectorAll('[data-testid="TextContent"]');
      if (termElements.length >= 2) {
        var rows = document.querySelectorAll('.SetPageTerms-term, .SetPageTerm-content');
        if (rows.length > 0) {
          rows.forEach(function(row) {
            var texts = row.querySelectorAll('[data-testid="TextContent"]');
            if (texts.length >= 2) {
              cards.push({
                term: texts[0].innerText.trim(),
                definition: texts[1].innerText.trim()
              });
            }
          });
        }
      }

      // Strategy 2: Fallback with class-based selectors
      if (cards.length === 0) {
        var termRows = document.querySelectorAll('.TermText');
        for (var i = 0; i < termRows.length; i += 2) {
          if (i + 1 < termRows.length) {
            cards.push({
              term: termRows[i].innerText.trim(),
              definition: termRows[i + 1].innerText.trim()
            });
          }
        }
      }

      // Strategy 3: Try aria-label based approach
      if (cards.length === 0) {
        var termContainers = document.querySelectorAll('[class*="SetPageTerm"]');
        termContainers.forEach(function(container) {
          var spans = container.querySelectorAll('span[class*="TermText"]');
          if (spans.length >= 2) {
            cards.push({
              term: spans[0].innerText.trim(),
              definition: spans[1].innerText.trim()
            });
          }
        });
      }

      // Strategy 4: Generic fallback - look for paired content divs
      if (cards.length === 0) {
        var allSpans = document.querySelectorAll('a.SetPageTerm-wordText span, a.SetPageTerm-definitionText span');
        for (var j = 0; j < allSpans.length; j += 2) {
          if (j + 1 < allSpans.length) {
            cards.push({
              term: allSpans[j].innerText.trim(),
              definition: allSpans[j + 1].innerText.trim()
            });
          }
        }
      }

      // Get title
      var title = '';
      var titleEl = document.querySelector('.SetPage-titleWrapper h1, [data-testid="set-title"], .UIHeading--one');
      if (titleEl) {
        title = titleEl.innerText.trim();
      } else {
        title = document.title.replace(' | Quizlet', '').replace(' Flashcards', '').trim();
      }

      return JSON.stringify({
        title: title,
        cards: cards
      });
    })();
  ''';
}
