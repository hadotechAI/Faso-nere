// src/utils/format.js

/** Formate un nombre avec espaces : 1000000 → "1 000 000" */
export const fmt = (v) => {
  if (v === null || v === undefined) return '—'
  return Number(v).toLocaleString('fr-FR')
}

/** Formate une date ISO en "12 jan. 2025" */
export const fmtDate = (iso) => {
  if (!iso) return '—'
  try {
    return new Date(iso).toLocaleDateString('fr-FR', {
      day:   'numeric',
      month: 'short',
      year:  'numeric',
    })
  } catch { return iso }
}

/** Formate une date ISO en "12 jan. 2025 à 14h30" */
export const fmtDateTime = (iso) => {
  if (!iso) return '—'
  try {
    return new Date(iso).toLocaleString('fr-FR', {
      day:    'numeric',
      month:  'short',
      year:   'numeric',
      hour:   '2-digit',
      minute: '2-digit',
    })
  } catch { return iso }
}

/** Formate une date relative : "il y a 2h" */
export const fmtRelative = (iso) => {
  if (!iso) return '—'
  try {
    const diff = Date.now() - new Date(iso).getTime()
    const mins = Math.floor(diff / 60000)
    if (mins < 1)   return 'À l\'instant'
    if (mins < 60)  return `Il y a ${mins} min`
    const hrs = Math.floor(mins / 60)
    if (hrs  < 24)  return `Il y a ${hrs}h`
    const days = Math.floor(hrs / 24)
    if (days < 7)   return `Il y a ${days}j`
    return fmtDate(iso)
  } catch { return iso }
}

/** Badge couleur selon statut livraison */
export const livraisonColor = (statut) => {
  const map = {
    en_attente: 'bg-yellow-500/10 text-yellow-400 border-yellow-500/30',
    contacte:   'bg-blue-500/10   text-blue-400   border-blue-500/30',
    en_cours:   'bg-purple-500/10 text-purple-400 border-purple-500/30',
    livre:      'bg-green-500/10  text-green-400  border-green-500/30',
    annule:     'bg-red-500/10    text-red-400    border-red-500/30',
  }
  return map[statut] ?? 'bg-gray-500/10 text-gray-400 border-gray-500/30'
}

/** Badge couleur selon statut transaction */
export const txColor = (statut) => {
  const map = {
    success:   'bg-green-500/10 text-green-400  border-green-500/30',
    pending:   'bg-yellow-500/10 text-yellow-400 border-yellow-500/30',
    failed:    'bg-red-500/10   text-red-400    border-red-500/30',
    cancelled: 'bg-gray-500/10  text-gray-400   border-gray-500/30',
    refunded:  'bg-blue-500/10  text-blue-400   border-blue-500/30',
  }
  return map[statut] ?? 'bg-gray-500/10 text-gray-400 border-gray-500/30'
}

/** Libellé français d'une méthode de paiement */
export const methodLabel = (m) => {
  const map = {
    orange_money:   'Orange Money BF',
    mtn_money:      'MTN Money BF',
    moov_money:     'Moov Money BF',
    mtn_ci:         'MTN Mobile Money CI',
    orange_ci:      'Orange Money CI',
    carte_bancaire: 'Carte bancaire',
  }
  return map[m] ?? m
}