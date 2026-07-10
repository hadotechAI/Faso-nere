// src/components/UI.jsx — composants réutilisables
import clsx from 'clsx'
import { Loader2, ChevronLeft, ChevronRight } from 'lucide-react'

// ── Spinner ───────────────────────────────────────────────────
export function Spinner({ size = 24, className = '' }) {
  return (
    <Loader2
      size={size}
      className={clsx('animate-spin text-gold', className)}
    />
  )
}

// ── Page loader ───────────────────────────────────────────────
export function PageLoader() {
  return (
    <div className="flex items-center justify-center min-h-96">
      <Spinner size={32} />
    </div>
  )
}

// ── Badge ─────────────────────────────────────────────────────
export function Badge({ children, className = '' }) {
  return (
    <span className={clsx(
      'inline-flex items-center px-2 py-0.5 rounded-lg text-xs font-bold border',
      className
    )}>
      {children}
    </span>
  )
}

// ── Bouton principal ──────────────────────────────────────────
export function Button({
  children, onClick, disabled, loading,
  variant = 'primary', size = 'md', className = '',
}) {
  const base = 'inline-flex items-center justify-center gap-2 font-bold rounded-xl transition-all'
  const variants = {
    primary:   'bg-gold hover:bg-yellow-400 text-bg',
    secondary: 'bg-surface2 hover:bg-card text-white border border-border',
    danger:    'bg-red-500/10 hover:bg-red-500/20 text-red-400 border border-red-500/30',
    ghost:     'hover:bg-surface2 text-gray-400 hover:text-white',
  }
  const sizes = {
    sm: 'px-3 py-1.5 text-xs',
    md: 'px-4 py-2 text-sm',
    lg: 'px-6 py-3 text-base',
  }

  return (
    <button
      onClick={onClick}
      disabled={disabled || loading}
      className={clsx(base, variants[variant], sizes[size],
        (disabled || loading) && 'opacity-50 cursor-not-allowed',
        className)}
    >
      {loading && <Spinner size={14} />}
      {children}
    </button>
  )
}

// ── Input ─────────────────────────────────────────────────────
export function Input({
  label, value, onChange, placeholder, type = 'text',
  error, className = '', ...props
}) {
  return (
    <div className={clsx('space-y-1.5', className)}>
      {label && (
        <label className="text-sm font-semibold text-gray-300 block">
          {label}
        </label>
      )}
      <input
        type={type}
        value={value}
        onChange={onChange}
        placeholder={placeholder}
        className={clsx(
          'w-full bg-surface2 border rounded-xl px-3 py-2.5 text-white',
          'placeholder-gray-500 focus:outline-none transition-colors text-sm',
          error ? 'border-red-500' : 'border-border focus:border-gold'
        )}
        {...props}
      />
      {error && <p className="text-xs text-red-400">{error}</p>}
    </div>
  )
}

// ── Select ────────────────────────────────────────────────────
export function Select({ label, value, onChange, options, className = '' }) {
  return (
    <div className={clsx('space-y-1.5', className)}>
      {label && (
        <label className="text-sm font-semibold text-gray-300 block">
          {label}
        </label>
      )}
      <select
        value={value}
        onChange={onChange}
        className="w-full bg-surface2 border border-border rounded-xl px-3 py-2.5
                   text-white focus:outline-none focus:border-gold transition-colors
                   text-sm"
      >
        {options.map(({ value: v, label: l }) => (
          <option key={v} value={v}>{l}</option>
        ))}
      </select>
    </div>
  )
}

// ── Modal ─────────────────────────────────────────────────────
export function Modal({ open, onClose, title, children, footer }) {
  if (!open) return null
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/60 backdrop-blur-sm"
           onClick={onClose} />
      <div className="relative bg-surface border border-border rounded-2xl
                      w-full max-w-lg max-h-[90vh] overflow-y-auto z-10">
        {/* Header */}
        <div className="flex items-center justify-between p-5 border-b border-border">
          <h3 className="font-bold text-white text-lg">{title}</h3>
          <button onClick={onClose}
            className="text-gray-500 hover:text-white transition-colors text-xl">
            ✕
          </button>
        </div>
        {/* Body */}
        <div className="p-5">{children}</div>
        {/* Footer */}
        {footer && (
          <div className="flex justify-end gap-3 p-5 border-t border-border">
            {footer}
          </div>
        )}
      </div>
    </div>
  )
}

