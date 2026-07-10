// src/pages/Joueurs.jsx
import { useEffect, useState, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import { UserCheck, UserX, Bell, Eye, RefreshCw } from 'lucide-react'
import toast from 'react-hot-toast'
import api from '../api/client'
import { fmt, fmtDate, fmtRelative } from '../utils/format'
import {
  PageHeader, Card, Table, Pagination,
  SearchInput, Select, Button, Badge,
  Modal, Input, ConfirmDialog, PageLoader,
} from '../components/UI'

const STATUT_OPTIONS = [
  { value: '',            label: 'Tous les statuts' },
  { value: 'actif',       label: 'Actifs'           },
  { value: 'suspendu',    label: 'Suspendus'        },
  { value: 'non_verifie', label: 'Non vérifiés'     },
]

export default function Joueurs() {
  const navigate = useNavigate()

  // État liste
  const [joueurs,  setJoueurs]  = useState([])
  const [pagination, setPagination] = useState({ page: 1, pages: 1, total: 0, limit: 20 })
  const [loading,  setLoading]  = useState(true)
  const [search,   setSearch]   = useState('')
  const [statut,   setStatut]   = useState('')

  // État actions
  const [actionTarget,  setActionTarget]  = useState(null) // { joueur, type }
  const [actionLoading, setActionLoading] = useState(false)
  const [notifModal,    setNotifModal]    = useState(null) // joueur
  const [notifText,     setNotifText]     = useState({ titre: '', message: '' })

  const loadJoueurs = useCallback(async (page = 1) => {
    setLoading(true)
    try {
      const params = new URLSearchParams({
        page, limit: 20,
        ...(search && { search }),
        ...(statut && { statut }),
      })
      const { data } = await api.get(`/admin/joueurs?${params}`)
      setJoueurs(data.joueurs)
      setPagination(data.pagination)
    } catch { toast.error('Erreur chargement joueurs') }
    finally  { setLoading(false) }
  }, [search, statut])

  useEffect(() => { loadJoueurs(1) }, [loadJoueurs])

  // ── Suspendre / Activer ──────────────────────────────────────
  const handleAction = async () => {
    if (!actionTarget) return
    setActionLoading(true)
    try {
      const { joueur, type } = actionTarget
      const url = `/admin/joueurs/${joueur.id}/${type === 'suspendre' ? 'suspendre' : 'activer'}`
      await api.put(url, { raison: 'Action admin' })
      toast.success(type === 'suspendre' ? 'Compte suspendu' : 'Compte activé')
      setActionTarget(null)
      loadJoueurs(pagination.page)
    } catch (e) {
      toast.error(e.response?.data?.detail ?? 'Erreur')
    } finally { setActionLoading(false) }
  }

  // ── Notifier ─────────────────────────────────────────────────
  const handleNotif = async () => {
    if (!notifModal) return
    if (!notifText.titre || !notifText.message) {
      toast.error('Titre et message requis')
      return
    }
    setActionLoading(true)
    try {
      await api.post(`/admin/joueurs/${notifModal.id}/notifier`, notifText)
      toast.success('Notification envoyée')
      setNotifModal(null)
      setNotifText({ titre: '', message: '' })
    } catch { toast.error('Erreur envoi notification') }
    finally  { setActionLoading(false) }
  }

  return (
    <div className="p-6">
      <PageHeader
        title="Joueurs"
        subtitle={`${fmt(pagination.total)} joueurs inscrits`}
        actions={
          <Button variant="secondary" onClick={() => loadJoueurs(1)}>
            <RefreshCw size={14} /> Actualiser
          </Button>
        }
      />

      {/* Filtres */}
      <div className="flex flex-wrap gap-3 mb-4">
        <SearchInput
          value={search}
          onChange={v => { setSearch(v) }}
          placeholder="Nom, prénom, téléphone..."
        />
        <Select
          value={statut}
          onChange={e => setStatut(e.target.value)}
          options={STATUT_OPTIONS}
          className="w-48"
        />
      </div>

      <Card>
        {loading ? <PageLoader /> : (
          <>
            <Table headers={['Joueur', 'Téléphone', 'Solde', 'Tentatives',
                             'Tirages', 'Statut', 'Inscrit', 'Actions']}>
              {joueurs.map(j => (
                <tr key={j.id}
                  className="border-b border-border/50 hover:bg-surface2/50
                             transition-colors">

                  {/* Nom */}
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 rounded-lg bg-purple/20 flex
                                      items-center justify-center flex-shrink-0">
                        <span className="text-sm font-bold text-purple-300">
                          {j.nom?.[0]?.toUpperCase()}
                        </span>
                      </div>
                      <div>
                        <p className="font-semibold text-white text-sm">
                          {j.nom} {j.prenom}
                        </p>
                        <p className="text-xs text-gray-500">{j.ville ?? '—'}</p>
                      </div>
                    </div>
                  </td>

                  <td className="px-4 py-3 text-sm text-gray-300">
                    {j.telephone}
                  </td>
                  <td className="px-4 py-3 text-sm font-bold text-gold">
                    {fmt(j.solde)} F
                  </td>
                  <td className="px-4 py-3 text-sm text-gray-300 text-center">
                    {j.tentatives}
                  </td>
                  <td className="px-4 py-3 text-sm text-gray-300 text-center">
                    {j.nb_tirages}
                  </td>

                  {/* Statut */}
                  <td className="px-4 py-3">
                    <Badge className={
                      j.is_active
                        ? 'bg-green-500/10 text-green-400 border-green-500/30'
                        : 'bg-red-500/10   text-red-400   border-red-500/30'
                    }>
                      {j.is_active ? '✓ Actif' : '✕ Suspendu'}
                    </Badge>
                  </td>

                  <td className="px-4 py-3 text-xs text-gray-500">
                    {fmtDate(j.created_at)}
                  </td>

                  {/* Actions */}
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-1">
                      <button
                        onClick={() => navigate(`/joueurs/${j.id}`)}
                        title="Voir détails"
                        className="p-1.5 rounded-lg hover:bg-surface2
                                   text-gray-400 hover:text-white transition-colors"
                      >
                        <Eye size={14} />
                      </button>
                      <button
                        onClick={() => setNotifModal(j)}
                        title="Envoyer notification"
                        className="p-1.5 rounded-lg hover:bg-surface2
                                   text-gray-400 hover:text-gold transition-colors"
                      >
                        <Bell size={14} />
                      </button>
                      {j.is_active ? (
                        <button
                          onClick={() => setActionTarget({ joueur: j, type: 'suspendre' })}
                          title="Suspendre"
                          className="p-1.5 rounded-lg hover:bg-red-500/10
                                     text-gray-400 hover:text-red-400 transition-colors"
                        >
                          <UserX size={14} />
                        </button>
                      ) : (
                        <button
                          onClick={() => setActionTarget({ joueur: j, type: 'activer' })}
                          title="Activer"
                          className="p-1.5 rounded-lg hover:bg-green-500/10
                                     text-gray-400 hover:text-green-400 transition-colors"
                        >
                          <UserCheck size={14} />
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </Table>
            <Pagination
              page={pagination.page}
              pages={pagination.pages}
              total={pagination.total}
              limit={pagination.limit}
              onPage={loadJoueurs}
            />
          </>
        )}
      </Card>

      {/* Modal notification */}
      <Modal
        open={!!notifModal}
        onClose={() => setNotifModal(null)}
        title={`Notifier ${notifModal?.nom} ${notifModal?.prenom}`}
        footer={<>
          <Button variant="secondary" onClick={() => setNotifModal(null)}>
            Annuler
          </Button>
          <Button onClick={handleNotif} loading={actionLoading}>
            Envoyer
          </Button>
        </>}
      >
        <div className="space-y-4">
          <Input
            label="Titre"
            value={notifText.titre}
            onChange={e => setNotifText(p => ({ ...p, titre: e.target.value }))}
            placeholder="Ex: Bonne nouvelle !"
          />
          <div className="space-y-1.5">
            <label className="text-sm font-semibold text-gray-300 block">
              Message
            </label>
            <textarea
              value={notifText.message}
              onChange={e => setNotifText(p => ({ ...p, message: e.target.value }))}
              placeholder="Votre message..."
              rows={4}
              className="w-full bg-surface2 border border-border rounded-xl px-3
                         py-2.5 text-white placeholder-gray-500 focus:outline-none
                         focus:border-gold transition-colors text-sm resize-none"
            />
          </div>
        </div>
      </Modal>

      {/* Confirm suspendre/activer */}
      <ConfirmDialog
        open={!!actionTarget}
        onClose={() => setActionTarget(null)}
        onConfirm={handleAction}
        loading={actionLoading}
        title={actionTarget?.type === 'suspendre' ? 'Suspendre le compte' : 'Activer le compte'}
        message={
          actionTarget?.type === 'suspendre'
            ? `Voulez-vous suspendre le compte de ${actionTarget?.joueur?.nom} ${actionTarget?.joueur?.prenom} ? Ses sessions actives seront révoquées.`
            : `Voulez-vous activer le compte de ${actionTarget?.joueur?.nom} ${actionTarget?.joueur?.prenom} ?`
        }
      />
    </div>
  )
}