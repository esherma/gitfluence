import { Editor, Extension } from '@tiptap/core'
import StarterKit from '@tiptap/starter-kit'
import { Markdown } from 'tiptap-markdown'
import Placeholder from '@tiptap/extension-placeholder'
import TaskList from '@tiptap/extension-task-list'
import TaskItem from '@tiptap/extension-task-item'
import Link from '@tiptap/extension-link'
import Typography from '@tiptap/extension-typography'
import Table from '@tiptap/extension-table'
import TableRow from '@tiptap/extension-table-row'
import TableHeader from '@tiptap/extension-table-header'
import TableCell from '@tiptap/extension-table-cell'
import Suggestion from '@tiptap/suggestion'

// ─── Bridge ──────────────────────────────────────────────────────────────────

function postToSwift(msg) {
  window.webkit?.messageHandlers?.editorBridge?.postMessage(msg)
}

// ─── Slash command definitions ────────────────────────────────────────────────

const SLASH_COMMANDS = [
  {
    title: 'Heading 1',   desc: 'Large heading',     icon: 'H1',
    keys: ['h1', 'heading'],
    run: (e, r) => e.chain().focus().deleteRange(r).setHeading({ level: 1 }).run(),
  },
  {
    title: 'Heading 2',   desc: 'Medium heading',    icon: 'H2',
    keys: ['h2', 'heading'],
    run: (e, r) => e.chain().focus().deleteRange(r).setHeading({ level: 2 }).run(),
  },
  {
    title: 'Heading 3',   desc: 'Small heading',     icon: 'H3',
    keys: ['h3', 'heading'],
    run: (e, r) => e.chain().focus().deleteRange(r).setHeading({ level: 3 }).run(),
  },
  {
    title: 'Bullet List', desc: 'Unordered list',    icon: '•',
    keys: ['bullet', 'list', 'ul'],
    run: (e, r) => e.chain().focus().deleteRange(r).toggleBulletList().run(),
  },
  {
    title: 'Numbered List', desc: 'Ordered list',    icon: '1.',
    keys: ['numbered', 'ordered', 'list', 'ol'],
    run: (e, r) => e.chain().focus().deleteRange(r).toggleOrderedList().run(),
  },
  {
    title: 'Task List',   desc: 'Checkable items',   icon: '☐',
    keys: ['task', 'todo', 'check', 'checkbox'],
    run: (e, r) => e.chain().focus().deleteRange(r).toggleTaskList().run(),
  },
  {
    title: 'Blockquote',  desc: 'Quote block',       icon: '❝',
    keys: ['quote', 'blockquote'],
    run: (e, r) => e.chain().focus().deleteRange(r).toggleBlockquote().run(),
  },
  {
    title: 'Code Block',  desc: 'Code snippet',      icon: '</>',
    keys: ['code', 'pre', 'codeblock'],
    run: (e, r) => e.chain().focus().deleteRange(r).toggleCodeBlock().run(),
  },
  {
    title: 'Table',       desc: '3×3 table',         icon: '⊞',
    keys: ['table', 'grid'],
    run: (e, r) => e.chain().focus().deleteRange(r)
      .insertTable({ rows: 3, cols: 3, withHeaderRow: true }).run(),
  },
  {
    title: 'Divider',     desc: 'Horizontal line',   icon: '─',
    keys: ['divider', 'hr', 'rule', 'separator'],
    run: (e, r) => e.chain().focus().deleteRange(r).setHorizontalRule().run(),
  },
]

function filterSlashCommands(query) {
  const q = query.toLowerCase()
  if (!q) return SLASH_COMMANDS
  return SLASH_COMMANDS.filter(c =>
    c.title.toLowerCase().includes(q) || c.keys.some(k => k.includes(q))
  )
}

// ─── Slash menu DOM ───────────────────────────────────────────────────────────

let slashEl = null
let slashItems = []
let slashIdx = 0
let slashCallback = null

