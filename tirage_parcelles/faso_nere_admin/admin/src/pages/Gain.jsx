// src/pages/Gains.jsx
import { useEffect, useState } from 'react'
import { Truck, CheckCircle, Phone, MapPin } from 'lucide-react'
import toast from 'react-hot-toast'
import api from '../api/client'
import { fmt, fmtDateTime, livraisonColor } from '../utils/format'
import {
  PageHeader, Card, Table, Badge, Button,
  Select, Modal, Input, PageLoader,
} from '../components/UI'

const STATUTS = [
  { value: '',           label: 'Tous les statuts'  },
  { value: 'en_attente', label: '⏳ En attente'      },
  { value: 'contacte',   label: '📞 Contacté'        },
  { value: 'en_cours',   label: '🚚 En cours'        },
  { value: 'livre',      label: '✅ Livré'            },
  { value: 'annule',     label: '❌ Annulé'           },
]

export default function Gains() {
  const [gains,   setGains]   = useState([])
  const [loading, setLoading] = useState(true)
  const [statut,  setStatut]  = useState('')

  // Modal livraison
  const [livrModal,  setLivrModal]  = useState(null) // gain
  const [livrForm,   setLivrForm]   = useState({ statut: '', notes: '' })
  const [livrLoading,setLivrLoading]= useState(false)

  const loadGains = async () => {
    setLoading(true)
    try {
      const params = statut ? `?statut=${statut}` : ''
      const { data } = await api.get(`/admin/gains${params}`)
      setGains(data.gains)
    } catch { toast.error('Erreur chargement gains') }
    finally  { setLoading(false) }
  }

  useEffect(() => { loadGains() }, [statut])

  const openLivraison = (gain) => {
    setLivrForm({
      statut: gain.livraison_statut ?? gain.statut_livraison ?? 'en_attente',
      notes:  gain.notes ?? '',
    })
    setLivrModal(gain)
  }

  const saveLivraison = async () => {
    setLivrLoading(true)
    try {
      const params = new URLSearchParams({
        statut: livrForm.statut,
        ...(livrForm.notes && { notes: livrForm.notes }),
      })
      await api.put(`/admin/gains/${livrModal.tirage_id}/livraison?${params}`)
      toast.success('Livraison mise à jour')
      setLivrModal(null)
      loadGains()
    } catch (e) { toast.error(e.response?.data?.detail ?? 'Erreur') }
    finally { setLivrLoading(false) }
  }

  // Compteurs par statut
  const counts = STATUTS.slice(1).reduce((acc, s) => {
    acc[s.value] = gains.filter(g =>
      (g.livraison_statut ?? g.statut_livraison) === s.value
    ).length
    return acc
  }, {})

  return (
    <div className="p-6 space-y-6">
      <PageHeader
        title="Gains & Livraisons"
        subtitle={`${gains.length} gain${gains.length > 1 ? 's' : ''} distribué${gains.length > 1 ? 's' : ''}`}
      />

      {/* Compteurs */}
      <div className="grid grid-cols-2 md:grid-cols-5 gap-3">
        {STATUTS.slice(1).map(s => (
          <button key={s.value}
            onClick={() => setStatut(s.value === statut ? '' : s.value)}
            className={`p-3 rounded-xl border text-left transition-all ${
              statut === s.value
                ? 'border-gold bg-gold/10'
                : 'border-border bg-surface hover:bg-surface2'
            }`}>
            <p className="text-xs text-gray-400 mb-1">{s.label}</p>
            <p className="text-xl font-black text-white">{counts[s.value] ?? 0}</p>
          </button>
        ))}
      </div>

      {/* Filtre */}
      <div className="flex gap-3">
        <Select value={statut} onChange={e => setStatut(e.target.value)}
          options={STATUTS} className="w-52" />
      </div>

      <Card>
        {loading ? <PageLoader /> : (
          <Table headers={['Gagnant', 'Cadeau', 'Lot', 'Valeur',
                           'Statut livraison', 'Date tirage', 'Actions']}>
            {gains.map(g => (
              <tr key={g.tirage_id}
                className="border-b border-border/50 hover:bg-surface2/50 transition-colors">

                {/* Gagnant */}
                <td className="px-4 py-3">
                  <p className="font-semibold text-white text-sm">
                    {g.nom} {g.prenom}
                  </p>
                  <p className="text-xs text-gray-500 flex items-center gap-1 mt-0.5">
                    <Phone size={10} /> {g.telephone}
                  </p>
                  {g.ville && (
                    <p className="text-xs text-gray-500 flex items-center gap-1">
                      <MapPin size={10} /> {g.ville}
                    </p>
                  )}
                </td>

                {/* Cadeau */}
                <td className="px-4 py-3">
                  <p className="text-sm text-white font-medium">{g.cadeau}</p>
                  <p className="text-xs text-gray-500 capitalize">{g.categorie}</p>
                </td>

                <td className="px-4 py-3 text-sm text-gray-300">{g.lot}</td>

                <td className="px-4 py-3 text-sm font-bold text-gold">
                  {fmt(g.valeur_gagnee)} FCFA
                </td>

                {/* Statut livraison */}
                <td className="px-4 py-3">
                  {g.is_converted ? (
                    <Badge className="bg-gray-500/20 text-gray-400 border-gray-500/30">
                      Converti en crédit
                    </Badge>
                  ) : (
                    <Badge className={livraisonColor(
                      g.livraison_statut ?? g.statut_livraison
                    )}>
                      {(g.livraison_statut ?? g.statut_livraison ?? 'en_attente')
                        .replace('_', ' ')}
                    </Badge>
                  )}
                </td>

                <td className="px-4 py-3 text-xs text-gray-500">
                  {fmtDateTime(g.date_tirage)}
                </td>

                {/* Actions */}
                <td className="px-4 py-3">
                  {g.is_converted ? (
                    <span className="text-xs text-gray-500 italic">Aucune action possible</span>
                  ) : (
                    <Button variant="secondary" size="sm"
                      onClick={() => openLivraison(g)}>
                      <Truck size={13} /> Livraison
                    </Button>
                  )}
                </td>
              </tr>
            ))}
          </Table>
        )}
      </Card>

      {/* Modal livraison */}
      <Modal
        open={!!livrModal}
        onClose={() => setLivrModal(null)}
        title="Mettre à jour la livraison"
        footer={<>
          <Button variant="secondary" onClick={() => setLivrModal(null)}>
            Annuler
          </Button>
          <Button onClick={saveLivraison} loading={livrLoading}>
            <CheckCircle size={14} /> Sauvegarder
          </Button>
        </>}
      >
        {livrModal && (
          <div className="space-y-4">
            {/* Info gagnant */}
            <div className="bg-surface2 rounded-xl p-4 space-y-2 text-sm">
              <p><span className="text-gray-400">Gagnant :</span>{' '}
                <span className="text-white font-semibold">
                  {livrModal.nom} {livrModal.prenom}
                </span>
              </p>
              <p><span className="text-gray-400">Tél :</span>{' '}
                <span className="text-white">{livrModal.telephone}</span>
              </p>
              <p><span className="text-gray-400">Cadeau :</span>{' '}
                <span className="text-gold font-semibold">{livrModal.cadeau}</span>
              </p>
              <p><span className="text-gray-400">Valeur :</span>{' '}
                <span className="text-gold">{fmt(livrModal.valeur_gagnee)} FCFA</span>
              </p>
            </div>

            <Select
              label="Statut de livraison"
              value={livrForm.statut}
              onChange={e => setLivrForm(p => ({ ...p, statut: e.target.value }))}
              options={STATUTS.slice(1).map(s => ({
                value: s.value,
                label: s.label,
              }))}
            />

            <div className="space-y-1.5">
              <label className="text-sm font-semibold text-gray-300 block">
                Notes (optionnel)
              </label>
              <textarea
                value={livrForm.notes}
                onChange={e => setLivrForm(p => ({ ...p, notes: e.target.value }))}
                rows={3}
                placeholder="Ex: Contacté le 12/01, rendez-vous fixé..."
                className="w-full bg-surface2 border border-border rounded-xl px-3
                           py-2.5 text-white placeholder-gray-500 focus:outline-none
                           focus:border-gold transition-colors text-sm resize-none"
              />
            </div>
          </div>
        )}
      </Modal>
    </div>
  )
}