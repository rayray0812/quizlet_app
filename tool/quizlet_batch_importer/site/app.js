const STORAGE_KEY = "quizlet_batch_importer_state_v1";
const CAPTURE_PREFIX = "QUIZLET_CAPTURE::";

const extractorSource = String.raw`(async function() {
  function pickText(value) {
    if (value == null) return "";
    if (typeof value === "string" || typeof value === "number") return String(value).trim();
    if (Array.isArray(value)) return value.map(pickText).filter(Boolean).join(" ").trim();
    if (typeof value === "object") {
      const directKeys = ["plainText", "text", "word", "value", "label", "name", "prompt", "answer", "question", "title"];
      for (const key of directKeys) {
        if (value[key] != null) {
          const direct = pickText(value[key]);
          if (direct) return direct;
        }
      }
      if (value.richText != null) {
        const rich = pickText(value.richText);
        if (rich) return rich;
      }
    }
    return "";
  }

  function extractPair(item) {
    if (!item || typeof item !== "object") return null;
    let term = pickText(item.termText || item.term || item.word || item.prompt || item.left || item.question);
    let definition = pickText(item.definitionText || item.definition || item.meaning || item.right || item.answer || item.explanation);
    let imageUrl = "";

    if ((!term || !definition) && Array.isArray(item.cardSides) && item.cardSides.length >= 2) {
      term = term || pickText(item.cardSides[0]);
      definition = definition || pickText(item.cardSides[1]);
    }

    if ((!term || !definition) && Array.isArray(item.sides) && item.sides.length >= 2) {
      term = term || pickText(item.sides[0]);
      definition = definition || pickText(item.sides[1]);
    }

    if (item.imageUrl) imageUrl = String(item.imageUrl);
    if (item.image && item.image.url) imageUrl = String(item.image.url);

    if (!term || !definition) return null;
    return { term, definition, imageUrl };
  }

  const cards = [];
  const seen = new Set();
  let title = "";

  function addCard(term, definition, imageUrl) {
    const cleanTerm = String(term || "").trim();
    const cleanDefinition = String(definition || "").trim();
    if (!cleanTerm || !cleanDefinition) return;
    const key = cleanTerm + "\n" + cleanDefinition;
    if (seen.has(key)) return;
    seen.add(key);
    cards.push({ term: cleanTerm, definition: cleanDefinition, imageUrl: imageUrl || "" });
  }

  try {
    const nextDataNode = document.getElementById("__NEXT_DATA__");
    if (nextDataNode) {
      const parsed = JSON.parse(nextDataNode.textContent);
      const pageProps = parsed.props && parsed.props.pageProps;
      if (pageProps && pageProps.dehydratedReduxStateKey) {
        const state = JSON.parse(pageProps.dehydratedReduxStateKey);
        const setPage = state.setPage;
        if (setPage && setPage.set && setPage.set.title) title = String(setPage.set.title).trim();

        let terms = [];
        if (setPage && setPage.set && Array.isArray(setPage.set.terms)) {
          terms = setPage.set.terms;
        } else if (setPage && Array.isArray(setPage.terms)) {
          terms = setPage.terms;
        }

        for (const item of terms) {
          const pair = extractPair(item);
          if (pair) addCard(pair.term, pair.definition, pair.imageUrl);
        }

        if (!cards.length && state.cards && typeof state.cards === "object") {
          Object.values(state.cards).forEach((value) => {
            if (Array.isArray(value)) {
              value.forEach((item) => {
                const pair = extractPair(item);
                if (pair) addCard(pair.term, pair.definition, pair.imageUrl);
              });
            } else if (value && typeof value === "object") {
              Object.values(value).forEach((item) => {
                const pair = extractPair(item);
                if (pair) addCard(pair.term, pair.definition, pair.imageUrl);
              });
            }
          });
        }
      }
    }
  } catch (error) {}

  if (!cards.length) {
    document.querySelectorAll('[class*="SetPageTerm"]').forEach((container) => {
      const texts = container.querySelectorAll(".TermText, [data-testid='TextContent']");
      if (texts.length >= 2) {
        const image = container.querySelector("img");
        addCard(texts[0].innerText, texts[1].innerText, image ? image.src : "");
      }
    });
  }

  if (!cards.length) {
    const terms = Array.from(document.querySelectorAll(".TermText, [data-testid='TextContent']"));
    for (let index = 0; index + 1 < terms.length; index += 2) {
      addCard(terms[index].innerText, terms[index + 1].innerText, "");
    }
  }

  if (!title) {
    const titleNode = document.querySelector(".SetPage-titleWrapper h1, [data-testid='set-title'], .UIHeading--one, h1");
    title = titleNode ? titleNode.innerText.trim() : document.title.replace(" Flashcards", "").trim();
  }

  if (!cards.length) {
    alert("No cards found. Make sure the Quizlet page is fully loaded and expanded.");
    return;
  }

  const payload = "${CAPTURE_PREFIX}" + JSON.stringify({ sourceUrl: location.href, title, cards });

  try {
    await navigator.clipboard.writeText(payload);
    alert("Captured to clipboard. Go back to the local importer page and click Import from clipboard.");
  } catch (error) {
    prompt("Clipboard write failed. Copy this text manually:", payload);
  }
})();`;