function getSlashEl() {
  if (!slashEl) {
    slashEl = document.createElement('div')
    slashEl.id = 'slash-menu'
    slashEl.hidden = true
    document.body.appendChild(slashEl)
  }
  return slashEl
}

function renderSlashMenu(items, idx, onSelect) {
  slashItems = items
  slashIdx = idx
  slashCallback = onSelect
  const el = getSlashEl()
  el.innerHTML = ''
  if (!items.length) { el.hidden = true; return }
  el.hidden = false
  items.forEach((item, i) => {
    const row = document.createElement('button')
    row.className = 'slash-row' + (i === idx ? ' slash-row--active' : '')
    row.innerHTML = `<span class="slash-icon">${item.icon}</span><span class="slash-body"><span class="slash-title">${item.title}</span><span class="slash-desc">${item.desc}</span></span>`
    row.addEventListener('mousedown', e => { e.preventDefault(); onSelect(item) })
    el.appendChild(row)
    if (i === idx) row.scrollIntoView({ block: 'nearest' })
  })
}

function positionSlashMenu(clientRect) {
  const el = getSlashEl()
  const rect = clientRect?.()
  if (!rect) return
  el.style.top  = `${rect.bottom + window.scrollY + 4}px`
  el.style.left = `${Math.max(4, Math.min(rect.left + window.scrollX, window.innerWidth - 248))}px`
}

// ─── SlashCommands TipTap extension ──────────────────────────────────────────

const SlashCommands = Extension.create({
  name: 'slashCommands',

  addProseMirrorPlugins() {
    return [
      Suggestion({
        editor: this.editor,
        char: '/',
        startOfLine: false,
        command: ({ editor, range, props }) => props.run(editor, range),
        items: ({ query }) => filterSlashCommands(query),
        render() {
          return {
            onStart(props) {
              slashIdx = 0
              renderSlashMenu(props.items, 0, item => props.command(item))
              positionSlashMenu(props.clientRect)
            },
            onUpdate(props) {
              slashIdx = Math.min(slashIdx, Math.max(props.items.length - 1, 0))
              renderSlashMenu(props.items, slashIdx, item => props.command(item))
              positionSlashMenu(props.clientRect)
            },
            onKeyDown({ event }) {
              const el = getSlashEl()
              if (el.hidden) return false
              const len = slashItems.length
              if (!len) return false
              if (event.key === 'ArrowDown') {
                slashIdx = (slashIdx + 1) % len
                renderSlashMenu(slashItems, slashIdx, slashCallback)
                return true
              }
              if (event.key === 'ArrowUp') {
                slashIdx = (slashIdx - 1 + len) % len
                renderSlashMenu(slashItems, slashIdx, slashCallback)
                return true
              }
              if (event.key === 'Enter') {
                slashCallback?.(slashItems[slashIdx])
                return true
              }
              if (event.key === 'Escape') {
                el.hidden = true
                return true
              }
              return false
            },
            onExit() {
              const el = getSlashEl()
              el.hidden = true
            },
          }
        },
      }),
    ]
  },
})

// ─── Toolbar state mapping ────────────────────────────────────────────────────

const TB_STATE = {
  'tb-bold':         e => e.isActive('bold'),
  'tb-italic':       e => e.isActive('italic'),
  'tb-strike':       e => e.isActive('strike'),
  'tb-code':         e => e.isActive('code'),
  'tb-link':         e => e.isActive('link'),
  'tb-blockquote':   e => e.isActive('blockquote'),
  'tb-code-block':   e => e.isActive('codeBlock'),
  'tb-bullet-list':  e => e.isActive('bulletList'),
  'tb-ordered-list': e => e.isActive('orderedList'),
  'tb-task-list':    e => e.isActive('taskList'),
}

function syncToolbar(editor) {
  const sel = document.getElementById('tb-block-type')
  if (sel) {
    sel.value =
      editor.isActive('heading', { level: 1 }) ? 'h1' :
      editor.isActive('heading', { level: 2 }) ? 'h2' :
      editor.isActive('heading', { level: 3 }) ? 'h3' : 'p'
  }
  for (const [id, isActive] of Object.entries(TB_STATE)) {
    document.getElementById(id)?.classList.toggle('tb-btn--active', isActive(editor))
  }
}

