import { useEffect, useState, useCallback } from 'react'
import {
  MapPin, Plus, Users, CalendarDays, Trophy, ToggleLeft,
  ToggleRight, Upload, Eye, Shuffle, ImageIcon
} from 'lucide-react'
import toast from 'react-hot-toast'
import api from '../api/client'
import { fmtDateTime } from '../utils/format'
import {
  PageHeader, Card, Table, Badge, PageLoader, Button, Modal, Input
} from '../components/UI'

// ── Helpers ──────────────────────────────────────────────────
const STATUS_CONFIG = {
  active:   { label: 'En cours',  cls: 'bg-green-500/10 text-green-400 border-green-500/30'  },
  termine:  { label: 'Terminée',  cls: 'bg-gray-500/10 text-gray-400 border-gray-500/30'     },
  inactive: { label: 'Inactive',  cls: 'bg-red-500/10 text-red-400 border-red-500/30'        },
  gagnant:  { label: 'Tiré',      cls: 'bg-gold/10 text-gold border-gold/30'                  },
}

function getCampagneStatus(c) {
  if (!c.is_active) return STATUS_CONFIG.inactive
  if (c.tirage_effectue) return STATUS_CONFIG.gagnant
  const now = new Date()
  if (new Date(c.date_fin) < now) return STATUS_CONFIG.termine
  return STATUS_CONFIG.active
}

