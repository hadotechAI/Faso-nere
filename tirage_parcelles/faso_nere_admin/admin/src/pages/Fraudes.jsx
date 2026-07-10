import { useEffect, useState, useCallback } from 'react'
import { ShieldAlert, Eye, UserX } from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import toast from 'react-hot-toast'
import api from '../api/client'
import {
  PageHeader, Card, Table, Badge, PageLoader, Button, ConfirmDialog
} from '../components/UI'

export default function Fraudes() {
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(true)
  const navigate = useNavigate()

  // Pour la suspension
  const [confirmSuspend, setConfirmSuspend] = useState(null) // user object
  const [actionLoading, setActionLoading] = useState(false)

  const loadAnomalies = useCallback(async () => {
    setLoading(true)
    try {
      const res = await api.get('/admin/anomalies')
      setData(res.data)
    } catch {
      toast.error('Erreur chargement des anomalies')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => { loadAnomalies() }, [loadAnomalies])

  const toggleSuspend = async () => {
    if (!confirmSuspend) return
    setActionLoading(true)
    try {
      const url = confirmSuspend.is_active
        ? `/admin/joueurs/${confirmSuspend.id}/suspendre`
        : `/admin/joueurs/${confirmSuspend.id}/activer`
      await api.put(url, { raison: 'Détection Fraude' })
      toast.success(confirmSuspend.is_active ? 'Compte suspendu' : 'Compte activé')
      setConfirmSuspend(null)
      loadAnomalies() // recharger pour mettre à jour les statuts
    } catch (e) {
      toast.error(e.response?.data?.detail ?? 'Erreur lors de la suspension')
    } finally {
      setActionLoading(false)
    }
  }

  if (loading) return <PageLoader />

  const { chanceux = [], spammeurs_retraits = [], echecs_multiples = [] } = data || {}

  const renderActions = (user) => (
    <div className="flex gap-2">
      <Button variant="secondary" onClick={() => navigate(`/joueurs/${user.id}`)}>
        <Eye size={14} /> Profil
      </Button>
      <Button
        variant={user.is_active ? 'danger' : 'secondary'}
        onClick={() => setConfirmSuspend(user)}
      >
        {user.is_active ? <><UserX size={14} /> Suspendre</> : 'Activer'}
      </Button>
    </div>
  )

  const renderStatus = (isActive) => (
    <Badge className={isActive ? 'bg-green-500/10 text-green-400 border-green-500/30' : 'bg-red-500/10 text-red-400 border-red-500/30'}>
      {isActive ? 'Actif' : 'Suspendu'}
    </Badge>
  )

  return (
    <div className="p-6 space-y-6">
      <PageHeader
        title="Système Anti-Fraude"
        subtitle="Détection automatique des comportements suspects"
        actions={
          <div className="flex items-center gap-2 bg-red-500/10 border border-red-500/30 rounded-xl px-3 py-2">
            <ShieldAlert size={14} className="text-red-400" />
            <span className="text-xs text-red-400 font-bold">
              {chanceux.length + spammeurs_retraits.length + echecs_multiples.length} Alertes
            </span>
          </div>
        }
      />

      {/* 1. Taux de victoire anormaux */}
      <Card className="border-red-500/20">
        <div className="p-5 border-b border-border bg-red-500/5">
          <h3 className="font-bold text-white flex items-center gap-2">
            🎰 Joueurs "Trop Chanceux"
          </h3>
          <p className="text-xs text-gray-400 mt-1">Taux de victoire supérieur à 40% sur au moins 5 tirages.</p>
        </div>
        <Table headers={['Joueur', 'Téléphone', 'Statut', 'Tirages', 'Gains', 'Taux de victoire', 'Actions']}>
          {chanceux.length === 0 ? (
            <tr><td colSpan={7} className="text-center p-4 text-gray-500 text-sm">Aucune anomalie détectée</td></tr>
          ) : chanceux.map(u => (
            <tr key={u.id} className="border-b border-border/50 hover:bg-surface2/50 transition-colors">
              <td className="px-4 py-3 font-semibold text-white">{u.nom} {u.prenom}</td>
              <td className="px-4 py-3 text-gray-400 text-sm">{u.telephone}</td>
              <td className="px-4 py-3">{renderStatus(u.is_active)}</td>
              <td className="px-4 py-3 text-gray-300 font-mono text-sm">{u.nb_tirages}</td>
              <td className="px-4 py-3 text-gold font-mono text-sm">{u.nb_gains}</td>
              <td className="px-4 py-3">
                <span className="text-red-400 font-bold">{u.win_rate}%</span>
              </td>
              <td className="px-4 py-3">{renderActions(u)}</td>
            </tr>
          ))}
        </Table>
      </Card>

      {/* 2. Spammeurs de retraits */}
      <Card className="border-orange-500/20">
        <div className="p-5 border-b border-border bg-orange-500/5">
          <h3 className="font-bold text-white flex items-center gap-2">
            💸 Spammeurs de Retraits
          </h3>
          <p className="text-xs text-gray-400 mt-1">Plus de 2 demandes de retrait en attente simultanément.</p>
        </div>
        <Table headers={['Joueur', 'Téléphone', 'Statut', 'Retraits en attente', 'Actions']}>
          {spammeurs_retraits.length === 0 ? (
            <tr><td colSpan={5} className="text-center p-4 text-gray-500 text-sm">Aucune anomalie détectée</td></tr>
          ) : spammeurs_retraits.map(u => (
            <tr key={u.id} className="border-b border-border/50 hover:bg-surface2/50 transition-colors">
              <td className="px-4 py-3 font-semibold text-white">{u.nom} {u.prenom}</td>
              <td className="px-4 py-3 text-gray-400 text-sm">{u.telephone}</td>
              <td className="px-4 py-3">{renderStatus(u.is_active)}</td>
              <td className="px-4 py-3">
                <span className="text-orange-400 font-bold">{u.nb_pending}</span>
              </td>
              <td className="px-4 py-3">{renderActions(u)}</td>
            </tr>
          ))}
        </Table>
      </Card>

      {/* 3. Echecs Multiples (24h) */}
      <Card className="border-yellow-500/20">
        <div className="p-5 border-b border-border bg-yellow-500/5">
          <h3 className="font-bold text-white flex items-center gap-2">
            💳 Échecs Multiples de Dépôt
          </h3>
          <p className="text-xs text-gray-400 mt-1">Plus de 5 transactions (PawaPay) échouées ou rejetées dans les dernières 24 heures.</p>
        </div>
        <Table headers={['Joueur', 'Téléphone', 'Statut', 'Échecs en 24h', 'Actions']}>
          {echecs_multiples.length === 0 ? (
            <tr><td colSpan={5} className="text-center p-4 text-gray-500 text-sm">Aucune anomalie détectée</td></tr>
          ) : echecs_multiples.map(u => (
            <tr key={u.id} className="border-b border-border/50 hover:bg-surface2/50 transition-colors">
              <td className="px-4 py-3 font-semibold text-white">{u.nom} {u.prenom}</td>
              <td className="px-4 py-3 text-gray-400 text-sm">{u.telephone}</td>
              <td className="px-4 py-3">{renderStatus(u.is_active)}</td>
              <td className="px-4 py-3">
                <span className="text-yellow-400 font-bold">{u.nb_echecs}</span>
              </td>
              <td className="px-4 py-3">{renderActions(u)}</td>
            </tr>
          ))}
        </Table>
      </Card>

      <ConfirmDialog
        open={!!confirmSuspend}
        onClose={() => setConfirmSuspend(null)}
        onConfirm={toggleSuspend}
        loading={actionLoading}
        title={confirmSuspend?.is_active ? 'Suspendre le compte' : 'Activer le compte'}
        message={
          confirmSuspend?.is_active
            ? `Suspendre ${confirmSuspend.nom} ${confirmSuspend.prenom} ? Ses sessions actives seront révoquées.`
            : `Activer le compte de ${confirmSuspend?.nom} ${confirmSuspend?.prenom} ?`
        }
      />
    </div>
  )
}