// ── Table ─────────────────────────────────────────────────────
export function Table({ headers, children, empty = 'Aucune donnée' }) {
  return (
    <div className="overflow-x-auto">
      <table className="w-full text-sm">
        <thead>
          <tr className="border-b border-border">
            {headers.map(h => (
              <th key={h}
                className="text-left px-4 py-3 text-xs font-bold
                           text-gray-400 uppercase tracking-wider whitespace-nowrap">
                {h}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {children || (
            <tr>
              <td colSpan={headers.length}
                className="text-center py-12 text-gray-500">
                {empty}
              </td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  )
}

// ── Pagination ────────────────────────────────────────────────
export function Pagination({ page, pages, total, limit, onPage }) {
  if (pages <= 1) return null
  return (
    <div className="flex items-center justify-between px-4 py-3
                    border-t border-border text-sm text-gray-400">
      <span>
        {((page - 1) * limit) + 1}–{Math.min(page * limit, total)} sur {total}
      </span>
      <div className="flex items-center gap-1">
        <button
          onClick={() => onPage(page - 1)}
          disabled={page <= 1}
          className="p-1.5 rounded-lg hover:bg-surface2 disabled:opacity-40
                     disabled:cursor-not-allowed transition-colors"
        >
          <ChevronLeft size={16} />
        </button>
        {Array.from({ length: Math.min(5, pages) }, (_, i) => {
          const p = page <= 3
            ? i + 1
            : page >= pages - 2
              ? pages - 4 + i
              : page - 2 + i
          if (p < 1 || p > pages) return null
          return (
            <button key={p} onClick={() => onPage(p)}
              className={clsx(
                'w-8 h-8 rounded-lg text-xs font-bold transition-colors',
                p === page
                  ? 'bg-gold text-bg'
                  : 'hover:bg-surface2 text-gray-400'
              )}>
              {p}
            </button>
          )
        })}
        <button
          onClick={() => onPage(page + 1)}
          disabled={page >= pages}
          className="p-1.5 rounded-lg hover:bg-surface2 disabled:opacity-40
                     disabled:cursor-not-allowed transition-colors"
        >
          <ChevronRight size={16} />
        </button>
      </div>
    </div>
  )
}

// ── Page header ───────────────────────────────────────────────
export function PageHeader({ title, subtitle, actions }) {
  return (
    <div className="flex items-start justify-between mb-6">
      <div>
        <h1 className="text-2xl font-black text-white">{title}</h1>
        {subtitle && (
          <p className="text-gray-400 text-sm mt-1">{subtitle}</p>
        )}
      </div>
      {actions && (
        <div className="flex items-center gap-3">{actions}</div>
      )}
    </div>
  )
}

// ── Card ──────────────────────────────────────────────────────
export function Card({ children, className = '' }) {
  return (
    <div className={clsx(
      'bg-surface border border-border rounded-2xl',
      className
    )}>
      {children}
    </div>
  )
}

// ── Search input ──────────────────────────────────────────────
export function SearchInput({ value, onChange, placeholder = 'Rechercher...' }) {
  return (
    <div className="relative">
      <span className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-500 text-sm">
        🔍
      </span>
      <input
        type="text"
        value={value}
        onChange={e => onChange(e.target.value)}
        placeholder={placeholder}
        className="bg-surface2 border border-border rounded-xl pl-9 pr-4 py-2
                   text-white placeholder-gray-500 focus:outline-none
                   focus:border-gold transition-colors text-sm w-64"
      />
    </div>
  )
}

// ── Confirm dialog ────────────────────────────────────────────
export function ConfirmDialog({ open, onClose, onConfirm, title, message, loading }) {
  return (
    <Modal open={open} onClose={onClose} title={title}
      footer={<>
        <Button variant="secondary" onClick={onClose}>Annuler</Button>
        <Button variant="danger" onClick={onConfirm} loading={loading}>
          Confirmer
        </Button>
      </>}
    >
      <p className="text-gray-300">{message}</p>
    </Modal>
  )
}