const state = loadState();

const elements = {
  urlInput: document.querySelector("#urlInput"),
  addUrlsButton: document.querySelector("#addUrlsButton"),
  openNextButton: document.querySelector("#openNextButton"),
  clearQueueButton: document.querySelector("#clearQueueButton"),
  bookmarkletLink: document.querySelector("#bookmarkletLink"),
  copyBookmarkletButton: document.querySelector("#copyBookmarkletButton"),
  importClipboardButton: document.querySelector("#importClipboardButton"),
  clearCaptureInputButton: document.querySelector("#clearCaptureInputButton"),
  captureInput: document.querySelector("#captureInput"),
  queueCount: document.querySelector("#queueCount"),
  queueList: document.querySelector("#queueList"),
  capturedCount: document.querySelector("#capturedCount"),
  capturedList: document.querySelector("#capturedList"),
  selectAllButton: document.querySelector("#selectAllButton"),
  downloadSelectedSinglesButton: document.querySelector("#downloadSelectedSinglesButton"),
  clearCapturedButton: document.querySelector("#clearCapturedButton"),
  mergeTitleInput: document.querySelector("#mergeTitleInput"),
  mergeDescriptionInput: document.querySelector("#mergeDescriptionInput"),
  dedupeCheckbox: document.querySelector("#dedupeCheckbox"),
  downloadMergedButton: document.querySelector("#downloadMergedButton"),
  copyMergedJsonButton: document.querySelector("#copyMergedJsonButton"),
  exportPreview: document.querySelector("#exportPreview"),
  queueItemTemplate: document.querySelector("#queueItemTemplate"),
  capturedItemTemplate: document.querySelector("#capturedItemTemplate")
};

applyBookmarklet();
bindEvents();
render();

function loadState() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return defaultState();
    const parsed = JSON.parse(raw);
    return {
      queue: Array.isArray(parsed.queue) ? parsed.queue : [],
      capturedSets: Array.isArray(parsed.capturedSets) ? parsed.capturedSets : [],
      selectedSetIds: Array.isArray(parsed.selectedSetIds) ? parsed.selectedSetIds : [],
      mergeTitle: typeof parsed.mergeTitle === "string" ? parsed.mergeTitle : "",
      mergeDescription: typeof parsed.mergeDescription === "string" ? parsed.mergeDescription : "",
      dedupeMergedCards: parsed.dedupeMergedCards !== false
    };
  } catch (error) {
    return defaultState();
  }
}