function bindToolbar(editor) {
  // Block type picker
  document.getElementById('tb-block-type')?.addEventListener('change', e => {
    const v = e.target.value
    if (v === 'p') editor.chain().focus().setParagraph().run()
    else           editor.chain().focus().setHeading({ level: parseInt(v[1]) }).run()
  })

  // Format buttons
  document.querySelectorAll('.tb-btn[data-cmd]').forEach(btn => {
    btn.addEventListener('mousedown', e => {
      e.preventDefault() // keep editor focused
      const ch = editor.chain().focus()
      switch (btn.dataset.cmd) {
        case 'bold':         ch.toggleBold().run();       break
        case 'italic':       ch.toggleItalic().run();     break
        case 'strike':       ch.toggleStrike().run();     break
        case 'code':         ch.toggleCode().run();       break
        case 'blockquote':   ch.toggleBlockquote().run(); break
        case 'code-block':   ch.toggleCodeBlock().run();  break
        case 'bullet-list':  ch.toggleBulletList().run(); break
        case 'ordered-list': ch.toggleOrderedList().run();break
        case 'task-list':    ch.toggleTaskList().run();   break
        case 'hr':           ch.setHorizontalRule().run();break
        case 'table':
          ch.insertTable({ rows: 3, cols: 3, withHeaderRow: true }).run()
          break
        case 'link': {
          const prev = editor.getAttributes('link').href ?? ''
          const url = window.prompt('Link URL', prev)
          if (url === null) break
          if (url === '') ch.unsetLink().run()
          else            ch.setLink({ href: url }).run()
          break
        }
      }
    })
  })
}

// ─── Editor init ──────────────────────────────────────────────────────────────

let editor = null
let isLoadingContent = false
let notifyTimer = null

function initEditor() {
  editor = new Editor({
    element: document.getElementById('editor'),
    extensions: [
      StarterKit.configure({
        codeBlock: { HTMLAttributes: { class: 'code-block' } },
      }),
      Markdown.configure({
        html: false,
        transformPastedText: true,
        transformCopiedText: true,
      }),
      Placeholder.configure({ placeholder: 'Start writing… (type / for commands)' }),
      TaskList,
      TaskItem.configure({ nested: true }),
      Link.configure({ openOnClick: false, autolink: true }),
      Typography,
      Table.configure({ resizable: false }),
      TableRow,
      TableHeader,
      TableCell,
      SlashCommands,
    ],
    editorProps: {
      attributes: { spellcheck: 'true' },
    },
    onUpdate({ editor }) {
      if (!isLoadingContent) scheduleNotify(editor)
    },
    onSelectionUpdate({ editor }) { syncToolbar(editor) },
    onTransaction({ editor })    { syncToolbar(editor) },
  })

  bindToolbar(editor)
  postToSwift({ type: 'ready' })
}

function scheduleNotify(editor) {
  clearTimeout(notifyTimer)
  notifyTimer = setTimeout(() => {
    postToSwift({ type: 'contentChanged', markdown: editor.storage.markdown.getMarkdown() })
  }, 300)
}

// ─── Public API (called by Swift via callAsyncJavaScript) ────────────────────

window.gitfluence = {
  loadDocument(markdown) {
    if (!editor) return
    isLoadingContent = true
    editor.commands.setContent(markdown, /* emitUpdate */ false)
    isLoadingContent = false
    editor.view.dom.scrollTop = 0
  },

  getMarkdown() {
    return editor ? editor.storage.markdown.getMarkdown() : ''
  },

  setReadOnly(readonly) {
    editor?.setEditable(!readonly)
    const tb = document.getElementById('toolbar')
    if (tb) tb.hidden = readonly
  },

  focus() {
    editor?.commands.focus()
  },
}

// ─── Boot ─────────────────────────────────────────────────────────────────────

document.addEventListener('DOMContentLoaded', initEditor)
