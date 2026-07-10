// src/pages/JoueurDetail.jsx
import { useEffect, useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { ArrowLeft, UserCheck, UserX, Bell, Plus } from 'lucide-react'
import toast from 'react-hot-toast'
import api from '../api/client'
import { fmt, fmtDateTime, fmtRelative } from '../utils/format'
import {
  Button, Badge, Card, Modal, Input, PageLoader, ConfirmDialog,
} from '../components/UI'

export default function JoueurDetail() {
  const { id }   = useParams()
  const navigate = useNavigate()

  const [data,    setData]    = useState(null)
  const [loading, setLoading] = useState(true)

  // Modals
  const [notifModal,  setNotifModal]  = useState(false)
  const [notifText,   setNotifText]   = useState({ titre: '', message: '' })
  const [creditModal, setCreditModal] = useState(false)
  const [creditQty,   setCreditQty]   = useState('')
  const [confirmSuspend, setConfirmSuspend] = useState(false)
  const [actionLoading,  setActionLoading]  = useState(false)

  useEffect(() => {
    api.get(`/admin/joueurs/${id}`)
      .then(r => setData(r.data))
      .catch(() => toast.error('Joueur introuvable'))
      .finally(() => setLoading(false))
  }, [id])

  if (loading) return <PageLoader />
  if (!data)   return <div className="p-6 text-gray-400">Joueur introuvable</div>

  const { joueur, tirages, transactions } = data

  // ── Actions ──────────────────────────────────────────────────
  const toggleSuspend = async () => {
    setActionLoading(true)
    try {
      const url = joueur.is_active
        ? `/admin/joueurs/${id}/suspendre`
        : `/admin/joueurs/${id}/activer`
      await api.put(url, { raison: 'Action admin' })
      toast.success(joueur.is_active ? 'Compte suspendu' : 'Compte activé')
      setConfirmSuspend(false)
      setData(p => ({ ...p, joueur: { ...p.joueur, is_active: !p.joueur.is_active } }))
    } catch (e) { toast.error(e.response?.data?.detail ?? 'Erreur') }
    finally { setActionLoading(false) }
  }

  const sendNotif = async () => {
    if (!notifText.titre || !notifText.message) {
      toast.error('Titre et message requis')
      return
    }
    setActionLoading(true)
    try {
      await api.post(`/admin/joueurs/${id}/notifier`, notifText)
      toast.success('Notification envoyée')
      setNotifModal(false)
      setNotifText({ titre: '', message: '' })
    } catch { toast.error('Erreur') }
    finally { setActionLoading(false) }
  }

  const creditTentatives = async () => {
    const qty = parseInt(creditQty)
    if (!qty || qty <= 0) { toast.error('Quantité invalide'); return }
    setActionLoading(true)
    try {
      // Ajustement admin via route dédiée qui crédite et notifie
      const res = await api.post(`/admin/joueurs/${id}/credit`, { quantite: qty })
      toast.success(`${qty} tentatives créditées (notification envoyée)`)
      setCreditModal(false)
      setCreditQty('')
      // Mettre à jour l'état local immédiatement
      setData(p => ({
        ...p,
        joueur: { ...p.joueur, tentatives: res.data.tentatives }
      }))
    } catch { toast.error('Erreur lors du crédit de tentatives') }
    finally { setActionLoading(false) }
  }

  return (
    <div className="p-6 space-y-6">

      {/* Header */}
      <div className="flex items-center gap-4">
        <button onClick={() => navigate('/joueurs')}
          className="p-2 rounded-xl bg-surface border border-border
                     text-gray-400 hover:text-white transition-colors">
          <ArrowLeft size={18} />
        </button>
        <div className="flex-1">
          <h1 className="text-xl font-black text-white">
            {joueur.nom} {joueur.prenom}
          </h1>
          <p className="text-gray-400 text-sm">{joueur.telephone}</p>
        </div>
        {/* Actions */}
        <div className="flex gap-2">
          <Button variant="secondary" onClick={() => setNotifModal(true)}>
            <Bell size={14} /> Notifier
          </Button>
          <Button variant="secondary" onClick={() => setCreditModal(true)}>
            <Plus size={14} /> Tentatives
          </Button>
          <Button variant="secondary" className="border-gold text-gold hover:bg-gold/10" 
                  onClick={() => { setCreditQty('1'); setCreditModal(true); }}>
            🎁 Compenser (1)
          </Button>
          <Button
            variant={joueur.is_active ? 'danger' : 'secondary'}
            onClick={() => setConfirmSuspend(true)}
          >
            {joueur.is_active
              ? <><UserX size={14} /> Suspendre</>
              : <><UserCheck size={14} /> Activer</>}
          </Button>
        </div>
      </div>

      {/* Infos + stats */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        {[
          { label: 'Solde',       value: `${fmt(joueur.solde)} FCFA`,  color: 'text-gold'        },
          { label: 'Tentatives',  value: joueur.tentatives,            color: 'text-purple-400'  },
          { label: 'Tirages',     value: joueur.nb_tirages,            color: 'text-blue-400'    },
          { label: 'Total Déposé', value: `${fmt(joueur.total_depose)} F`, color: 'text-green-400'   },
          { label: 'Total Retiré', value: `${fmt(joueur.total_retire)} F`, color: 'text-orange-400'  },
          { label: 'Marge Joueur', value: `${fmt((joueur.total_depose || 0) - (joueur.total_retire || 0))} F`, color: ((joueur.total_depose || 0) - (joueur.total_retire || 0)) >= 0 ? 'text-green-500' : 'text-red-500' },
          { label: 'Gains',       value: joueur.nb_gains,              color: 'text-green-400'   },
          { label: 'Valeur gagnée', value: `${fmt(joueur.valeur_gagnee_totale)} F`, color: 'text-gold' },
          { label: 'Parrainages', value: joueur.parrainages,           color: 'text-blue-400'    },
          { label: 'Code parrain',value: joueur.code_parrain,          color: 'text-gray-300'    },
          { label: 'Statut',
            value: joueur.is_active ? 'Actif' : 'Suspendu',
            color: joueur.is_active ? 'text-green-400' : 'text-red-400' },
        ].map(({ label, value, color }) => (
          <Card key={label} className="p-4">
            <p className="text-xs text-gray-500 mb-1">{label}</p>
            <p className={`text-lg font-black ${color}`}>{value ?? '—'}</p>
          </Card>
        ))}
      </div>

      {/* Infos profil */}
      <Card className="p-5">
        <h3 className="font-bold text-white mb-4">Informations personnelles</h3>
        <div className="grid grid-cols-2 md:grid-cols-3 gap-4 text-sm">
          {[
            ['Email',       joueur.email],
            ['Pays',        joueur.pays],
            ['Ville',       joueur.ville],
            ['Quartier',    joueur.quartier],
            ['Rôle',        joueur.role],
            ['Vérifié',     joueur.is_verified ? 'Oui' : 'Non'],
            ['Inscrit le',  fmtDateTime(joueur.created_at)],
            ['Dernière connexion', fmtDateTime(joueur.last_login_at)],
          ].map(([k, v]) => (
            <div key={k}>
              <p className="text-gray-500 text-xs">{k}</p>
              <p className="text-gray-200 font-medium mt-0.5">{v ?? '—'}</p>
            </div>
          ))}
        </div>
      </Card>

      {/* Derniers tirages */}
      <Card>
        <div className="p-5 border-b border-border">
          <h3 className="font-bold text-white">10 derniers tirages</h3>
        </div>
        <div className="divide-y divide-border/50">
          {tirages.length === 0
            ? <p className="text-gray-500 text-sm p-5">Aucun tirage</p>
            : tirages.map(t => (
              <div key={t.id}
                className="flex items-center justify-between px-5 py-3">
                <div className="flex items-center gap-3">
                  <span className="text-lg">{t.is_winner ? '🏆' : '❌'}</span>
                  <div>
                    <p className="text-sm font-semibold text-white">
                      {t.cadeau} — {t.lot}
                    </p>
                    <p className="text-xs text-gray-500">
                      {fmtRelative(t.created_at)} · {t.mode}
                    </p>
                  </div>
                </div>
                <span className={`text-sm font-bold ${
                  t.is_winner ? 'text-gold' : 'text-gray-500'}`}>
                  {t.is_winner ? `+${fmt(t.valeur_gagnee)} F` : '—'}
                </span>
              </div>
            ))}
        </div>
      </Card>

      {/* Dernières transactions */}
      <Card>
        <div className="p-5 border-b border-border">
          <h3 className="font-bold text-white">10 dernières transactions</h3>
        </div>
        <div className="divide-y divide-border/50">
          {transactions.length === 0
            ? <p className="text-gray-500 text-sm p-5">Aucune transaction</p>
            : transactions.map(tx => (
              <div key={tx.id}
                className="flex items-center justify-between px-5 py-3">
                <div>
                  <p className="text-sm font-semibold text-white">
                    {tx.methode?.replace('_', ' ')}
                  </p>
                  <p className="text-xs text-gray-500">
                    {fmtRelative(tx.created_at)} · {tx.reference ?? '—'}
                  </p>
                  {(tx.statut === 'failed' || tx.statut === 'rejected') && tx.metadata && tx.metadata.errorMessage && (
                    <p className="text-xs font-medium text-red-400 mt-1">
                      🛑 Motif: {tx.metadata.errorMessage}
                    </p>
                  )}
                  {(tx.statut === 'failed' || tx.statut === 'rejected') && tx.metadata && tx.metadata.failureReason && !tx.metadata.errorMessage && (
                    <p className="text-xs font-medium text-red-400 mt-1">
                      🛑 Motif: {tx.metadata.failureReason}
                    </p>
                  )}
                </div>
                <div className="text-right">
                  <p className="text-sm font-bold text-gold">
                    {fmt(tx.montant)} FCFA
                  </p>
                  <Badge className={
                    tx.statut === 'success'
                      ? 'bg-green-500/10 text-green-400 border-green-500/30'
                      : 'bg-red-500/10 text-red-400 border-red-500/30'
                  }>
                    {tx.statut}
                  </Badge>
                </div>
              </div>
            ))}
        </div>
      </Card>

      {/* Modal notification */}
      <Modal open={notifModal} onClose={() => setNotifModal(false)}
        title="Envoyer une notification"
        footer={<>
          <Button variant="secondary" onClick={() => setNotifModal(false)}>
            Annuler
          </Button>
          <Button onClick={sendNotif} loading={actionLoading}>Envoyer</Button>
        </>}
      >
        <div className="space-y-4">
          <Input label="Titre" value={notifText.titre}
            onChange={e => setNotifText(p => ({ ...p, titre: e.target.value }))}
            placeholder="Ex: Offre spéciale !" />
          <div className="space-y-1.5">
            <label className="text-sm font-semibold text-gray-300 block">
              Message
            </label>
            <textarea value={notifText.message}
              onChange={e => setNotifText(p => ({ ...p, message: e.target.value }))}
              rows={4} placeholder="Votre message..."
              className="w-full bg-surface2 border border-border rounded-xl px-3
                         py-2.5 text-white placeholder-gray-500 focus:outline-none
                         focus:border-gold transition-colors text-sm resize-none"
            />
          </div>
        </div>
      </Modal>

      {/* Modal créditer tentatives */}
      <Modal open={creditModal} onClose={() => setCreditModal(false)}
        title="Créditer des tentatives"
        footer={<>
          <Button variant="secondary" onClick={() => setCreditModal(false)}>
            Annuler
          </Button>
          <Button onClick={creditTentatives} loading={actionLoading}>
            Créditer
          </Button>
        </>}
      >
        <Input label="Nombre de tentatives" type="number"
          value={creditQty}
          onChange={e => setCreditQty(e.target.value)}
          placeholder="Ex: 5" />
      </Modal>

      {/* Confirm suspendre */}
      <ConfirmDialog
        open={confirmSuspend}
        onClose={() => setConfirmSuspend(false)}
        onConfirm={toggleSuspend}
        loading={actionLoading}
        title={joueur.is_active ? 'Suspendre le compte' : 'Activer le compte'}
        message={
          joueur.is_active
            ? `Suspendre ${joueur.nom} ${joueur.prenom} ? Ses sessions actives seront révoquées.`
            : `Activer le compte de ${joueur.nom} ${joueur.prenom} ?`
        }
      />
    </div>
  )
}