function defaultState() {
  return {
    queue: [],
    capturedSets: [],
    selectedSetIds: [],
    mergeTitle: "",
    mergeDescription: "",
    dedupeMergedCards: true
  };
}

function saveState() {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
}

function bindEvents() {
  elements.addUrlsButton.addEventListener("click", addUrlsFromInput);
  elements.openNextButton.addEventListener("click", openNextPendingLink);
  elements.clearQueueButton.addEventListener("click", () => {
    state.queue = [];
    saveState();
    render();
  });
  elements.copyBookmarkletButton.addEventListener("click", copyBookmarklet);
  elements.importClipboardButton.addEventListener("click", importFromClipboardOrTextarea);
  elements.clearCaptureInputButton.addEventListener("click", () => {
    elements.captureInput.value = "";
  });
  elements.selectAllButton.addEventListener("click", selectAllCapturedSets);
  elements.downloadSelectedSinglesButton.addEventListener("click", downloadSelectedSingles);
  elements.clearCapturedButton.addEventListener("click", () => {
    state.capturedSets = [];
    state.selectedSetIds = [];
    saveState();
    render();
  });
  elements.mergeTitleInput.addEventListener("input", (event) => {
    state.mergeTitle = event.target.value;
    saveState();
    renderPreview();
  });
  elements.mergeDescriptionInput.addEventListener("input", (event) => {
    state.mergeDescription = event.target.value;
    saveState();
    renderPreview();
  });
  elements.dedupeCheckbox.addEventListener("change", (event) => {
    state.dedupeMergedCards = event.target.checked;
    saveState();
    renderPreview();
  });
  elements.downloadMergedButton.addEventListener("click", downloadMergedJson);
  elements.copyMergedJsonButton.addEventListener("click", copyMergedJson);
}

function applyBookmarklet() {
  elements.bookmarkletLink.href = "javascript:" + extractorSource.replace(/\s+/g, " ");
}

async function copyBookmarklet() {
  await navigator.clipboard.writeText(elements.bookmarkletLink.href);
  alert("Bookmarklet copied. Create a browser bookmark and paste this into its URL field.");
}

function addUrlsFromInput() {
  const lines = elements.urlInput.value.split(/\r?\n/).map((line) => normalizeUrl(line)).filter(Boolean);
  const existing = new Set(state.queue.map((item) => item.url));
  const additions = [];

  for (const url of lines) {
    if (existing.has(url)) continue;
    additions.push({ id: crypto.randomUUID(), url, status: findCapturedByUrl(url) ? "captured" : "pending" });
    existing.add(url);
  }

  if (!additions.length) return;
  state.queue.unshift(...additions);
  elements.urlInput.value = "";
  saveState();
  render();
}

function openNextPendingLink() {
  const nextItem = state.queue.find((item) => item.status !== "captured");
  if (!nextItem) {
    alert("No pending Quizlet links left.");
    return;
  }
  window.open(nextItem.url, "_blank", "noopener,noreferrer");
}

async function importFromClipboardOrTextarea() {
  const typedValue = elements.captureInput.value.trim();
  if (typedValue) {
    importCapturePayload(typedValue);
    return;
  }

  try {
    const text = await navigator.clipboard.readText();
    importCapturePayload(text);
  } catch (error) {
    alert("Clipboard read failed. Paste the captured text into the textarea first.");
  }
}

function importCapturePayload(rawText) {
  const text = String(rawText || "").trim();
  if (!text) {
    alert("No captured text found.");
    return;
  }

  const payloadText = text.startsWith(CAPTURE_PREFIX) ? text.slice(CAPTURE_PREFIX.length) : text;

  try {
    const payload = JSON.parse(payloadText);
    upsertCapturedSet(payload);
    elements.captureInput.value = "";
  } catch (error) {
    alert("Invalid capture payload. Make sure you copied the full text from the bookmarklet.");
  }
}

function normalizeUrl(raw) {
  const value = String(raw || "").trim();
  if (!value) return "";
  try {
    const url = new URL(value.startsWith("http") ? value : "https://" + value);
    return url.toString();
  } catch (error) {
    return "";
  }
}

