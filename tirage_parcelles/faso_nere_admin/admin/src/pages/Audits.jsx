// src/pages/Audit.jsx
import { useEffect, useState, useCallback } from 'react'
import { Shield } from 'lucide-react'
import toast from 'react-hot-toast'
import api from '../api/client'
import { fmtDateTime } from '../utils/format'
import {
  PageHeader, Card, Table, Pagination,
  Badge, PageLoader,
} from '../components/UI'

const ACTION_COLORS = {
  login:                'bg-blue-500/10   text-blue-400   border-blue-500/30',
  logout:               'bg-gray-500/10   text-gray-400   border-gray-500/30',
  inscription:          'bg-green-500/10  text-green-400  border-green-500/30',
  verification_otp:     'bg-purple-500/10 text-purple-400 border-purple-500/30',
  achat_pack:           'bg-gold/10       text-gold       border-gold/30',
  tirage:               'bg-indigo-500/10 text-indigo-400 border-indigo-500/30',
  depot:                'bg-green-500/10  text-green-400  border-green-500/30',
  retrait:              'bg-orange-500/10 text-orange-400 border-orange-500/30',
  modification_profil:  'bg-cyan-500/10   text-cyan-400   border-cyan-500/30',
  suspension_compte:    'bg-red-500/10    text-red-400    border-red-500/30',
  activation_compte:    'bg-green-500/10  text-green-400  border-green-500/30',
  ajustement_admin:     'bg-yellow-500/10 text-yellow-400 border-yellow-500/30',
  modif_cadeau:         'bg-pink-500/10   text-pink-400   border-pink-500/30',
  modif_lot:            'bg-pink-500/10   text-pink-400   border-pink-500/30',
  notification_admin:   'bg-blue-500/10   text-blue-400   border-blue-500/30',
  mise_a_jour_livraison:'bg-teal-500/10   text-teal-400   border-teal-500/30',
  mise_a_jour_config:   'bg-violet-500/10 text-violet-400 border-violet-500/30',
  credit_tentatives:    'bg-gold/10       text-gold       border-gold/30',
}

const ACTION_ICONS = {
  login:                '🔐',
  logout:               '🚪',
  inscription:          '✍️',
  verification_otp:     '📱',
  achat_pack:           '🎟️',
  tirage:               '🎲',
  depot:                '💵',
  retrait:              '💸',
  modification_profil:  '✏️',
  suspension_compte:    '🚫',
  activation_compte:    '✅',
  ajustement_admin:     '⚙️',
  modif_cadeau:         '🎁',
  modif_lot:            '📦',
  notification_admin:   '📢',
  mise_a_jour_livraison:'🚚',
  mise_a_jour_config:   '🔧',
  credit_tentatives:    '🎫',
}

export default function Audit() {
  const [logs,       setLogs]       = useState([])
  const [pagination, setPagination] = useState({ page: 1, pages: 1, total: 0, limit: 50 })
  const [loading,    setLoading]    = useState(true)
  const [expanded,   setExpanded]   = useState(null)

  const loadLogs = useCallback(async (page = 1) => {
    setLoading(true)
    try {
      const { data } = await api.get(`/admin/audit?page=${page}&limit=50`)
      setLogs(data.logs ?? data.audit ?? [])
      setPagination(data.pagination ?? {
        page,
        limit: 50,
        total: (data.logs ?? data.audit ?? []).length,
        pages: 1,
      })
    } catch { toast.error('Erreur chargement audit') }
    finally  { setLoading(false) }
  }, [])

  useEffect(() => { loadLogs(1) }, [loadLogs])

  return (
    <div className="p-6 space-y-6">
      <PageHeader
        title="Journal d'audit"
        subtitle="Trace de toutes les actions sensibles"
        actions={
          <div className="flex items-center gap-2 bg-surface2 border border-border
                          rounded-xl px-3 py-2">
            <Shield size={14} className="text-gold" />
            <span className="text-xs text-gray-400">
              {pagination.total} événements enregistrés
            </span>
          </div>
        }
      />

      <Card>
        {loading ? <PageLoader /> : (
          <>
            <Table headers={['Heure', 'Utilisateur', 'Action', 'Admin', 'IP', 'Détails']}>
              {logs.map(log => (
                <>
                  <tr key={log.id}
                    className="border-b border-border/50 hover:bg-surface2/50
                               transition-colors cursor-pointer"
                    onClick={() => setExpanded(expanded === log.id ? null : log.id)}>

                    <td className="px-4 py-3 text-xs text-gray-500 whitespace-nowrap">
                      {fmtDateTime(log.created_at)}
                    </td>

                    <td className="px-4 py-3">
                      {log.user_nom ? (
                        <p className="text-sm text-white font-medium">
                          {log.user_nom} {log.user_prenom}
                        </p>
                      ) : (
                        <span className="text-gray-500 text-sm">—</span>
                      )}
                    </td>

                    <td className="px-4 py-3">
                      <Badge className={ACTION_COLORS[log.action] ?? 'bg-gray-500/10 text-gray-400 border-gray-500/30'}>
                        {ACTION_ICONS[log.action] ?? '•'} {log.action?.replace(/_/g, ' ')}
                      </Badge>
                    </td>

                    <td className="px-4 py-3 text-sm text-gray-400">
                      {log.admin_nom
                        ? `${log.admin_nom} ${log.admin_prenom}`
                        : '—'}
                    </td>

                    <td className="px-4 py-3 text-xs text-gray-500 font-mono">
                      {log.ip_address ?? '—'}
                    </td>

                    <td className="px-4 py-3 text-xs text-gray-500">
                      {log.details
                        ? <span className="text-gold hover:text-yellow-300 transition-colors">
                            {expanded === log.id ? '▲ Masquer' : '▼ Voir'}
                          </span>
                        : '—'}
                    </td>
                  </tr>

                  {/* Ligne expandée avec les détails JSON */}
                  {expanded === log.id && log.details && (
                    <tr key={`${log.id}-detail`}
                      className="bg-surface2/50 border-b border-border/50">
                      <td colSpan={6} className="px-4 py-3">
                        <pre className="text-xs text-gray-300 bg-bg rounded-xl p-3
                                        overflow-x-auto font-mono">
                          {JSON.stringify(log.details, null, 2)}
                        </pre>
                      </td>
                    </tr>
                  )}
                </>
              ))}
            </Table>
            <Pagination
              page={pagination.page}
              pages={pagination.pages}
              total={pagination.total}
              limit={pagination.limit}
              onPage={loadLogs}
            />
          </>
        )}
      </Card>
    </div>
  )
}