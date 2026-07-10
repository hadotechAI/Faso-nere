// src/pages/Parametres.jsx
import { useEffect, useState } from 'react'
import { Save, UserPlus, Shield, RefreshCw } from 'lucide-react'
import toast from 'react-hot-toast'
import api from '../api/client'
import { useAuth } from '../store/authStore'
import {
  PageHeader, Card, Button, Input, Modal, PageLoader,
} from '../components/UI'

const CONFIG_LABELS = {
  bonus_parrainage_tentatives: { label: 'Bonus parrainage (Tentatives)',  type: 'number' },
  otp_max_attempts:            { label: 'Tentatives OTP max',               type: 'number' },
  otp_expires_minutes:         { label: 'Expiration OTP (minutes)',         type: 'number' },
  login_max_attempts:          { label: 'Échecs login avant blocage',       type: 'number' },
  login_lock_duration_minutes: { label: 'Durée blocage compte (minutes)',   type: 'number' },
  session_ttl_hours:           { label: 'Durée session (heures)',           type: 'number' },
  refresh_ttl_days:            { label: 'Durée refresh token (jours)',      type: 'number' },
}

export default function Parametres() {
  const { user, isSuperAdmin } = useAuth()

  const [configs,  setConfigs]  = useState({})
  const [loading,  setLoading]  = useState(true)
  const [saving,   setSaving]   = useState(false)
  const [edited,   setEdited]   = useState({})

  // Contrôles applicatifs
  const [controles, setControles] = useState({ depot_actif: true, retrait_actif: true })
  const [loadingControles, setLoadingControles] = useState(true)

  // Modal créer admin
  const [adminModal,   setAdminModal]   = useState(false)
  const [adminForm,    setAdminForm]    = useState({ telephone: '', role: 'admin' })
  const [adminLoading, setAdminLoading] = useState(false)

  // Modal changer mot de passe
  const [pwdModal,   setPwdModal]   = useState(false)
  const [pwdForm,    setPwdForm]    = useState({ ancien: '', nouveau: '', confirm: '' })
  const [pwdLoading, setPwdLoading] = useState(false)

  useEffect(() => {
    // Charger configs existantes
    api.get('/admin/config')
      .then(({ data }) => {
        const confs = {}
        data.config.forEach(c => { confs[c.cle] = c.valeur })
        setConfigs(prev => ({
          bonus_parrainage_tentatives: confs.bonus_parrainage_tentatives || '1',
          otp_max_attempts:            confs.otp_max_attempts || '3',
          otp_expires_minutes:         confs.otp_expires_minutes || '5',
          login_max_attempts:          confs.login_max_attempts || '5',
          login_lock_duration_minutes: confs.login_lock_duration_minutes || '30',
          session_ttl_hours:           confs.session_ttl_hours || '24',
          refresh_ttl_days:            confs.refresh_ttl_days || '30',
          ...confs
        }))
      })
      .catch(console.error)
      .finally(() => setLoading(false))

    // Charger contrôles
    api.get('/admin/parametres/controles')
      .then(({ data }) => setControles(data))
      .catch(console.error)
      .finally(() => setLoadingControles(false))
  }, [])

  const saveConfigs = async () => {
    if (Object.keys(edited).length === 0) {
      toast('Aucune modification', { icon: 'ℹ️' })
      return
    }
    setSaving(true)
    try {
      await Promise.all(
        Object.entries(edited).map(([cle, valeur]) =>
          api.put('/admin/parametres', { cle, valeur }).catch(() => {})
        )
      )
      setConfigs(p => ({ ...p, ...edited }))
      setEdited({})
      toast.success('Paramètres sauvegardés')
    } catch { toast.error('Erreur sauvegarde') }
    finally { setSaving(false) }
  }

  const toggleControle = async (key, newValue) => {
    const old = { ...controles }
    setControles(p => ({ ...p, [key]: newValue }))
    try {
      await api.put('/admin/parametres/controles', { [key]: newValue })
      toast.success(`${key === 'depot_actif' ? 'Dépôts' : 'Retraits'} ${newValue ? 'activés' : 'bloqués'}`)
    } catch {
      setControles(old)
      toast.error('Erreur lors de la mise à jour')
    }
  }

  const promoteAdmin = async () => {
    if (!adminForm.telephone) {
      toast.error('Numéro de téléphone requis')
      return
    }
    setAdminLoading(true)
    try {
      // Chercher le joueur et le promouvoir
      const { data } = await api.get(
        `/admin/joueurs?search=${encodeURIComponent(adminForm.telephone)}&limit=1`
      )
      const joueur = data.joueurs?.[0]
      if (!joueur) { toast.error('Joueur introuvable'); return }

      // Notifier le nouveau rôle
      await api.post(`/admin/joueurs/${joueur.id}/notifier`, {
        titre:   '🔐 Accès administrateur',
        message: `Votre compte a été promu au rôle ${adminForm.role}. Connectez-vous au dashboard admin.`,
        type:    'systeme',
      })
      toast.success(`${joueur.nom} ${joueur.prenom} promu ${adminForm.role}`)
      toast('Mettez à jour le rôle manuellement dans PostgreSQL', { icon: 'ℹ️' })
      setAdminModal(false)
      setAdminForm({ telephone: '', role: 'admin' })
    } catch { toast.error('Erreur') }
    finally { setAdminLoading(false) }
  }

  if (loading) return <PageLoader />

  return (
    <div className="p-6 space-y-6">
      <PageHeader
        title="Paramètres système"
        subtitle="Configuration globale de Faso Nere"
      />

      {/* ── Configuration système ── */}
      <Card className="p-6">
        <div className="flex items-center justify-between mb-6">
          <h3 className="font-bold text-white">Configuration système</h3>
          <Button onClick={saveConfigs} loading={saving}
            disabled={Object.keys(edited).length === 0}>
            <Save size={14} /> Sauvegarder
            {Object.keys(edited).length > 0 && (
              <span className="ml-1 bg-white/20 text-xs px-1.5 py-0.5 rounded-full">
                {Object.keys(edited).length}
              </span>
            )}
          </Button>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {Object.entries(CONFIG_LABELS).map(([cle, { label, type }]) => {
            const val     = edited[cle] ?? configs[cle] ?? ''
            const isDirty = edited[cle] !== undefined
            return (
              <div key={cle}>
                <label className="text-sm font-semibold text-gray-300 block mb-1.5">
                  {label}
                  {isDirty && (
                    <span className="ml-2 text-xs text-gold">● modifié</span>
                  )}
                </label>
                <input
                  type={type}
                  value={val}
                  onChange={e => setEdited(p => ({
                    ...p, [cle]: e.target.value
                  }))}
                  className={`w-full bg-surface2 border rounded-xl px-3 py-2.5
                              text-white focus:outline-none transition-colors text-sm
                              ${isDirty
                                ? 'border-gold focus:border-gold'
                                : 'border-border focus:border-gold'}`}
                />
              </div>
            )
          })}
        </div>

        {Object.keys(edited).length > 0 && (
          <div className="mt-4 flex items-center justify-between bg-gold/5
                          border border-gold/20 rounded-xl p-3">
            <p className="text-sm text-gold">
              {Object.keys(edited).length} paramètre(s) modifié(s)
            </p>
            <button
              onClick={() => setEdited({})}
              className="text-xs text-gray-400 hover:text-white transition-colors
                         flex items-center gap-1"
            >
              <RefreshCw size={12} /> Annuler les modifications
            </button>
          </div>
        )}
      </Card>

      {/* ── Contrôles applicatifs ── */}
      <Card className="p-6">
        <div className="flex items-center justify-between mb-6">
          <div>
            <h3 className="font-bold text-white">Contrôles des transactions</h3>
            <p className="text-xs text-gray-400 mt-1">Bloquez ou réactivez les paiements instantanément</p>
          </div>
        </div>

        {loadingControles ? (
          <div className="animate-pulse h-20 bg-surface2 rounded-xl"></div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="bg-surface2 rounded-xl p-4 flex items-center justify-between">
              <div>
                <p className="font-semibold text-white">Dépôts & Achats de pack</p>
                <p className={`text-xs mt-1 ${controles.depot_actif ? 'text-green-400' : 'text-red-400'}`}>
                  {controles.depot_actif ? 'Actuellement autorisés' : 'Actuellement suspendus'}
                </p>
              </div>
              <button
                onClick={() => toggleControle('depot_actif', !controles.depot_actif)}
                className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${controles.depot_actif ? 'bg-gold' : 'bg-gray-600'}`}
              >
                <span className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${controles.depot_actif ? 'translate-x-6' : 'translate-x-1'}`} />
              </button>
            </div>

            <div className="bg-surface2 rounded-xl p-4 flex items-center justify-between">
              <div>
                <p className="font-semibold text-white">Retraits d'argent</p>
                <p className={`text-xs mt-1 ${controles.retrait_actif ? 'text-green-400' : 'text-red-400'}`}>
                  {controles.retrait_actif ? 'Actuellement autorisés' : 'Actuellement suspendus'}
                </p>
              </div>
              <button
                onClick={() => toggleControle('retrait_actif', !controles.retrait_actif)}
                className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${controles.retrait_actif ? 'bg-gold' : 'bg-gray-600'}`}
              >
                <span className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${controles.retrait_actif ? 'translate-x-6' : 'translate-x-1'}`} />
              </button>
            </div>
          </div>
        )}
      </Card>

      {/* ── Gestion des admins ── */}
      {isSuperAdmin && (
        <Card className="p-6">
          <div className="flex items-center justify-between mb-6">
            <div>
              <h3 className="font-bold text-white">Gestion des administrateurs</h3>
              <p className="text-xs text-gray-400 mt-1">
                Réservé aux super admins
              </p>
            </div>
            <Button onClick={() => setAdminModal(true)}>
              <UserPlus size={14} /> Promouvoir admin
            </Button>
          </div>

          {/* Infos admin connecté */}
          <div className="bg-surface2 rounded-xl p-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-purple/20 flex
                              items-center justify-center">
                <span className="font-bold text-purple-300">
                  {user?.nom?.[0]?.toUpperCase()}
                </span>
              </div>
              <div>
                <p className="font-semibold text-white">
                  {user?.nom} {user?.prenom}
                </p>
                <p className="text-xs text-gold capitalize">{user?.role}</p>
              </div>
              <div className="ml-auto">
                <span className="text-xs bg-gold/10 text-gold border border-gold/20
                                 px-2 py-1 rounded-lg">
                  Compte connecté
                </span>
              </div>
            </div>
          </div>

          <div className="mt-4 p-3 bg-yellow-500/5 border border-yellow-500/20
                          rounded-xl">
            <p className="text-xs text-yellow-400">
              ⚠️ Pour promouvoir un admin, exécutez aussi cette requête SQL dans
              pgAdmin :
            </p>
            <pre className="text-xs text-gray-300 mt-2 font-mono bg-bg
                            rounded-lg p-2 overflow-x-auto">
{`UPDATE users SET role = 'admin'
WHERE telephone = '+226XXXXXXXX';`}
            </pre>
          </div>
        </Card>
      )}

      {/* ── Informations système ── */}
      <Card className="p-6">
        <h3 className="font-bold text-white mb-4">Informations système</h3>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {[
            { label: 'Version API',    value: 'v2.0.0'       },
            { label: 'Base de données',value: 'PostgreSQL'   },
            { label: 'Framework',      value: 'FastAPI'      },
            { label: 'Dashboard',      value: 'React + Vite' },
          ].map(({ label, value }) => (
            <div key={label} className="bg-surface2 rounded-xl p-3 text-center">
              <p className="text-xs text-gray-500 mb-1">{label}</p>
              <p className="text-sm font-bold text-white">{value}</p>
            </div>
          ))}
        </div>
      </Card>

      {/* Modal promouvoir admin */}
      <Modal
        open={adminModal}
        onClose={() => setAdminModal(false)}
        title="Promouvoir un joueur en admin"
        footer={<>
          <Button variant="secondary" onClick={() => setAdminModal(false)}>
            Annuler
          </Button>
          <Button onClick={promoteAdmin} loading={adminLoading}>
            <Shield size={14} /> Promouvoir
          </Button>
        </>}
      >
        <div className="space-y-4">
          <Input
            label="Téléphone du joueur"
            value={adminForm.telephone}
            onChange={e => setAdminForm(p => ({ ...p, telephone: e.target.value }))}
            placeholder="+22600000000"
          />
          <div className="space-y-1.5">
            <label className="text-sm font-semibold text-gray-300 block">
              Rôle
            </label>
            <div className="grid grid-cols-2 gap-3">
              {['admin', 'super_admin'].map(role => (
                <button
                  key={role}
                  onClick={() => setAdminForm(p => ({ ...p, role }))}
                  className={`p-3 rounded-xl border text-sm font-semibold
                              transition-all text-center ${
                    adminForm.role === role
                      ? 'border-gold bg-gold/10 text-gold'
                      : 'border-border bg-surface2 text-gray-400 hover:bg-card'
                  }`}
                >
                  {role === 'admin' ? '🛡️ Admin' : '👑 Super Admin'}
                </button>
              ))}
            </div>
          </div>
          <div className="bg-surface2 rounded-xl p-3 text-xs text-gray-400">
            <p className="font-semibold text-gray-300 mb-1">Différences :</p>
            <p>• <strong className="text-white">Admin</strong> : accès complet au dashboard</p>
            <p>• <strong className="text-white">Super Admin</strong> : + gestion des admins et paramètres</p>
          </div>
        </div>
      </Modal>
    </div>
  )
}