function upsertCapturedSet(payload) {
  const normalizedUrl = normalizeUrl(payload.sourceUrl);
  const cards = Array.isArray(payload.cards)
    ? payload.cards.map((card) => ({
        term: String(card.term || "").trim(),
        definition: String(card.definition || "").trim(),
        imageUrl: String(card.imageUrl || "").trim()
      })).filter((card) => card.term && card.definition)
    : [];

  if (!cards.length) {
    alert("This capture did not contain any usable cards.");
    return;
  }

  const existingIndex = state.capturedSets.findIndex((item) => item.sourceUrl === normalizedUrl);
  const nextSet = {
    id: existingIndex >= 0 ? state.capturedSets[existingIndex].id : crypto.randomUUID(),
    title: String(payload.title || "Imported Set").trim() || "Imported Set",
    sourceUrl: normalizedUrl,
    cards,
    capturedAt: new Date().toISOString()
  };

  if (existingIndex >= 0) {
    state.capturedSets.splice(existingIndex, 1, nextSet);
  } else {
    state.capturedSets.unshift(nextSet);
  }

  if (!state.selectedSetIds.includes(nextSet.id)) state.selectedSetIds.push(nextSet.id);
  state.queue = state.queue.map((item) => item.url === normalizedUrl ? { ...item, status: "captured" } : item);
  if (!state.mergeTitle) state.mergeTitle = nextSet.title;
  saveState();
  render();
}

function findCapturedByUrl(url) {
  return state.capturedSets.find((item) => item.sourceUrl === url);
}

function render() {
  elements.mergeTitleInput.value = state.mergeTitle;
  elements.mergeDescriptionInput.value = state.mergeDescription;
  elements.dedupeCheckbox.checked = state.dedupeMergedCards;
  renderQueue();
  renderCapturedSets();
  renderPreview();
}

function renderQueue() {
  elements.queueCount.textContent = `${state.queue.length} links`;
  elements.queueList.innerHTML = "";
  if (!state.queue.length) {
    elements.queueList.innerHTML = `<p class="hint">還沒有連結。先貼上一批 Quizlet 網址。</p>`;
    return;
  }

  for (const item of state.queue) {
    const node = elements.queueItemTemplate.content.firstElementChild.cloneNode(true);
    node.querySelector(".queue-label").textContent = item.url.split("/").filter(Boolean).pop() || item.url;
    node.querySelector(".status-pill").textContent = item.status === "captured" ? "captured" : "pending";
    const link = node.querySelector(".queue-url");
    link.href = item.url;
    link.textContent = item.url;
    node.querySelector(".open-link-button").addEventListener("click", () => window.open(item.url, "_blank", "noopener,noreferrer"));
    node.querySelector(".remove-link-button").addEventListener("click", () => {
      state.queue = state.queue.filter((entry) => entry.id !== item.id);
      saveState();
      render();
    });
    elements.queueList.appendChild(node);
  }
}

