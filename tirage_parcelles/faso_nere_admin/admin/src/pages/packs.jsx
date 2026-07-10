// src/pages/Packs.jsx
import { useEffect, useState } from 'react'
import { Pencil, ToggleLeft, ToggleRight } from 'lucide-react'
import toast from 'react-hot-toast'
import api from '../api/client'
import { fmt } from '../utils/format'
import {
  PageHeader, Card, Badge, Button,
  Modal, Input, PageLoader,
} from '../components/UI'

const emptyPack = {
  nom: '', tentatives: '', prix: '',
  prix_par_tentative: '', badge: '',
  is_popular: false, is_best_value: false, is_active: true,
}

const PACK_ICONS = ['🥉', '🥈', '🥇', '💎', '👑', '🏆']

export default function Packs() {
  const [packs,   setPacks]   = useState([])
  const [loading, setLoading] = useState(true)
  const [modal,   setModal]   = useState(null)   // { mode, data }
  const [form,    setForm]    = useState(emptyPack)
  const [saving,  setSaving]  = useState(false)

  const loadPacks = async () => {
    setLoading(true)
    try {
      const { data } = await api.get('/admin/packs')
      setPacks(data.packs)
    } catch { toast.error('Erreur chargement packs') }
    finally  { setLoading(false) }
  }

  useEffect(() => { loadPacks() }, [])

  const openAdd = () => {
    setForm(emptyPack)
    setModal({ mode: 'add' })
  }

  const openEdit = (pack) => {
    setForm({
      nom:               pack.nom          ?? '',
      tentatives:        pack.tentatives   ?? '',
      prix:              pack.prix         ?? '',
      prix_par_tentative: pack.prix_par_tentative ?? '',
      badge:             pack.badge        ?? '',
      is_popular:        pack.is_popular   ?? false,
      is_best_value:     pack.is_best_value ?? false,
      is_active:         pack.is_active    ?? true,
    })
    setModal({ mode: 'edit', data: pack })
  }

  const togglePackActive = async (pack) => {
    try {
      const newStatus = !pack.is_active
      await api.put(`/admin/packs/${pack.id}`, { is_active: newStatus })
      toast.success(newStatus ? 'Pack activé' : 'Pack désactivé')
      loadPacks()
    } catch (e) {
      toast.error(e.response?.data?.detail ?? 'Erreur')
    }
  }

  const savePack = async () => {
    setSaving(true)
    try {
      const payload = {
        ...form,
        tentatives:        parseInt(form.tentatives)        || 0,
        prix:              parseInt(form.prix)              || 0,
        prix_par_tentative: parseInt(form.prix_par_tentative) || 0,
        badge: form.badge || null,
      }
      if (modal.mode === 'add') {
        await api.post('/admin/packs', payload)
        toast.success('Pack créé')
      } else {
        await api.put(`/admin/packs/${modal.data.id}`, payload)
        toast.success('Pack mis à jour')
      }
      setModal(null)
      loadPacks()
    } catch (e) { toast.error(e.response?.data?.detail ?? 'Erreur') }
    finally { setSaving(false) }
  }

  if (loading) return <PageLoader />

  return (
    <div className="p-6 space-y-6">
      <PageHeader
        title="Packs de tentatives"
        subtitle="Gérez les packs disponibles à l'achat"
        actions={
          <Button onClick={openAdd}>
            ➕ Créer un pack
          </Button>
        }
      />

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {packs.map((pack, i) => (
          <Card key={pack.id} className="p-5 relative overflow-hidden">
            {/* Badge populaire / meilleur choix */}
            {(pack.is_popular || pack.is_best_value) && (
              <div className="absolute top-3 right-3">
                <Badge className={
                  pack.is_best_value
                    ? 'bg-gold/20 text-gold border-gold/40'
                    : 'bg-purple/20 text-purple-300 border-purple/40'
                }>
                  {pack.badge ?? (pack.is_best_value ? 'Meilleur choix' : 'Populaire')}
                </Badge>
              </div>
            )}

            {/* Icône + nom */}
            <div className="flex items-center gap-3 mb-4">
              <div className="w-12 h-12 rounded-xl bg-gold/10 border border-gold/20
                              flex items-center justify-center text-2xl">
                {PACK_ICONS[i] ?? '🎟️'}
              </div>
              <div>
                <p className="font-black text-white text-lg">
                  {pack.nom || pack.tentatives + ' tentatives'}
                </p>
                <button
                  onClick={() => togglePackActive(pack)}
                  className="focus:outline-none block mt-1"
                >
                  <Badge className={
                    pack.is_active
                      ? 'bg-green-500/10 text-green-400 border-green-500/30 hover:bg-green-500/20 transition-all'
                      : 'bg-red-500/10 text-red-400 border-red-500/30 hover:bg-red-500/20 transition-all'
                  }>
                    {pack.is_active ? '● Actif' : '○ Inactif'}
                  </Badge>
                </button>
              </div>
            </div>

            {/* Stats */}
            <div className="space-y-2 mb-4">
              <div className="flex justify-between text-sm">
                <span className="text-gray-400">Tentatives</span>
                <span className="font-bold text-white">{pack.tentatives}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-gray-400">Prix</span>
                <span className="font-bold text-gold">{fmt(pack.prix)} FCFA</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-gray-400">Prix / tentative</span>
                <span className="font-bold text-gray-300">
                  {fmt(pack.prix_par_tentative)} FCFA
                </span>
              </div>
            </div>

            {/* Bouton modifier */}
            <Button variant="secondary" size="sm" className="w-full"
              onClick={() => openEdit(pack)}>
              <Pencil size={13} /> Modifier
            </Button>
          </Card>
        ))}
      </div>

      {/* Modal modifier/créer pack */}
      <Modal
        open={!!modal}
        onClose={() => setModal(null)}
        title={modal?.mode === 'add' ? 'Créer un pack' : 'Modifier le pack'}
        footer={<>
          <Button variant="secondary" onClick={() => setModal(null)}>
            Annuler
          </Button>
          <Button onClick={savePack} loading={saving}>
            Sauvegarder
          </Button>
        </>}
      >
        <div className="space-y-4">
          <Input label="Nom du pack" value={form.nom}
            onChange={e => setForm(p => ({ ...p, nom: e.target.value }))}
            placeholder="Ex: Pack Gold" />

          <div className="grid grid-cols-2 gap-4">
            <Input label="Tentatives" type="number" value={form.tentatives}
              onChange={e => setForm(p => ({ ...p, tentatives: e.target.value }))} />
            <Input label="Prix (FCFA)" type="number" value={form.prix}
              onChange={e => setForm(p => ({ ...p, prix: e.target.value }))} />
          </div>

          <Input label="Prix / tentative (FCFA)" type="number"
            value={form.prix_par_tentative}
            onChange={e => setForm(p => ({ ...p, prix_par_tentative: e.target.value }))} />

          <Input label="Badge (optionnel)" value={form.badge}
            onChange={e => setForm(p => ({ ...p, badge: e.target.value }))}
            placeholder="Ex: Populaire, Meilleur choix..." />

          {/* Toggles */}
          <div className="space-y-3">
            {[
              { key: 'is_active',    label: 'Pack actif'         },
              { key: 'is_popular',   label: 'Marquer populaire'  },
              { key: 'is_best_value',label: 'Meilleur choix'     },
            ].map(({ key, label }) => (
              <div key={key} className="flex items-center justify-between">
                <label className="text-sm text-gray-300">{label}</label>
                <button
                  type="button"
                  onClick={(e) => {
                    e.preventDefault();
                    setForm(p => ({ ...p, [key]: !p[key] }));
                  }}
                  className="focus:outline-none"
                >
                  {form[key]
                    ? <ToggleRight size={28} className="text-gold" />
                    : <ToggleLeft  size={28} className="text-gray-500" />}
                </button>
              </div>
            ))}
          </div>
        </div>
      </Modal>
    </div>
  )
}