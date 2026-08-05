// src/pages/Notifications.jsx
import { useState } from 'react'
import { Send, Users, User } from 'lucide-react'
import toast from 'react-hot-toast'
import api from '../api/client'
import { PageHeader, Card, Button, Input, Select } from '../components/UI'

const TYPES = [
  { value: 'systeme',    label: '⚙️ Système'     },
  { value: 'promo',      label: '🎁 Promotion'   },
  { value: 'paiement',   label: '💰 Paiement'    },
  { value: 'gain',       label: '🏆 Gain'        },
  { value: 'livraison',  label: '🚚 Livraison'   },
]

export default function Notifications() {
  // Notification globale
  const [globalForm,    setGlobalForm]    = useState({ titre: '', message: '', type: 'systeme', send_sms: false })
  const [globalLoading, setGlobalLoading] = useState(false)
  const [globalSent,    setGlobalSent]    = useState(0)

  // Notification ciblée
  const [targetForm,    setTargetForm]    = useState({ telephone: '', titre: '', message: '', type: 'systeme', send_sms: false })
  const [targetLoading, setTargetLoading] = useState(false)

  // ── Envoyer à tous ───────────────────────────────────────────
  const sendGlobal = async () => {
    if (!globalForm.titre || !globalForm.message) {
      toast.error('Titre et message requis')
      return
    }
    setGlobalLoading(true)
    try {
      // Appel de la nouvelle route globale (une seule requête)
      await api.post('/admin/notifications/global', {
        titre:   globalForm.titre,
        message: globalForm.message,
        type:    globalForm.type,
        send_sms: globalForm.send_sms,
      })

      setGlobalSent(true) // On peut juste afficher un succès global (on ne compte plus côté frontend)
      toast.success(`Notification globale lancée avec succès`)
      setGlobalForm({ titre: '', message: '', type: 'systeme', send_sms: false })
    } catch { toast.error('Erreur envoi notifications') }
    finally { setGlobalLoading(false) }
  }

  // ── Envoyer à un joueur ──────────────────────────────────────
  const sendTargeted = async () => {
    if (!targetForm.telephone || !targetForm.titre || !targetForm.message) {
      toast.error('Tous les champs sont requis')
      return
    }
    setTargetLoading(true)
    try {
      // Chercher l'utilisateur par téléphone
      const { data: search } = await api.get(
        `/admin/joueurs?search=${encodeURIComponent(targetForm.telephone)}&limit=1`
      )
      const joueur = search.joueurs?.[0]
      if (!joueur) {
        toast.error('Joueur introuvable')
        return
      }
      await api.post(`/admin/joueurs/${joueur.id}/notifier`, {
        titre:   targetForm.titre,
        message: targetForm.message,
        type:    targetForm.type,
        send_sms: targetForm.send_sms,
      })
      toast.success(`Notification envoyée à ${joueur.nom} ${joueur.prenom}`)
      setTargetForm({ telephone: '', titre: '', message: '', type: 'systeme', send_sms: false })
    } catch { toast.error('Erreur envoi notification') }
    finally { setTargetLoading(false) }
  }

  return (
    <div className="p-6 space-y-6">
      <PageHeader
        title="Notifications"
        subtitle="Envoyez des notifications aux joueurs"
      />

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">

        {/* ── Notification globale ── */}
        <Card className="p-6">
          <div className="flex items-center gap-3 mb-6">
            <div className="w-10 h-10 rounded-xl bg-gold/10 border border-gold/20
                            flex items-center justify-center">
              <Users size={18} className="text-gold" />
            </div>
            <div>
              <h3 className="font-bold text-white">Notification globale</h3>
              <p className="text-xs text-gray-400">Envoyer à tous les joueurs</p>
            </div>
          </div>

          <div className="space-y-4">
            <Select
              label="Type"
              value={globalForm.type}
              onChange={e => setGlobalForm(p => ({ ...p, type: e.target.value }))}
              options={TYPES}
            />
            <Input
              label="Titre"
              value={globalForm.titre}
              onChange={e => setGlobalForm(p => ({ ...p, titre: e.target.value }))}
              placeholder="Ex: 🎉 Nouvelle offre !"
            />
            <div className="space-y-1.5">
              <label className="text-sm font-semibold text-gray-300 block">
                Message
              </label>
              <textarea
                value={globalForm.message}
                onChange={e => setGlobalForm(p => ({ ...p, message: e.target.value }))}
                rows={5}
                placeholder="Votre message pour tous les joueurs..."
                className="w-full bg-surface2 border border-border rounded-xl px-3
                           py-2.5 text-white placeholder-gray-500 focus:outline-none
                           focus:border-gold transition-colors text-sm resize-none"
              />
            </div>

            <label className="flex items-center gap-2 mt-4 cursor-pointer">
              <input 
                type="checkbox" 
                className="w-4 h-4 rounded border-gray-600 bg-surface text-gold focus:ring-gold"
                checked={globalForm.send_sms}
                onChange={e => setGlobalForm(p => ({ ...p, send_sms: e.target.checked }))}
              />
              <span className="text-sm text-gray-300 font-semibold">📱 Envoyer aussi par SMS</span>
            </label>

            {globalForm.send_sms && (
              <div className="bg-red-500/10 border border-red-500/30 rounded-xl p-3 mt-2">
                <p className="text-red-400 text-xs font-semibold flex items-start gap-1.5">
                  ⚠️ Attention : l'envoi de SMS à toute la base de données engendre des coûts financiers chez Africa's Talking.
                </p>
              </div>
            )}

            {globalSent > 0 && (
              <div className="bg-green-500/10 border border-green-500/30 rounded-xl p-3">
                <p className="text-green-400 text-sm font-semibold">
                  ✅ Dernière diffusion : {globalSent} joueur(s) notifié(s)
                </p>
              </div>
            )}

            <Button
              className="w-full"
              onClick={sendGlobal}
              loading={globalLoading}
              disabled={!globalForm.titre || !globalForm.message}
            >
              <Send size={14} />
              Envoyer à tous
            </Button>
          </div>
        </Card>

        {/* ── Notification ciblée ── */}
        <Card className="p-6">
          <div className="flex items-center gap-3 mb-6">
            <div className="w-10 h-10 rounded-xl bg-purple/10 border border-purple/20
                            flex items-center justify-center">
              <User size={18} className="text-purple-300" />
            </div>
            <div>
              <h3 className="font-bold text-white">Notification ciblée</h3>
              <p className="text-xs text-gray-400">Envoyer à un joueur spécifique</p>
            </div>
          </div>

          <div className="space-y-4">
            <Input
              label="Numéro de téléphone du joueur"
              value={targetForm.telephone}
              onChange={e => setTargetForm(p => ({ ...p, telephone: e.target.value }))}
              placeholder="+22600000000"
            />
            <Select
              label="Type"
              value={targetForm.type}
              onChange={e => setTargetForm(p => ({ ...p, type: e.target.value }))}
              options={TYPES}
            />
            <Input
              label="Titre"
              value={targetForm.titre}
              onChange={e => setTargetForm(p => ({ ...p, titre: e.target.value }))}
              placeholder="Ex: Votre compte a été mis à jour"
            />
            <div className="space-y-1.5">
              <label className="text-sm font-semibold text-gray-300 block">
                Message
              </label>
              <textarea
                value={targetForm.message}
                onChange={e => setTargetForm(p => ({ ...p, message: e.target.value }))}
                rows={5}
                placeholder="Message personnalisé pour ce joueur..."
                className="w-full bg-surface2 border border-border rounded-xl px-3
                           py-2.5 text-white placeholder-gray-500 focus:outline-none
                           focus:border-gold transition-colors text-sm resize-none"
              />
            </div>

            <label className="flex items-center gap-2 mt-4 cursor-pointer">
              <input 
                type="checkbox" 
                className="w-4 h-4 rounded border-gray-600 bg-surface text-gold focus:ring-gold"
                checked={targetForm.send_sms}
                onChange={e => setTargetForm(p => ({ ...p, send_sms: e.target.checked }))}
              />
              <span className="text-sm text-gray-300 font-semibold">📱 Envoyer aussi par SMS</span>
            </label>

            <Button
              className="w-full"
              onClick={sendTargeted}
              loading={targetLoading}
              disabled={!targetForm.telephone || !targetForm.titre || !targetForm.message}
            >
              <Send size={14} />
              Envoyer au joueur
            </Button>
          </div>
        </Card>

      </div>

      {/* Guide des types */}
      <Card className="p-5">
        <h3 className="font-bold text-white mb-4">Types de notifications</h3>
        <div className="grid grid-cols-2 md:grid-cols-5 gap-3">
          {[
            { icon: '⚙️', type: 'systeme',   desc: 'Infos système, mises à jour' },
            { icon: '🎁', type: 'promo',     desc: 'Promotions, offres spéciales' },
            { icon: '💰', type: 'paiement',  desc: 'Dépôts, retraits, achats'    },
            { icon: '🏆', type: 'gain',      desc: 'Gains, félicitations'         },
            { icon: '🚚', type: 'livraison', desc: 'Suivi de livraison'           },
          ].map(({ icon, type, desc }) => (
            <div key={type}
              className="bg-surface2 rounded-xl p-3 text-center">
              <span className="text-2xl">{icon}</span>
              <p className="text-xs font-bold text-gray-300 mt-1 capitalize">{type}</p>
              <p className="text-xs text-gray-500 mt-0.5">{desc}</p>
            </div>
          ))}
        </div>
      </Card>
    </div>
  )
}