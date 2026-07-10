import { useEffect, useState, useCallback } from 'react'
import { Ticket, Plus, Ban, CheckCircle, Trash2 } from 'lucide-react'
import toast from 'react-hot-toast'
import api from '../api/client'
import { fmtDateTime } from '../utils/format'
import {
  PageHeader, Card, Table, Badge, PageLoader, Button, Modal, Input
} from '../components/UI'

export default function PromoCodes() {
  const [codes, setCodes] = useState([])
  const [loading, setLoading] = useState(true)

  // Modal création
  const [createModal, setCreateModal] = useState(false)
  const [formData, setFormData] = useState({
    code: '',
    tentatives_offertes: 1,
    max_utilisations: '',
    expires_at: ''
  })
  const [creating, setCreating] = useState(false)

  const loadCodes = useCallback(async () => {
    setLoading(true)
    try {
      const { data } = await api.get('/admin/promo-codes')
      setCodes(data.promo_codes || [])
    } catch {
      toast.error('Erreur chargement des codes promo')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => { loadCodes() }, [loadCodes])

  const toggleStatus = async (code) => {
    try {
      await api.put(`/admin/promo-codes/${code.id}/toggle`)
      toast.success(code.is_active ? 'Code désactivé' : 'Code activé')
      loadCodes()
    } catch (e) {
      toast.error(e.response?.data?.detail || 'Erreur modification statut')
    }
  }

  const handleCreate = async (e) => {
    e.preventDefault()
    setCreating(true)
    try {
      const payload = {
        code: formData.code.trim().toUpperCase() || Math.random().toString(36).substring(2, 10).toUpperCase(),
        tentatives_offertes: parseInt(formData.tentatives_offertes),
        max_utilisations: formData.max_utilisations ? parseInt(formData.max_utilisations) : null,
        expires_at: formData.expires_at ? new Date(formData.expires_at).toISOString() : null
      }
      await api.post('/admin/promo-codes', payload)
      toast.success('Code promo créé !')
      setCreateModal(false)
      setFormData({ code: '', tentatives_offertes: 1, max_utilisations: '', expires_at: '' })
      loadCodes()
    } catch (e) {
      toast.error(e.response?.data?.detail || 'Erreur lors de la création')
    } finally {
      setCreating(false)
    }
  }

  return (
    <div className="p-6 space-y-6">
      <PageHeader
        title="Codes Promo (Vouchers)"
        subtitle="Gérez les codes de tentatives gratuites offerts à vos joueurs"
        actions={
          <Button onClick={() => setCreateModal(true)}>
            <Plus size={16} /> Générer un Code
          </Button>
        }
      />

      <Card>
        {loading ? <PageLoader /> : (
          <Table headers={['Code', 'Tentatives offertes', 'Utilisations', 'Expiration', 'Statut', 'Actions']}>
            {codes.length === 0 ? (
              <tr><td colSpan={6} className="text-center p-4 text-gray-500">Aucun code promo créé</td></tr>
            ) : codes.map(c => {
              const isExpired = c.expires_at && new Date(c.expires_at) < new Date()
              const isFull = c.max_utilisations && c.utilisations_actuelles >= c.max_utilisations
              const displayStatus = !c.is_active ? 'Désactivé' : (isExpired ? 'Expiré' : (isFull ? 'Épuisé' : 'Actif'))
              
              let statusColor = 'bg-gray-500/10 text-gray-400 border-gray-500/30'
              if (displayStatus === 'Actif') statusColor = 'bg-green-500/10 text-green-400 border-green-500/30'
              else if (displayStatus === 'Expiré' || displayStatus === 'Épuisé') statusColor = 'bg-orange-500/10 text-orange-400 border-orange-500/30'

              return (
                <tr key={c.id} className="border-b border-border/50 hover:bg-surface2/50 transition-colors">
                  <td className="px-4 py-3">
                    <span className="font-mono text-gold font-bold bg-gold/10 px-2 py-1 rounded border border-gold/20">
                      {c.code}
                    </span>
                  </td>
                  <td className="px-4 py-3 font-bold text-white">🎁 {c.tentatives_offertes}</td>
                  <td className="px-4 py-3">
                    <span className={isFull ? 'text-orange-400 font-bold' : 'text-gray-300'}>
                      {c.utilisations_actuelles} {c.max_utilisations ? `/ ${c.max_utilisations}` : '(Illimité)'}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-sm text-gray-400">
                    {c.expires_at ? fmtDateTime(c.expires_at) : 'Jamais'}
                  </td>
                  <td className="px-4 py-3">
                    <Badge className={statusColor}>{displayStatus}</Badge>
                  </td>
                  <td className="px-4 py-3">
                    <Button 
                      variant={c.is_active ? 'danger' : 'secondary'} 
                      onClick={() => toggleStatus(c)}
                    >
                      {c.is_active ? <><Ban size={14} /> Désactiver</> : <><CheckCircle size={14} /> Activer</>}
                    </Button>
                  </td>
                </tr>
              )
            })}
          </Table>
        )}
      </Card>

      <Modal open={createModal} onClose={() => setCreateModal(false)} title="Créer un Code Promo">
        <form onSubmit={handleCreate} className="space-y-4">
          <Input 
            label="Texte du Code (Optionnel)" 
            placeholder="Ex: INFLUENCEUR2024 (Laisser vide pour générer au hasard)"
            value={formData.code}
            onChange={e => setFormData({...formData, code: e.target.value.toUpperCase()})}
          />
          <Input 
            label="Tentatives offertes" 
            type="number"
            required
            min="1"
            value={formData.tentatives_offertes}
            onChange={e => setFormData({...formData, tentatives_offertes: e.target.value})}
          />
          <Input 
            label="Limite totale d'utilisations (Optionnel)" 
            type="number"
            min="1"
            placeholder="Ex: 100 (Les 100 premiers)"
            value={formData.max_utilisations}
            onChange={e => setFormData({...formData, max_utilisations: e.target.value})}
          />
          <div className="flex flex-col gap-1.5">
            <label className="text-sm font-semibold text-gray-300">Date d'expiration (Optionnel)</label>
            <input 
              type="datetime-local" 
              className="bg-bg border border-border rounded-xl px-4 py-2.5 text-sm text-white focus:outline-none focus:border-gold transition-colors"
              value={formData.expires_at}
              onChange={e => setFormData({...formData, expires_at: e.target.value})}
            />
          </div>
          <div className="pt-4 flex justify-end gap-3">
            <Button variant="secondary" onClick={() => setCreateModal(false)} type="button">Annuler</Button>
            <Button type="submit" disabled={creating} className={creating ? 'opacity-50 cursor-not-allowed' : ''}>
              {creating ? 'Création...' : 'Générer le Code'}
            </Button>
          </div>
        </form>
      </Modal>
    </div>
  )
}
