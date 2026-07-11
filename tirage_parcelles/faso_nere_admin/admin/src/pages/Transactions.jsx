/* eslint-disable react/prop-types, react/no-unescaped-entities */
// src/pages/Transactions.jsx
import { useEffect, useState, useCallback } from 'react'
import { Download, Check, X as XIcon, TrendingUp, TrendingDown } from 'lucide-react'
import toast from 'react-hot-toast'
import { AreaChart, Area, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid, BarChart, Bar } from 'recharts'
import api from '../api/client'
import { fmt, fmtDateTime, txColor, methodLabel } from '../utils/format'
import {
  PageHeader, Card, Table, Pagination, Badge,
  Select, Button, PageLoader, Modal, Input,
} from '../components/UI'

const STATUTS = [
  { value: '',          label: 'Tous statuts'    },
  { value: 'success',   label: '✅ Succès'        },
  { value: 'pending',   label: '⏳ En attente'    },
  { value: 'failed',    label: '❌ Échoué'        },
  { value: 'cancelled', label: '🚫 Annulé'        },
  { value: 'refunded',  label: '↩️ Remboursé'     },
]

const METHODES = [
  { value: '',               label: 'Toutes méthodes'      },
  { value: 'orange_money',   label: 'Orange Money BF'      },
  { value: 'mtn_money',      label: 'MTN Money BF'         },
  { value: 'moov_money',     label: 'Moov Money BF'        },
  { value: 'mtn_ci',         label: 'MTN Mobile Money CI'  },
  { value: 'orange_ci',      label: 'Orange Money CI'      },
  { value: 'carte_bancaire', label: 'Carte bancaire'       },
]

const TYPES = [
  { value: '',        label: 'Tous types'      },
  { value: 'depot',   label: '📥 Dépôts'        },
  { value: 'retrait', label: '💸 Retraits'      },
  { value: 'pack',    label: '📦 Achats Pack'   },
]

// Custom Tooltip pour Recharts
const CustomTooltip = ({ active, payload, label }) => {
  if (active && payload && payload.length) {
    return (
      <div className="bg-surface2/95 border border-border/50 p-3 rounded-lg shadow-xl backdrop-blur-sm">
        <p className="text-gray-400 text-xs mb-1">{label}</p>
        <p className="text-white font-bold text-lg">
          {fmt(payload[0].value)} FCFA
        </p>
      </div>
    );
  }
  return null;
};

