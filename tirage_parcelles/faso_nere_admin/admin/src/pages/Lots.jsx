// src/pages/Lots.jsx
import { useEffect, useState } from 'react'
import { Plus, Pencil, Trash2, ToggleLeft, ToggleRight, AlertTriangle } from 'lucide-react'
import toast from 'react-hot-toast'
import api from '../api/client'
import { fmt } from '../utils/format'
import {
  PageHeader, Card, Button, Badge, Modal,
  Input, Select, ConfirmDialog, PageLoader,
} from '../components/UI'

const CATEGORIES = [
  { value: 'terrain',   label: 'Terrain'   },
  { value: 'ciment',    label: 'Ciment'    },
  { value: 'materiaux', label: 'Matériaux' },
  { value: 'aucun',     label: 'Aucun'     },
]

const emptyGift = {
  nom: '', description: '', icon: '🎁',
  prix_reel: '', categorie: 'terrain',
  is_winner: true, quantite: 1,
}

export default function Lots() {
  const [lots,    setLots]    = useState([])
  const [loading, setLoading] = useState(true)
  const [openLot, setOpenLot] = useState(null) // lot dont on voit les cadeaux

  // Modals cadeaux
  const [giftModal,   setGiftModal]   = useState(null) // { mode: 'add'|'edit', data, lot_id }
  const [giftLoading, setGiftLoading] = useState(false)
  const [giftForm,    setGiftForm]    = useState(emptyGift)
  const [deleteGift,  setDeleteGift]  = useState(null)

  // Modals lot
  const [lotModal,    setLotModal]    = useState(null) // { mode: 'edit', data }
  const [lotForm,     setLotForm]     = useState({})
  const [lotLoading,  setLotLoading]  = useState(false)
  const [toutPerdant, setToutPerdant] = useState(null) // lot_id

  const loadLots = async () => {
    setLoading(true)
    try {
      const { data } = await api.get('/admin/lots')
      setLots(data.lots)
    } catch { toast.error('Erreur chargement lots') }
    finally  { setLoading(false) }
  }

  useEffect(() => { loadLots() }, [])

  // ── Modifier lot ─────────────────────────────────────────────
  const saveLot = async () => {
    setLotLoading(true)
    try {
      await api.put(`/admin/lots/${lotModal.data.id}`, lotForm)
      toast.success('Lot modifié')
      setLotModal(null)
      loadLots()
    } catch (e) { toast.error(e.response?.data?.detail ?? 'Erreur') }
    finally { setLotLoading(false) }
  }

  // ── Ajouter / modifier cadeau ─────────────────────────────────
  const saveGift = async () => {
    setGiftLoading(true)
    try {
      const payload = {
        ...giftForm,
        prix_reel: parseInt(giftForm.prix_reel) || 0,
        quantite:  parseInt(giftForm.quantite)  || 1,
        lot_id:    giftModal.lot_id,
      }
      if (giftModal.mode === 'add') {
        await api.post('/admin/cadeaux', payload)
        toast.success('Cadeau ajouté')
      } else {
        await api.put(`/admin/cadeaux/${giftModal.data.id}`, payload)
        toast.success('Cadeau modifié')
      }
      setGiftModal(null)
      loadLots()
    } catch (e) { toast.error(e.response?.data?.detail ?? 'Erreur') }
    finally { setGiftLoading(false) }
  }

  // ── Supprimer cadeau ──────────────────────────────────────────
  const deleteGiftConfirm = async () => {
    setGiftLoading(true)
    try {
      await api.delete(`/admin/cadeaux/${deleteGift.id}`)
      toast.success('Cadeau supprimé')
      setDeleteGift(null)
      loadLots()
    } catch (e) { toast.error(e.response?.data?.detail ?? 'Erreur') }
    finally { setGiftLoading(false) }
  }

  // ── Tout perdant / Restaurer ──────────────────────────────────
  const handleToutPerdant = async (lotId, restore = false) => {
    try {
      const url = restore
        ? `/admin/lots/${lotId}/restaurer`
        : `/admin/lots/${lotId}/tout-perdant`
      await api.put(url, {})
      toast.success(restore ? 'Cadeaux restaurés' : 'Tous les cadeaux sont maintenant perdants')
      setToutPerdant(null)
      loadLots()
    } catch (e) { toast.error(e.response?.data?.detail ?? 'Erreur') }
  }

  if (loading) return <PageLoader />

  return (
    <div className="p-6 space-y-6">
      <PageHeader title="Lots & Cadeaux" subtitle="Gérez les lots et leurs cadeaux" />

      {lots.map(lot => (
        <Card key={lot.id}>
          {/* En-tête lot */}
          <div className="p-5 border-b border-border">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <span className="text-3xl">{lot.icon}</span>
                <div>
                  <div className="flex items-center gap-2">
                    <h3 className="font-black text-white text-lg">{lot.nom}</h3>
                    <Badge className={lot.is_active
                      ? 'bg-green-500/10 text-green-400 border-green-500/30'
                      : 'bg-red-500/10 text-red-400 border-red-500/30'}>
                      {lot.is_active ? 'Actif' : 'Inactif'}
                    </Badge>
                  </div>
                  <p className="text-sm text-gray-400">
                    {lot.nb_cadeaux} cadeaux · {fmt(lot.prix_min)}–{fmt(lot.prix_max)} FCFA
                  </p>
                </div>
              </div>

              <div className="flex gap-2">
                <Button variant="secondary" size="sm"
                  onClick={() => {
                    setLotForm({
                      nom: lot.nom, subtitle: lot.subtitle,
                      icon: lot.icon, is_active: lot.is_active,
                    })
                    setLotModal({ mode: 'edit', data: lot })
                  }}>
                  <Pencil size={13} /> Modifier
                </Button>
                <Button variant="danger" size="sm"
                  onClick={() => setToutPerdant(lot.id)}>
                  <AlertTriangle size={13} /> Tout perdant
                </Button>
                <Button variant="secondary" size="sm"
                  onClick={() => handleToutPerdant(lot.id, true)}>
                  ↺ Restaurer
                </Button>
                <Button size="sm"
                  onClick={() => {
                    setGiftForm(emptyGift)
                    setGiftModal({ mode: 'add', lot_id: lot.id })
                    setOpenLot(lot.id)
                  }}>
                  <Plus size={13} /> Cadeau
                </Button>
                <Button variant="ghost" size="sm"
                  onClick={() => setOpenLot(openLot === lot.id ? null : lot.id)}>
                  {openLot === lot.id ? '▲ Réduire' : '▼ Voir cadeaux'}
                </Button>
              </div>
            </div>
          </div>

          {/* Liste cadeaux */}
          {openLot === lot.id && (
            <div className="divide-y divide-border/50">
              {(lot.cadeaux ?? []).length === 0
                ? <p className="text-gray-500 text-sm p-5">Aucun cadeau</p>
                : (lot.cadeaux ?? []).map(c => (
                  <div key={c.id}
                    className="flex items-center gap-4 px-5 py-3
                               hover:bg-surface2/30 transition-colors">
                    <span className="text-2xl">{c.icon}</span>
                    <div className="flex-1">
                      <div className="flex items-center gap-2">
                        <p className="text-sm font-semibold text-white">{c.nom}</p>
                        <Badge className={c.is_winner
                          ? 'bg-gold/10 text-gold border-gold/30'
                          : 'bg-gray-500/10 text-gray-400 border-gray-500/30'}>
                          {c.is_winner ? '🏆 Gagnant' : '❌ Perdant'}
                        </Badge>
                        <Badge className="bg-surface2 text-gray-400 border-border">
                          ×{c.quantite}
                        </Badge>
                      </div>
                      <p className="text-xs text-gray-500 mt-0.5">
                        {c.categorie} · {c.is_winner ? `${fmt(c.prix_reel)} FCFA` : 'Pas de gain'}
                      </p>
                    </div>
                    <div className="flex gap-1">
                      <button
                        onClick={() => {
                          setGiftForm({
                            nom: c.nom, description: c.description,
                            icon: c.icon, prix_reel: c.prix_reel,
                            categorie: c.categorie, is_winner: c.is_winner,
                            quantite: c.quantite,
                          })
                          setGiftModal({ mode: 'edit', data: c, lot_id: lot.id })
                        }}
                        className="p-1.5 rounded-lg hover:bg-surface2
                                   text-gray-400 hover:text-white transition-colors"
                      >
                        <Pencil size={13} />
                      </button>
                      <button
                        onClick={() => setDeleteGift(c)}
                        className="p-1.5 rounded-lg hover:bg-red-500/10
                                   text-gray-400 hover:text-red-400 transition-colors"
                      >
                        <Trash2 size={13} />
                      </button>
                    </div>
                  </div>
                ))}
            </div>
          )}
        </Card>
      ))}

      {/* Modal modifier lot */}
      <Modal open={!!lotModal} onClose={() => setLotModal(null)}
        title="Modifier le lot"
        footer={<>
          <Button variant="secondary" onClick={() => setLotModal(null)}>Annuler</Button>
          <Button onClick={saveLot} loading={lotLoading}>Sauvegarder</Button>
        </>}
      >
        <div className="space-y-4">
          <Input label="Nom" value={lotForm.nom ?? ''}
            onChange={e => setLotForm(p => ({ ...p, nom: e.target.value }))} />
          <Input label="Sous-titre" value={lotForm.subtitle ?? ''}
            onChange={e => setLotForm(p => ({ ...p, subtitle: e.target.value }))} />
          <Input label="Icône" value={lotForm.icon ?? ''}
            onChange={e => setLotForm(p => ({ ...p, icon: e.target.value }))} />
          <div className="flex items-center gap-3">
            <label className="text-sm text-gray-300">Actif</label>
            <button onClick={() => setLotForm(p => ({ ...p, is_active: !p.is_active }))}>
              {lotForm.is_active
                ? <ToggleRight size={28} className="text-gold" />
                : <ToggleLeft  size={28} className="text-gray-500" />}
            </button>
          </div>
        </div>
      </Modal>

      {/* Modal cadeau */}
      <Modal
        open={!!giftModal}
        onClose={() => setGiftModal(null)}
        title={giftModal?.mode === 'add' ? 'Ajouter un cadeau' : 'Modifier le cadeau'}
        footer={<>
          <Button variant="secondary" onClick={() => setGiftModal(null)}>Annuler</Button>
          <Button onClick={saveGift} loading={giftLoading}>Sauvegarder</Button>
        </>}
      >
        <div className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <Input label="Nom" value={giftForm.nom}
              onChange={e => setGiftForm(p => ({ ...p, nom: e.target.value }))} />
            <Input label="Icône" value={giftForm.icon}
              onChange={e => setGiftForm(p => ({ ...p, icon: e.target.value }))} />
          </div>
          <Input label="Description" value={giftForm.description}
            onChange={e => setGiftForm(p => ({ ...p, description: e.target.value }))} />
          <div className="grid grid-cols-2 gap-4">
            <Input label="Prix réel (FCFA)" type="number" value={giftForm.prix_reel}
              onChange={e => setGiftForm(p => ({ ...p, prix_reel: e.target.value }))} />
            <Input label="Quantité" type="number" value={giftForm.quantite}
              onChange={e => setGiftForm(p => ({ ...p, quantite: e.target.value }))} />
          </div>
          <Select label="Catégorie" value={giftForm.categorie}
            onChange={e => setGiftForm(p => ({ ...p, categorie: e.target.value }))}
            options={CATEGORIES} />
          <div className="flex items-center gap-3">
            <label className="text-sm text-gray-300">Cadeau gagnant</label>
            <button onClick={() => setGiftForm(p => ({ ...p, is_winner: !p.is_winner }))}>
              {giftForm.is_winner
                ? <ToggleRight size={28} className="text-gold" />
                : <ToggleLeft  size={28} className="text-gray-500" />}
            </button>
          </div>
        </div>
      </Modal>

      {/* Confirm supprimer cadeau */}
      <ConfirmDialog
        open={!!deleteGift}
        onClose={() => setDeleteGift(null)}
        onConfirm={deleteGiftConfirm}
        loading={giftLoading}
        title="Supprimer le cadeau"
        message={`Supprimer "${deleteGift?.nom}" ? Cette action est irréversible.`}
      />

      {/* Confirm tout perdant */}
      <ConfirmDialog
        open={!!toutPerdant}
        onClose={() => setToutPerdant(null)}
        onConfirm={() => handleToutPerdant(toutPerdant)}
        title="Rendre tous les cadeaux perdants"
        message="Tous les cadeaux de ce lot deviendront perdants. Les joueurs ne pourront plus gagner. Confirmer ?"
      />
    </div>
  )
}