function renderCapturedSets() {
  elements.capturedCount.textContent = `${state.capturedSets.length} sets`;
  elements.capturedList.innerHTML = "";
  if (!state.capturedSets.length) {
    elements.capturedList.innerHTML = `<p class="hint">還沒有抓到任何 Quizlet 單字集。</p>`;
    return;
  }

  for (const set of state.capturedSets) {
    const node = elements.capturedItemTemplate.content.firstElementChild.cloneNode(true);
    const checkbox = node.querySelector(".select-set-checkbox");
    checkbox.checked = state.selectedSetIds.includes(set.id);
    checkbox.addEventListener("change", (event) => {
      if (event.target.checked) {
        if (!state.selectedSetIds.includes(set.id)) state.selectedSetIds.push(set.id);
      } else {
        state.selectedSetIds = state.selectedSetIds.filter((id) => id !== set.id);
      }
      saveState();
      renderPreview();
    });

    node.querySelector(".captured-title").textContent = set.title;
    node.querySelector(".captured-count").textContent = `${set.cards.length} cards`;
    const link = node.querySelector(".captured-url");
    link.href = set.sourceUrl;
    link.textContent = set.sourceUrl;
    node.querySelector(".download-single-button").addEventListener("click", () => downloadJson(buildSingleSetJson(set), sanitizeFilename(set.title || "quizlet_set") + ".json"));
    node.querySelector(".remove-set-button").addEventListener("click", () => {
      state.capturedSets = state.capturedSets.filter((item) => item.id !== set.id);
      state.selectedSetIds = state.selectedSetIds.filter((id) => id !== set.id);
      state.queue = state.queue.map((entry) => entry.url === set.sourceUrl ? { ...entry, status: "pending" } : entry);
      saveState();
      render();
    });
    elements.capturedList.appendChild(node);
  }
}

function renderPreview() {
  const payload = buildMergedPayload();
  elements.exportPreview.textContent = payload ? JSON.stringify(payload, null, 2) : "尚未產生 JSON";
}

function selectAllCapturedSets() {
  state.selectedSetIds = state.capturedSets.map((item) => item.id);
  saveState();
  render();
}

function getSelectedSets() {
  return state.capturedSets.filter((item) => state.selectedSetIds.includes(item.id));
}

function buildMergedPayload() {
  const selectedSets = getSelectedSets();
  if (!selectedSets.length) return null;

  const mergedCards = [];
  const seen = new Set();
  for (const set of selectedSets) {
    for (const card of set.cards) {
      const nextCard = { term: card.term, definition: card.definition, exampleSentence: "" };
      if (state.dedupeMergedCards) {
        const key = `${nextCard.term}\n${nextCard.definition}`;
        if (seen.has(key)) continue;
        seen.add(key);
      }
      mergedCards.push(nextCard);
    }
  }

  if (!mergedCards.length) return null;
  const title = state.mergeTitle.trim() || (selectedSets.length === 1 ? selectedSets[0].title : `Merged Quizlet Set ${new Date().toISOString().slice(0, 10)}`);
  return { title, description: state.mergeDescription.trim(), cards: mergedCards };
}

function buildSingleSetJson(set) {
  return {
    title: set.title,
    description: "",
    cards: set.cards.map((card) => ({ term: card.term, definition: card.definition, exampleSentence: "" }))
  };
}

function downloadMergedJson() {
  const payload = buildMergedPayload();
  if (!payload) {
    alert("Nothing to export. Select at least one captured set first.");
    return;
  }
  downloadJson(payload, sanitizeFilename(payload.title) + ".json");
}

function downloadSelectedSingles() {
  const selectedSets = getSelectedSets();
  if (!selectedSets.length) {
    alert("Select at least one captured set first.");
    return;
  }
  selectedSets.forEach((set, index) => {
    setTimeout(() => {
      downloadJson(buildSingleSetJson(set), sanitizeFilename(set.title || `quizlet_set_${index + 1}`) + ".json");
    }, index * 150);
  });
}

async function copyMergedJson() {
  const payload = buildMergedPayload();
  if (!payload) {
    alert("Nothing to copy.");
    return;
  }
  await navigator.clipboard.writeText(JSON.stringify(payload, null, 2));
  alert("Merged JSON copied.");
}

function downloadJson(payload, filename) {
  const blob = new Blob([JSON.stringify(payload, null, 2)], { type: "application/json" });
  const url = URL.createObjectURL(blob);
  const anchor = document.createElement("a");
  anchor.href = url;
  anchor.download = filename;
  anchor.click();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
}

function sanitizeFilename(value) {
  const sanitized = String(value || "quizlet_set").replace(/[<>:"/\\|?*\u0000-\u001F]/g, "_").replace(/\s+/g, "_").trim();
  return sanitized || "quizlet_set";
}