export default function Transactions() {
  const [txs,        setTxs]        = useState([])
  const [pagination, setPagination] = useState({ page: 1, pages: 1, total: 0, limit: 20 })
  const [loading,    setLoading]    = useState(true)
  const [statsLoading, setStatsLoading] = useState(true)
  const [stats,      setStats]      = useState(null)
  
  // Filtres
  const [activeTab,  setActiveTab]  = useState('all') // 'all' | 'depot' | 'retrait'
  const [statut,     setStatut]     = useState('')
  const [methode,    setMethode]    = useState('')
  const [type,       setType]       = useState('')

  // Modal actions
  const [selectedTx, setSelectedTx] = useState(null)
  const [actionType, setActionType] = useState('') // 'approve' | 'reject'
  const [noteAdmin,  setNoteAdmin]  = useState('')
  const [actionLoading, setActionLoading] = useState(false)

  const loadStats = useCallback(async () => {
    setStatsLoading(true)
    try {
      const { data } = await api.get('/admin/transactions/stats')
      setStats(data)
    } catch { 
      toast.error('Erreur chargement des statistiques')
    } finally {
      setStatsLoading(false)
    }
  }, [])

  const loadTxs = useCallback(async (page = 1) => {
    setLoading(true)
    try {
      // Si on utilise l'onglet, on force le type
      let currentType = type;
      if (activeTab === 'depot') currentType = 'depot';
      if (activeTab === 'retrait') currentType = 'retrait';

      const params = new URLSearchParams({
        page, limit: 20,
        ...(statut  && { statut  }),
        ...(methode && { methode }),
        ...(currentType && { type: currentType }),
      })
      const { data } = await api.get(`/admin/transactions?${params}`)
      setTxs(data.transactions)
      setPagination(data.pagination)
    } catch { toast.error('Erreur chargement transactions') }
    finally  { setLoading(false) }
  }, [statut, methode, type, activeTab])

  useEffect(() => { 
    loadTxs(1) 
  }, [loadTxs])

  useEffect(() => {
    loadStats()
  }, [loadStats])

  const openActionModal = (tx, actType) => {
    setSelectedTx(tx)
    setActionType(actType)
    setNoteAdmin(tx.note_admin ?? '')
  }

  const handleActionSubmit = async () => {
    if (!selectedTx) return
    setActionLoading(true)
    try {
      if (actionType === 'approve') {
        await api.post(`/admin/transactions/${selectedTx.id}/payer-pawapay`)
        toast.success('Paiement PawaPay initié avec succès')
      } else {
        await api.put(`/admin/transactions/${selectedTx.id}/statut`, {
          statut: 'failed',
          note_admin: noteAdmin,
        })
        toast.success('Retrait rejeté')
      }
      setSelectedTx(null)
      setNoteAdmin('')
      loadTxs(pagination.page)
    } catch (err) {
      toast.error(err.response?.data?.detail ?? 'Erreur lors de la validation')
    } finally {
      setActionLoading(false)
    }
  }

  const getTxTypeBadge = (tx) => {
    const op = tx.metadata?.operation;
    if (op === 'pack' || tx.pack_tentatives || tx.reference?.startsWith('PACK-')) {
      return <Badge className="text-purple-400 border-purple-500/30 bg-purple-500/10">📦 Pack</Badge>
    }
    if (op === 'depot' || tx.reference?.startsWith('DEP-')) {
      return <Badge className="text-blue-400 border-blue-500/30 bg-blue-500/10">📥 Dépôt</Badge>
    }
    if (op === 'souscription' || tx.reference?.startsWith('SOUS-')) {
      return <Badge className="text-emerald-400 border-emerald-500/30 bg-emerald-500/10">🎟️ Souscription</Badge>
    }
    // L'identifiant de retrait peut être un UUID, donc si ce n'est ni pack ni dépot explicitement :
    if (op === 'retrait' || tx.reference?.startsWith('RET-') || tx.reference?.length === 36) {
      return <Badge className="text-orange-400 border-orange-500/30 bg-orange-500/10">💸 Retrait</Badge>
    }
    return <Badge className="text-gray-400 border-gray-500/30 bg-gray-500/5">Autre</Badge>
  }

  // Export CSV
  const exportCSV = () => {
    const headers = ['Date', 'Joueur', 'Téléphone', 'Type', 'Montant', 'Méthode',
                     'Statut', 'Référence', 'Note Admin', 'Tentatives']
    const rows = txs.map(tx => {
      let tType = 'Autre'
      const op = tx.metadata?.operation;
      if (op === 'pack' || tx.pack_tentatives || tx.reference?.startsWith('PACK-')) tType = 'Pack'
      else if (op === 'depot' || tx.reference?.startsWith('DEP-')) tType = 'Dépôt'
      else if (op === 'souscription' || tx.reference?.startsWith('SOUS-')) tType = 'Souscription'
      else if (op === 'retrait' || tx.reference?.startsWith('RET-') || tx.reference?.length === 36) tType = 'Retrait'

      return [
        fmtDateTime(tx.created_at),
        `${tx.nom} ${tx.prenom}`,
        tx.user_telephone,
        tType,
        tx.montant,
        methodLabel(tx.methode),
        tx.statut,
        tx.reference ?? '',
        tx.note_admin ?? '',
        tx.tentatives_ajout,
      ]
    })
    const csv = [headers, ...rows]
      .map(r => r.map(v => `"${v}"`).join(','))
      .join('\n')
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' })
    const url  = URL.createObjectURL(blob)
    const a    = document.createElement('a')
    a.href = url; a.download = 'transactions.csv'; a.click()
    URL.revokeObjectURL(url)
  }

  return (
    <div className="p-6 space-y-6">
      <PageHeader
        title="Transactions & Retraits"
        subtitle={`${fmt(pagination.total)} transactions enregistrées`}
        actions={
          <Button variant="secondary" onClick={exportCSV}>
            <Download size={14} /> Exporter CSV
          </Button>
        }
      />

      {/* Résumé Global (provenant des stats serveur) */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        {[
          { label: 'Entrées Réelles (Dépôts + Packs)', value: stats ? `${fmt(stats.total_entrees)} F` : '...', color: 'text-green-400', sub: stats ? `Dépôts: ${fmt(stats.total_depots_reel)} F | Packs: ${fmt(stats.total_packs_reel)} F` : '' },
          { label: 'Total Sorties (Retraits)', value: stats ? `${fmt(stats.total_sorties)} F` : '...', color: 'text-orange-400', sub: 'Montants payés' },
          { label: 'Frais Estimés (PawaPay)', value: stats ? `-${fmt(stats.frais_estimes)} F` : '...', color: 'text-red-400', sub: '~2% entrées, ~1% sorties' },
          { label: 'Bénéfice Net Estimé', value: stats ? `${fmt(stats.benefice_net)} F` : '...', color: stats && stats.benefice_net >= 0 ? 'text-green-500' : 'text-red-500', sub: 'Marge dégagée' },
        ].map(({ label, value, color, sub }, i) => (
          <Card key={i} className="p-4 bg-surface2/40 border-border/50 shadow-lg">
            <p className="text-xs text-gray-400 mb-1 font-semibold uppercase tracking-wider">{label}</p>
            <p className={`text-2xl font-black ${color}`}>{value}</p>
            {sub && <p className="text-[10px] text-gray-500 mt-2">{sub}</p>}
          </Card>
        ))}
      </div>

      {/* Graphiques Dépôts vs Retraits (30 jours) */}
      {!statsLoading && stats && (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <Card className="p-5">
            <div className="flex items-center justify-between mb-4">
              <div>
                <h3 className="text-white font-bold text-lg flex items-center gap-2">
                  <TrendingUp className="text-green-400" size={20} />
                  Entrées d'argent (30 jours)
                </h3>
                <p className="text-xs text-gray-400">Évolution des entrées (Dépôts + Packs)</p>
              </div>
            </div>
            <div className="h-64 w-full">
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={stats.depots_chart}>
                  <defs>
                    <linearGradient id="colorDepot" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#4ade80" stopOpacity={0.3} />
                      <stop offset="95%" stopColor="#4ade80" stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" stroke="#ffffff10" vertical={false} />
                  <XAxis dataKey="date" stroke="#ffffff50" fontSize={12} tickFormatter={(str) => str.slice(5, 10)} />
                  <YAxis stroke="#ffffff50" fontSize={12} width={60} tickFormatter={(val) => `${val/1000}k`} />
                  <Tooltip content={<CustomTooltip />} />
                  <Area type="monotone" dataKey="total" stroke="#4ade80" strokeWidth={3} fillOpacity={1} fill="url(#colorDepot)" />
                </AreaChart>
              </ResponsiveContainer>
            </div>
          </Card>

          <Card className="p-5">
            <div className="flex items-center justify-between mb-4">
              <div>
                <h3 className="text-white font-bold text-lg flex items-center gap-2">
                  <TrendingDown className="text-orange-400" size={20} />
                  Retraits (30 jours)
                </h3>
                <p className="text-xs text-gray-400">Évolution des sorties d'argent</p>
              </div>
            </div>
            <div className="h-64 w-full">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={stats.retraits_chart}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#ffffff10" vertical={false} />
                  <XAxis dataKey="date" stroke="#ffffff50" fontSize={12} tickFormatter={(str) => str.slice(5, 10)} />
                  <YAxis stroke="#ffffff50" fontSize={12} width={60} tickFormatter={(val) => `${val/1000}k`} />
                  <Tooltip content={<CustomTooltip />} />
                  <Bar dataKey="total" fill="#fb923c" radius={[4, 4, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </Card>
        </div>
      )}

      {/* Onglets Dépôts / Retraits */}
      <div className="flex gap-2 border-b border-border/50 pb-2">
        {[
          { id: 'all', label: 'Toutes les transactions' },
          { id: 'depot', label: '📥 Dépôts & Packs' },
          { id: 'retrait', label: '💸 Retraits Uniquement' }
        ].map(tab => (
          <button
            key={tab.id}
            onClick={() => {
              setActiveTab(tab.id);
              setType(''); // Réinitialiser le select si on utilise les onglets
            }}
            className={`px-4 py-2 rounded-t-lg text-sm font-semibold transition-colors ${
              activeTab === tab.id
                ? 'bg-primary text-white border-b-2 border-white'
                : 'text-gray-400 hover:text-white hover:bg-surface2'
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* Filtres (Cachés ou affichés dynamiquement selon l'onglet) */}
      <div className="flex flex-wrap gap-3 mt-4">
        {activeTab === 'all' && (
          <Select value={type} onChange={e => setType(e.target.value)}
            options={TYPES} className="w-48" />
        )}
        <Select value={statut}  onChange={e => setStatut(e.target.value)}
          options={STATUTS}  className="w-48" />
        <Select value={methode} onChange={e => setMethode(e.target.value)}
          options={METHODES} className="w-48" />
      </div>

      <Card>
        {loading ? <PageLoader /> : (
          <>
            <Table headers={['Date', 'Joueur', 'Type', 'Montant', 'Méthode',
                             'Statut', 'Référence', 'Note Admin', 'Actions']}>
              {txs.map(tx => (
                <tr key={tx.id}
                  className="border-b border-border/50 hover:bg-surface2/50 transition-colors">

                  <td className="px-4 py-3 text-xs text-gray-400 whitespace-nowrap">
                    {fmtDateTime(tx.created_at)}
                  </td>

                  <td className="px-4 py-3">
                    <p className="text-sm font-semibold text-white">
                      {tx.nom} {tx.prenom}
                    </p>
                    <p className="text-xs text-gray-500">{tx.user_telephone}</p>
                  </td>

                  <td className="px-4 py-3">
                    {getTxTypeBadge(tx)}
                  </td>

                  <td className="px-4 py-3 text-sm font-bold text-gold whitespace-nowrap">
                    {fmt(tx.montant)} FCFA
                  </td>

                  <td className="px-4 py-3 text-sm text-gray-300">
                    {methodLabel(tx.methode)}
                  </td>

                  <td className="px-4 py-3">
                    <Badge className={txColor(tx.statut)}>
                      {tx.statut}
                    </Badge>
                  </td>

                  <td className="px-4 py-3 text-xs text-gray-500 font-mono">
                    {tx.reference ?? '—'}
                  </td>

                  <td className="px-4 py-3 text-xs text-gray-400 italic max-w-xs truncate">
                    {tx.note_admin ?? '—'}
                  </td>

                  <td className="px-4 py-3 whitespace-nowrap">
                    {tx.statut === 'pending' && (tx.reference?.startsWith('RET-') || tx.reference?.length === 36) ? (
                      <div className="flex gap-2">
                        <Button
                          variant="primary"
                          size="sm"
                          onClick={() => openActionModal(tx, 'approve')}
                          className="!px-2.5 !py-1 text-xs"
                          title="Payer via PawaPay"
                        >
                          <Check size={14} /> Payer PawaPay
                        </Button>
                        <Button
                          variant="danger"
                          size="sm"
                          onClick={() => openActionModal(tx, 'reject')}
                          className="!px-2.5 !py-1 text-xs"
                          title="Rejeter"
                        >
                          <XIcon size={14} /> Rejeter
                        </Button>
                      </div>
                    ) : (
                      <span className="text-gray-600 text-xs">—</span>
                    )}
                  </td>
                </tr>
              ))}
            </Table>
            <Pagination
              page={pagination.page}
              pages={pagination.pages}
              total={pagination.total}
              limit={pagination.limit}
              onPage={loadTxs}
            />
          </>
        )}
      </Card>

      {/* Modal de validation / rejet */}
      <Modal
        open={!!selectedTx}
        onClose={() => setSelectedTx(null)}
        title={actionType === 'approve' ? '💰 Payer via PawaPay' : '❌ Rejeter le retrait'}
        footer={
          <div className="flex gap-3 justify-end">
            <Button variant="secondary" onClick={() => setSelectedTx(null)}>
              Annuler
            </Button>
            <Button
              variant={actionType === 'approve' ? 'primary' : 'danger'}
              onClick={handleActionSubmit}
              loading={actionLoading}
            >
              {actionType === 'approve' ? 'Confirmer le paiement PawaPay' : 'Confirmer le rejet'}
            </Button>
          </div>
        }
      >
        {selectedTx && (
          <div className="space-y-4 text-sm text-gray-300">
            <p>
              Vous êtes sur le point de {actionType === 'approve' ? 'déclencher un transfert d\'argent RÉEL via PawaPay pour' : 'rejeter'} la demande de retrait suivante :
            </p>
            <div className="bg-surface2 p-4 rounded-xl border border-border space-y-2 font-medium">
              <div>
                <span className="text-gray-400 text-xs">Joueur :</span>{' '}
                <span className="text-white">{selectedTx.nom} {selectedTx.prenom}</span> ({selectedTx.user_telephone})
              </div>
              <div>
                <span className="text-gray-400 text-xs">Montant :</span>{' '}
                <span className="text-gold font-bold">{fmt(selectedTx.montant)} FCFA</span>
              </div>
              <div>
                <span className="text-gray-400 text-xs">Méthode de réception :</span>{' '}
                <span className="text-white">{methodLabel(selectedTx.methode)}</span> ({selectedTx.telephone_paiement ?? 'N/A'})
              </div>
              <div>
                <span className="text-gray-400 text-xs">Référence :</span>{' '}
                <span className="text-gray-400 font-mono text-xs">{selectedTx.reference}</span>
              </div>
            </div>

            {actionType !== 'approve' && (
              <Input
                label="Note interne / Raison"
                placeholder="Ex: Suspicion de fraude / Solde invalide."
                value={noteAdmin}
                onChange={e => setNoteAdmin(e.target.value)}
              />
            )}
          </div>
        )}
      </Modal>
    </div>
  )
}