// ── Page principale ──────────────────────────────────────────
export default function Campagnes() {
  const [campagnes,  setCampagnes]  = useState([])
  const [loading,    setLoading]    = useState(true)
  const [createOpen, setCreateOpen] = useState(false)
  const [detailOpen, setDetailOpen] = useState(false)
  const [editOpen,   setEditOpen]   = useState(false)
  const [selected,   setSelected]   = useState(null)

  const load = useCallback(async () => {
    setLoading(true)
    try {
      const { data } = await api.get('/admin/campagnes')
      setCampagnes(data.campagnes || [])
    } catch {
      toast.error('Erreur chargement des campagnes')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => { load() }, [load])

  const toggle = async (c) => {
    try {
      await api.put(`/admin/campagnes/${c.id}/toggle`)
      toast.success(c.is_active ? 'Campagne désactivée' : 'Campagne activée')
      load()
    } catch {}
  }

  const openDetail = (c) => { setSelected(c); setDetailOpen(true) }

  return (
    <div className="p-6 space-y-6">
      <PageHeader
        title="Campagnes de Souscription"
        subtitle="Créez et gérez les campagnes de tirage au sort pour les terrains"
        actions={
          <Button onClick={() => setCreateOpen(true)}>
            <Plus size={16} /> Nouvelle Campagne
          </Button>
        }
      />

      {/* Statistiques rapides */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        {[
          { label: 'Total',     value: campagnes.length,                                      icon: MapPin,      color: 'text-blue-400'   },
          { label: 'En cours',  value: campagnes.filter(c => getCampagneStatus(c) === STATUS_CONFIG.active).length, icon: CalendarDays, color: 'text-green-400' },
          { label: 'Participants', value: campagnes.reduce((a, c) => a + c.nb_participants, 0), icon: Users,     color: 'text-gold'        },
          { label: 'Tirés',     value: campagnes.filter(c => c.tirage_effectue).length,        icon: Trophy,     color: 'text-purple-400'  },
        ].map(({ label, value, icon: Icon, color }) => (
          <Card key={label} className="p-4 flex items-center gap-3">
            <div className={`p-2 rounded-lg bg-surface2 ${color}`}><Icon size={20} /></div>
            <div>
              <p className="text-2xl font-black text-white">{value}</p>
              <p className="text-xs text-gray-400">{label}</p>
            </div>
          </Card>
        ))}
      </div>

      {/* Liste des campagnes */}
      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-5">
        {loading ? (
          <div className="col-span-3"><PageLoader /></div>
        ) : campagnes.length === 0 ? (
          <div className="col-span-3 text-center py-16 text-gray-500">
            <MapPin size={40} className="mx-auto mb-3 opacity-30" />
            <p>Aucune campagne. Créez-en une !</p>
          </div>
        ) : campagnes.map(c => (
          <CampagneCard
            key={c.id}
            campagne={c}
            onToggle={() => toggle(c)}
            onDetail={() => openDetail(c)}
            onRefresh={load}
          />
        ))}
      </div>

      {/* Modals */}
      <CreateModal open={createOpen} onClose={() => setCreateOpen(false)} onCreated={load} />
      {selected && !editOpen && (
        <DetailModal
          open={detailOpen}
          campagne={selected}
          onClose={() => { setDetailOpen(false); setSelected(null) }}
          onRefresh={load}
          onEdit={() => { setDetailOpen(false); setEditOpen(true) }}
        />
      )}
      {selected && editOpen && (
        <EditModal
          open={editOpen}
          campagne={selected}
          onClose={() => { setEditOpen(false); setDetailOpen(true) }}
          onUpdated={load}
        />
      )}
    </div>
  )
}

// ── Carte campagne ───────────────────────────────────────────
function CampagneCard({ campagne: c, onToggle, onDetail, onRefresh }) {
  const st        = getCampagneStatus(c)
  const isActive  = getCampagneStatus(c) === STATUS_CONFIG.active
  const baseUrl   = import.meta.env.VITE_API_BASE_URL || ''
  const imageUrl  = c.image_url ? `${baseUrl}${c.image_url}` : null

  return (
    <div className="bg-surface border border-border rounded-2xl overflow-hidden flex flex-col hover:border-gold/40 transition-all group">
      {/* Image */}
      <div className="relative h-44 bg-surface2 overflow-hidden">
        {imageUrl ? (
          <img
            src={imageUrl}
            alt={c.titre}
            className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
          />
        ) : (
          <div className="w-full h-full flex flex-col items-center justify-center text-gray-600 gap-2">
            <ImageIcon size={36} />
            <p className="text-xs">Aucune image</p>
          </div>
        )}
        <div className="absolute top-3 left-3">
          <Badge className={st.cls}>{st.label}</Badge>
        </div>
        <div className="absolute top-3 right-3">
          <Badge className={
            c.type_terrain === 'commercial'
              ? 'bg-purple-500/20 text-purple-300 border-purple-500/30'
              : 'bg-blue-500/20 text-blue-300 border-blue-500/30'
          }>
            {c.type_terrain === 'commercial' ? '🏢 Commercial' : '🏡 Habitation'}
          </Badge>
        </div>
      </div>

      {/* Contenu */}
      <div className="p-4 flex-1 flex flex-col gap-3">
        <div>
          <h3 className="font-bold text-white text-base truncate">{c.titre}</h3>
          {c.description && <p className="text-xs text-gray-400 mt-1 line-clamp-2">{c.description}</p>}
        </div>

        {/* Infos */}
        <div className="space-y-1.5 text-xs text-gray-400">
          <div className="flex items-center gap-2">
            <CalendarDays size={13} />
            <span>Début : {fmtDateTime(c.date_debut)}</span>
          </div>
          <div className="flex items-center gap-2">
            <CalendarDays size={13} />
            <span>Fin : {fmtDateTime(c.date_fin)}</span>
          </div>
          <div className="flex items-center gap-2">
            <Users size={13} />
            <span className="font-semibold text-white">{c.nb_participants} participant{c.nb_participants > 1 ? 's' : ''}</span>
          </div>
          <div className="flex items-center gap-2">
            <span className="text-gold font-bold">{c.frais_souscription.toLocaleString('fr-FR')} FCFA</span>
            <span>/ souscription</span>
          </div>
        </div>

        {/* Gagnant */}
        {c.tirage_effectue && c.gagnant_nom && (
          <div className="bg-gold/10 border border-gold/30 rounded-xl px-3 py-2 text-xs">
            <p className="text-gold font-bold">🏆 Gagnant(e)</p>
            <p className="text-white font-semibold">{c.gagnant_prenom} {c.gagnant_nom}</p>
          </div>
        )}

        {/* Actions */}
        <div className="mt-auto flex gap-2 pt-2">
          <Button variant="secondary" onClick={onDetail} className="flex-1 text-xs py-2">
            <Eye size={13} /> Détails
          </Button>
          <Button
            variant={c.is_active ? 'danger' : 'secondary'}
            onClick={onToggle}
            className="flex-1 text-xs py-2"
          >
            {c.is_active ? <><ToggleRight size={13} /> Désact.</> : <><ToggleLeft size={13} /> Activer</>}
          </Button>
        </div>
      </div>
    </div>
  )
}

// ── Modal création ───────────────────────────────────────────
function CreateModal({ open, onClose, onCreated }) {
  const [form, setForm] = useState({
    titre: '', description: '', type_terrain: 'habitation',
    frais_souscription: 10000,
    date_debut: '', date_fin: ''
  })
  const [image,    setImage]   = useState(null)
  const [preview,  setPreview] = useState(null)
  const [creating, setCreating] = useState(false)

  const handleFile = (e) => {
    const file = e.target.files[0]
    if (!file) return
    setImage(file)
    setPreview(URL.createObjectURL(file))
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    setCreating(true)
    try {
      const fd = new FormData()
      Object.entries(form).forEach(([k, v]) => fd.append(k, v))
      if (image) fd.append('image', image)
      await api.post('/admin/campagnes', fd, {
        headers: { 'Content-Type': 'multipart/form-data' }
      })
      toast.success('Campagne créée !')
      onCreated()
      onClose()
      setForm({ titre: '', description: '', type_terrain: 'habitation', frais_souscription: 10000, date_debut: '', date_fin: '' })
      setImage(null); setPreview(null)
    } catch (err) {
      toast.error(err.response?.data?.detail || 'Erreur lors de la création')
    } finally {
      setCreating(false)
    }
  }

  return (
    <Modal open={open} onClose={onClose} title="Créer une Campagne de Souscription">
      <form onSubmit={handleSubmit} className="space-y-4">
        {/* Upload image */}
        <div>
          <label className="text-sm font-semibold text-gray-300 block mb-2">Image du terrain</label>
          <label className="cursor-pointer flex flex-col items-center justify-center border-2 border-dashed border-border rounded-xl h-36 hover:border-gold transition-colors overflow-hidden relative">
            {preview ? (
              <img src={preview} alt="preview" className="w-full h-full object-cover absolute inset-0" />
            ) : (
              <div className="flex flex-col items-center gap-2 text-gray-500">
                <Upload size={24} />
                <span className="text-xs">Cliquez pour uploader (jpg/png/webp)</span>
              </div>
            )}
            <input type="file" accept="image/*" className="hidden" onChange={handleFile} />
          </label>
        </div>

        <Input label="Titre de la campagne" required value={form.titre}
          onChange={e => setForm({...form, titre: e.target.value})} />
        <Input label="Description (optionnel)" value={form.description}
          onChange={e => setForm({...form, description: e.target.value})} />

        <div>
          <label className="text-sm font-semibold text-gray-300 block mb-2">Type de terrain</label>
          <div className="grid grid-cols-2 gap-3">
            {[
              { value: 'habitation', label: '🏡 Habitation' },
              { value: 'commercial', label: '🏢 Commercial' },
            ].map(opt => (
              <button
                key={opt.value} type="button"
                onClick={() => setForm({...form, type_terrain: opt.value})}
                className={`p-3 rounded-xl border text-left transition-all ${
                  form.type_terrain === opt.value
                    ? 'border-gold bg-gold/10 text-gold'
                    : 'border-border text-gray-400 hover:border-gray-500'
                }`}
              >
                <p className="font-semibold text-sm">{opt.label}</p>
              </button>
            ))}
          </div>
        </div>

        <Input 
          type="number" 
          label="Frais de souscription (FCFA)" 
          required 
          value={form.frais_souscription}
          onChange={e => setForm({...form, frais_souscription: e.target.value})} 
        />

        {/* Dates */}
        <div className="grid grid-cols-2 gap-3">
          {[
            { key: 'date_debut', label: 'Date de début' },
            { key: 'date_fin',   label: 'Date de fin'   },
          ].map(({ key, label }) => (
            <div key={key} className="flex flex-col gap-1.5">
              <label className="text-sm font-semibold text-gray-300">{label}</label>
              <input
                type="datetime-local" required
                className="bg-bg border border-border rounded-xl px-4 py-2.5 text-sm text-white focus:outline-none focus:border-gold transition-colors"
                value={form[key]}
                onChange={e => setForm({...form, [key]: e.target.value})}
              />
            </div>
          ))}
        </div>

        <div className="pt-2 flex justify-end gap-3">
          <Button variant="secondary" type="button" onClick={onClose}>Annuler</Button>
          <Button type="submit" disabled={creating}>
            {creating ? 'Création...' : <><Plus size={14} /> Créer</>}
          </Button>
        </div>
      </form>
    </Modal>
  )
}

// ── Modal détail + participants + tirage ─────────────────────
function DetailModal({ open, campagne: c, onClose, onRefresh, onEdit }) {
  const [participants, setParticipants] = useState([])
  const [loading,      setLoading]      = useState(true)
  const [tirage,       setTirage]       = useState(false)
  const [uploadOpen,   setUploadOpen]   = useState(false)
  const [newImage,     setNewImage]     = useState(null)
  const [newPreview,   setNewPreview]   = useState(null)
  const baseUrl = import.meta.env.VITE_API_BASE_URL || ''

  const loadParticipants = useCallback(async () => {
    setLoading(true)
    try {
      const { data } = await api.get(`/admin/campagnes/${c.id}/participants`)
      setParticipants(data.participants || [])
    } catch {
      toast.error('Erreur chargement des participants')
    } finally { setLoading(false) }
  }, [c.id])

  useEffect(() => { if (open) loadParticipants() }, [open, loadParticipants])

  const handleTirage = async () => {
    if (!confirm(`Effectuer le tirage au sort parmi ${participants.length} participant(s) ? Cette action est irréversible.`)) return
    setTirage(true)
    try {
      const { data } = await api.post(`/admin/campagnes/${c.id}/tirer`)
      toast.success(`🏆 Gagnant : ${data.gagnant.prenom} ${data.gagnant.nom} (${data.gagnant.telephone})`)
      onRefresh()
      onClose()
    } catch (err) {
      toast.error(err.response?.data?.detail || 'Erreur lors du tirage')
    } finally { setTirage(false) }
  }

  const handleDelete = async () => {
    if (!confirm(`Voulez-vous vraiment supprimer cette campagne ? Toutes les souscriptions liées seront effacées.`)) return
    try {
      await api.delete(`/admin/campagnes/${c.id}`)
      toast.success('Campagne supprimée')
      onRefresh()
      onClose()
    } catch (err) {
      toast.error(err.response?.data?.detail || 'Erreur lors de la suppression')
    }
  }

  const handleUploadImage = async () => {
    if (!newImage) return
    const fd = new FormData()
    fd.append('image', newImage)
    try {
      await api.put(`/admin/campagnes/${c.id}/image`, fd, {
        headers: { 'Content-Type': 'multipart/form-data' }
      })
      toast.success('Image mise à jour !')
      setUploadOpen(false); setNewImage(null); setNewPreview(null)
      onRefresh()
    } catch { toast.error('Erreur upload image') }
  }

  const st = getCampagneStatus(c)

  return (
    <Modal open={open} onClose={onClose} title={c.titre}>
      <div className="space-y-5">
        {/* Image */}
        <div className="relative h-52 bg-surface2 rounded-xl overflow-hidden">
          {c.image_url ? (
            <img src={`${baseUrl}${c.image_url}`} alt={c.titre} className="w-full h-full object-cover" />
          ) : (
            <div className="w-full h-full flex items-center justify-center text-gray-600">
              <ImageIcon size={40} />
            </div>
          )}
          <button
            onClick={() => setUploadOpen(true)}
            className="absolute bottom-3 right-3 bg-black/60 hover:bg-black/80 text-white px-3 py-1.5 rounded-lg text-xs flex items-center gap-1.5 transition-colors"
          >
            <Upload size={12} /> Changer l'image
          </button>
        </div>

        {/* Upload image inline */}
        {uploadOpen && (
          <div className="flex flex-col gap-3 p-4 bg-surface2 rounded-xl border border-border">
            <label className="cursor-pointer flex items-center gap-3 border border-dashed border-border rounded-xl p-3 hover:border-gold transition-colors">
              {newPreview
                ? <img src={newPreview} alt="" className="w-16 h-16 object-cover rounded-lg" />
                : <div className="w-16 h-16 flex items-center justify-center bg-surface rounded-lg text-gray-600"><ImageIcon size={20} /></div>
              }
              <div>
                <p className="text-sm text-gray-300 font-medium">Sélectionner une image</p>
                <p className="text-xs text-gray-500">jpg/png/webp</p>
              </div>
              <input type="file" accept="image/*" className="hidden" onChange={e => {
                const f = e.target.files[0]; if (!f) return
                setNewImage(f); setNewPreview(URL.createObjectURL(f))
              }} />
            </label>
            <div className="flex gap-2">
              <Button onClick={handleUploadImage} disabled={!newImage} className="flex-1 text-xs">Valider</Button>
              <Button variant="secondary" onClick={() => { setUploadOpen(false); setNewImage(null); setNewPreview(null) }} className="flex-1 text-xs">Annuler</Button>
            </div>
          </div>
        )}

        {/* Infos */}
        <div className="grid grid-cols-2 gap-3 text-sm">
          {[
            { label: 'Statut',       value: <Badge className={st.cls}>{st.label}</Badge>         },
            { label: 'Type',         value: c.type_terrain === 'commercial' ? '🏢 Commercial' : '🏡 Habitation' },
            { label: 'Frais',        value: <span className="text-gold font-bold">{c.frais_souscription.toLocaleString('fr-FR')} FCFA</span> },
            { label: 'Participants', value: <span className="text-white font-bold">{c.nb_participants}</span> },
            { label: 'Début',        value: fmtDateTime(c.date_debut)                            },
            { label: 'Fin',          value: fmtDateTime(c.date_fin)                              },
          ].map(({ label, value }) => (
            <div key={label} className="bg-surface2 rounded-xl p-3">
              <p className="text-xs text-gray-500 mb-1">{label}</p>
              <div className="text-sm text-gray-200">{value}</div>
            </div>
          ))}
        </div>

        {/* Gagnant */}
        {c.tirage_effectue && c.gagnant_nom && (
          <div className="bg-gold/10 border border-gold/30 rounded-xl p-4 text-center">
            <p className="text-gold font-black text-lg">🏆 Gagnant(e) du tirage</p>
            <p className="text-white font-bold text-base mt-1">{c.gagnant_prenom} {c.gagnant_nom}</p>
          </div>
        )}

        {/* Participants */}
        <div>
          <p className="text-sm font-bold text-gray-200 mb-3 flex items-center gap-2">
            <Users size={15} /> Participants ({c.nb_participants})
          </p>
          {loading ? <PageLoader /> : (
            <div className="max-h-56 overflow-y-auto rounded-xl border border-border">
              <Table headers={['Nom', 'Téléphone', 'Ville', 'Montant', 'Date']}>
                {participants.length === 0 ? (
                  <tr><td colSpan={5} className="text-center p-4 text-gray-500 text-sm">Aucun participant</td></tr>
                ) : participants.map((p, i) => (
                  <tr key={i} className="border-b border-border/50 hover:bg-surface2/50 transition-colors text-sm">
                    <td className="px-4 py-2.5 font-medium text-white">{p.prenom} {p.nom}</td>
                    <td className="px-4 py-2.5 text-gray-400 font-mono">{p.telephone}</td>
                    <td className="px-4 py-2.5 text-gray-400">{p.ville || '—'}</td>
                    <td className="px-4 py-2.5 text-gold font-semibold">{p.montant_paye.toLocaleString('fr-FR')} FCFA</td>
                    <td className="px-4 py-2.5 text-gray-500 text-xs">{fmtDateTime(p.souscrit_le)}</td>
                  </tr>
                ))}
              </Table>
            </div>
          )}
        </div>

        {/* Tirage action & Delete & Edit */}
        <div className="pt-4 flex gap-3 border-t border-border/50">
          <Button
            variant="secondary"
            onClick={onEdit}
            className="flex-1 py-3 border-gray-600 hover:bg-gray-700"
          >
            <span className="font-bold">Modifier la campagne</span>
          </Button>

          <Button
            variant="danger"
            onClick={handleDelete}
            className="flex-1 py-3 bg-red-600 hover:bg-red-700"
          >
            <span className="font-bold">Supprimer la campagne</span>
          </Button>

          {!c.tirage_effectue ? (
            <Button
              onClick={handleTirage} disabled={tirage || participants.length === 0}
              className="flex-1 py-3 bg-gradient-to-r from-gold to-yellow-500 text-black hover:from-yellow-400 hover:to-gold"
            >
              {tirage ? 'Tirage en cours...' : (
                <span className="font-bold text-base flex items-center gap-2 justify-center">
                  Effectuer le tirage au sort 🎉
                </span>
              )}
            </Button>
          ) : (
            <div className="flex-1 bg-surface py-3 rounded-xl border border-border text-center text-sm font-semibold text-gray-500">
              Tirage déjà effectué
            </div>
          )}
        </div>
      </div>
    </Modal>
  )
}

// ── Modal édition ───────────────────────────────────────────
function EditModal({ open, campagne, onClose, onUpdated }) {
  const [form, setForm] = useState({
    titre: campagne.titre || '', 
    description: campagne.description || '', 
    type_terrain: campagne.type_terrain || 'habitation',
    frais_souscription: campagne.frais_souscription || 10000,
    // input datetime-local requires format YYYY-MM-DDTHH:MM
    date_debut: campagne.date_debut ? new Date(campagne.date_debut).toISOString().slice(0, 16) : '', 
    date_fin: campagne.date_fin ? new Date(campagne.date_fin).toISOString().slice(0, 16) : ''
  })
  const [updating, setUpdating] = useState(false)

  const handleSubmit = async (e) => {
    e.preventDefault()
    setUpdating(true)
    try {
      const fd = new FormData()
      Object.entries(form).forEach(([k, v]) => fd.append(k, v))
      await api.put(`/admin/campagnes/${campagne.id}`, fd, {
        headers: { 'Content-Type': 'multipart/form-data' }
      })
      toast.success('Campagne modifiée avec succès !')
      onUpdated()
      onClose()
    } catch (err) {
      toast.error(err.response?.data?.detail || 'Erreur lors de la modification')
    } finally {
      setUpdating(false)
    }
  }

  return (
    <Modal open={open} onClose={onClose} title="Modifier la Campagne">
      <form onSubmit={handleSubmit} className="space-y-4">
        <Input label="Titre de la campagne" required value={form.titre}
          onChange={e => setForm({...form, titre: e.target.value})} />
        <Input label="Description (optionnel)" value={form.description}
          onChange={e => setForm({...form, description: e.target.value})} />

        <div>
          <label className="text-sm font-semibold text-gray-300 block mb-2">Type de terrain</label>
          <div className="grid grid-cols-2 gap-3">
            {[
              { value: 'habitation', label: '🏡 Habitation' },
              { value: 'commercial', label: '🏢 Commercial' },
            ].map(opt => (
              <button
                key={opt.value} type="button"
                onClick={() => setForm({...form, type_terrain: opt.value})}
                className={`p-3 rounded-xl border text-left transition-all ${
                  form.type_terrain === opt.value
                    ? 'border-gold bg-gold/10 text-gold'
                    : 'border-border text-gray-400 hover:border-gray-500'
                }`}
              >
                <p className="font-semibold text-sm">{opt.label}</p>
              </button>
            ))}
          </div>
        </div>

        <Input 
          type="number" 
          label="Frais de souscription (FCFA)" 
          required 
          value={form.frais_souscription}
          onChange={e => setForm({...form, frais_souscription: e.target.value})} 
        />

        {/* Dates */}
        <div className="grid grid-cols-2 gap-3">
          {[
            { key: 'date_debut', label: 'Date de début' },
            { key: 'date_fin',   label: 'Date de fin'   },
          ].map(({ key, label }) => (
            <div key={key} className="flex flex-col gap-1.5">
              <label className="text-sm font-semibold text-gray-300">{label}</label>
              <input
                type="datetime-local" required
                className="bg-bg border border-border rounded-xl px-4 py-2.5 text-sm text-white focus:outline-none focus:border-gold transition-colors"
                value={form[key]}
                onChange={e => setForm({...form, [key]: e.target.value})}
              />
            </div>
          ))}
        </div>

        <div className="pt-2 flex justify-end gap-3">
          <Button variant="secondary" type="button" onClick={onClose}>Annuler</Button>
          <Button type="submit" disabled={updating}>
            {updating ? 'Enregistrement...' : 'Enregistrer les modifications'}
          </Button>
        </div>
      </form>
    </Modal>
  )
}

