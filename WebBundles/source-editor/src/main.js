import { EditorState, Compartment } from '@codemirror/state'
import {
  EditorView,
  keymap,
  lineNumbers,
  highlightActiveLine,
  highlightActiveLineGutter,
  drawSelection,
  dropCursor,
} from '@codemirror/view'
import {
  defaultKeymap,
  history,
  historyKeymap,
  indentWithTab,
} from '@codemirror/commands'
import {
  indentOnInput,
  syntaxHighlighting,
  defaultHighlightStyle,
  bracketMatching,
} from '@codemirror/language'
import { markdown, markdownLanguage } from '@codemirror/lang-markdown'
import { languages } from '@codemirror/language-data'

// ─── Bridge ───────────────────────────────────────────────────────────────────

function postToSwift(message) {
  window.webkit?.messageHandlers?.editorBridge?.postMessage(message)
}

// ─── State ────────────────────────────────────────────────────────────────────

let view = null
let isLoadingContent = false
let notifyTimer = null

const readOnlyCompartment = new Compartment()

// ─── Theme ────────────────────────────────────────────────────────────────────

const lightTheme = EditorView.theme({
  '&': { height: '100%', background: '#ffffff' },
  '.cm-content': { fontFamily: '"JetBrains Mono", "SF Mono", Menlo, monospace' },
}, { dark: false })

// ─── Init ─────────────────────────────────────────────────────────────────────

function initEditor() {
  const state = EditorState.create({
    doc: '',
    extensions: [
      // History (undo/redo)
      history(),

      // Gutters
      lineNumbers(),
      highlightActiveLineGutter(),

      // Visual
      drawSelection(),
      dropCursor(),
      highlightActiveLine(),

      // Editing aids
      indentOnInput(),
      bracketMatching(),

      // Language: Markdown with embedded language support
      markdown({
        base: markdownLanguage,
        codeLanguages: languages,
      }),

      // Syntax highlighting
      syntaxHighlighting(defaultHighlightStyle, { fallback: true }),

      // Theme
      lightTheme,

      // Read-only compartment (toggled by Swift)
      readOnlyCompartment.of(EditorState.readOnly.of(false)),

      // Keybindings
      keymap.of([indentWithTab, ...defaultKeymap, ...historyKeymap]),

      // Content change listener → notify Swift
      EditorView.updateListener.of(update => {
        if (update.docChanged && !isLoadingContent) {
          clearTimeout(notifyTimer)
          notifyTimer = setTimeout(() => {
            postToSwift({ type: 'contentChanged', markdown: view.state.doc.toString() })
          }, 300)
        }
      }),
    ],
  })

  view = new EditorView({
    state,
    parent: document.getElementById('editor'),
  })

  postToSwift({ type: 'ready' })
}

// ─── Public API ───────────────────────────────────────────────────────────────

window.gitfluence = {
  loadDocument(content) {
    if (!view) return
    isLoadingContent = true
    view.dispatch({
      changes: { from: 0, to: view.state.doc.length, insert: content },
      // Move cursor to start
      selection: { anchor: 0 },
    })
    // Scroll to top
    view.scrollDOM.scrollTop = 0
    isLoadingContent = false
  },

  getMarkdown() {
    return view?.state.doc.toString() ?? ''
  },

  setReadOnly(readonly) {
    view?.dispatch({
      effects: readOnlyCompartment.reconfigure(EditorState.readOnly.of(readonly)),
    })
  },

  focus() {
    view?.focus()
  },
}

// ─── Boot ─────────────────────────────────────────────────────────────────────

document.addEventListener('DOMContentLoaded', initEditor)
