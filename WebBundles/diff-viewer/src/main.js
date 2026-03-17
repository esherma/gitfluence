import { html } from 'diff2html'
import 'diff2html/bundles/css/diff2html.min.css'

// ─── Bridge ──────────────────────────────────────────────────────────────────

function postToSwift(msg) {
  window.webkit?.messageHandlers?.editorBridge?.postMessage(msg)
}

// ─── State ────────────────────────────────────────────────────────────────────

const root = () => document.getElementById('root')
let floatBtn = null
let hoverRow = null

// ─── Diff rendering ───────────────────────────────────────────────────────────

function renderDiff(unifiedDiff) {
  const el = root()
  if (!unifiedDiff?.trim()) {
    el.innerHTML = '<div class="empty-state">No changes in working tree.</div>'
    floatBtn && (floatBtn.style.display = 'none')
    return
  }
  el.innerHTML = html(unifiedDiff, {
    drawFileList: false,
    matching: 'lines',
    outputFormat: 'line-by-line',
    renderNothingWhenEmpty: false,
  })
  setupHoverCommentBtn(el)
}

// ─── Floating comment button ──────────────────────────────────────────────────

function setupHoverCommentBtn(el) {
  if (!floatBtn) {
    floatBtn = document.createElement('button')
    floatBtn.className = 'comment-add-btn'
    floatBtn.setAttribute('title', 'Add comment')
    floatBtn.innerHTML = '<svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M2 2h12v9H9l-3 3v-3H2z"/><line x1="5" y1="6" x2="11" y2="6"/><line x1="5" y1="8.5" x2="8" y2="8.5"/></svg>'
    floatBtn.addEventListener('click', handleCommentClick)
    document.body.appendChild(floatBtn)
  }

  el.addEventListener('mouseover', e => {
    const row = e.target.closest('tr.d2h-ins, tr.d2h-del, tr.d2h-cntx')
    if (!row || row === hoverRow) return
    hoverRow = row
    const rect = row.getBoundingClientRect()
    floatBtn.style.top  = `${rect.top + window.scrollY + Math.max(0, (rect.height - 20) / 2)}px`
    floatBtn.style.display = 'flex'
  })

  el.addEventListener('mouseleave', () => {
    hoverRow = null
    if (floatBtn) floatBtn.style.display = 'none'
  })

  floatBtn.addEventListener('mouseenter', () => { /* keep visible while hovering btn */ })
  floatBtn.addEventListener('mouseleave', () => {
    hoverRow = null
    floatBtn.style.display = 'none'
  })
}

function handleCommentClick() {
  if (!hoverRow) return
  const { filePath, lineNumber, side } = getRowInfo(hoverRow)
  if (filePath && lineNumber) {
    postToSwift({ type: 'commentRequest', filePath, lineNumber, side })
  }
}

function getRowInfo(row) {
  const fileWrapper = row.closest('.d2h-file-wrapper')
  const filePath = fileWrapper?.querySelector('.d2h-file-name')?.textContent?.trim() ?? ''
  const isDel = row.classList.contains('d2h-del')
  const numEl = isDel
    ? row.querySelector('.line-num1')
    : row.querySelector('.line-num2')
  const lineNumber = parseInt(numEl?.textContent?.trim() ?? '0')
  return {
    filePath,
    lineNumber: isNaN(lineNumber) || lineNumber === 0 ? null : lineNumber,
    side: isDel ? 'LEFT' : 'RIGHT',
  }
}

// ─── Comment rendering ────────────────────────────────────────────────────────

function renderComments(comments) {
  if (!comments?.length) return
  const el = root()
  comments.forEach(c => {
    if (!c.path || !c.line) return
    const row = findRow(el, c.path, c.line, c.side ?? 'RIGHT')
    if (!row) return
    // Don't add duplicate
    if (row.nextSibling?.classList?.contains('comment-row')) return
    row.after(makeCommentRow(c))
  })
}

function findRow(el, filePath, lineNumber, side) {
  for (const wrapper of el.querySelectorAll('.d2h-file-wrapper')) {
    const name = wrapper.querySelector('.d2h-file-name')?.textContent?.trim() ?? ''
    if (!name) continue
    if (name !== filePath && !name.endsWith('/' + filePath) && !filePath.endsWith(name)) continue
    const numClass = side === 'LEFT' ? '.line-num1' : '.line-num2'
    for (const row of wrapper.querySelectorAll('tr')) {
      if (row.querySelector(numClass)?.textContent?.trim() === String(lineNumber)) {
        return row
      }
    }
  }
  return null
}

function makeCommentRow(c) {
  const tr = document.createElement('tr')
  tr.className = 'comment-row'
  tr.innerHTML = `
    <td class="d2h-code-linenumber comment-linenumber"></td>
    <td class="comment-cell">
      <div class="comment-thread">
        <div class="comment-meta">
          <span class="comment-author">@${esc(c.user?.login ?? 'unknown')}</span>
          <span class="comment-date">${fmtDate(c.created_at ?? '')}</span>
        </div>
        <div class="comment-body">${esc(c.body ?? '')}</div>
      </div>
    </td>`
  return tr
}

function esc(s) {
  return String(s)
    .replace(/&/g, '&amp;').replace(/</g, '&lt;')
    .replace(/>/g, '&gt;').replace(/"/g, '&quot;')
    .replace(/\n/g, '<br>')
}

function fmtDate(iso) {
  if (!iso) return ''
  try {
    return new Date(iso).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
  } catch { return iso }
}

// ─── Public API ───────────────────────────────────────────────────────────────

window.gitfluence = {
  loadDiff(unifiedDiff) {
    renderDiff(unifiedDiff)
  },

  loadComments(commentsJson) {
    try {
      const comments = typeof commentsJson === 'string'
        ? JSON.parse(commentsJson) : commentsJson
      renderComments(comments)
    } catch (e) {
      console.error('loadComments parse error:', e)
    }
  },

  appendComment(commentJson) {
    try {
      const c = typeof commentJson === 'string' ? JSON.parse(commentJson) : commentJson
      if (c) renderComments([c])
    } catch {}
  },
}

// ─── Boot ─────────────────────────────────────────────────────────────────────

document.addEventListener('DOMContentLoaded', () => {
  postToSwift({ type: 'ready' })
})
