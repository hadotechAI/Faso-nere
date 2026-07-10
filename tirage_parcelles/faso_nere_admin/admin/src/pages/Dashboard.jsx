import { useQuery } from '@tanstack/react-query'
import {
  Users, Trophy, TrendingUp, Package,
  Truck, CreditCard, UserPlus, Dice5,
} from 'lucide-react'
import {
  AreaChart, Area, BarChart, Bar, PieChart, Pie, Cell,
  XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend,
} from 'recharts'
import api from '../api/client'
import { fmt, fmtDate } from '../utils/format'

const COLORS = ['#F5A623', '#7B5EA7', '#2ECC71', '#E74C3C', '#3498DB']

export default function Dashboard() {
  const { data, isLoading: loading } = useQuery({
    queryKey: ['dashboard_stats'],
    queryFn: () => api.get('/admin/dashboard').then(res => res.data),
    refetchInterval: 60000, // Refresh every minute
  })

  if (loading) return <PageLoader />

  const stats = data?.stats ?? {}

  const statCards = [
    { label: 'Total joueurs',       value: fmt(stats.total_joueurs),    icon: Users,      color: 'text-blue-400',   bg: 'bg-blue-400/10'   },
    { label: 'Nouveaux (30j)',       value: fmt(stats.nouveaux_30j),     icon: UserPlus,   color: 'text-green-400',  bg: 'bg-green-400/10'  },
    { label: 'Total tirages',        value: fmt(stats.total_tirages),    icon: Dice5,      color: 'text-purple-400', bg: 'bg-purple-400/10' },
    { label: 'Total gains',          value: fmt(stats.total_gains),      icon: Trophy,     color: 'text-gold',       bg: 'bg-gold/10'       },
    { label: 'Revenus total',        value: `${fmt(stats.revenus_total)} F`, icon: TrendingUp, color: 'text-gold',   bg: 'bg-gold/10'       },
    { label: 'Revenus (30j)',        value: `${fmt(stats.revenus_30j)} F`,   icon: CreditCard, color: 'text-green-400', bg: 'bg-green-400/10' },
    { label: 'Joueurs suspendus',    value: fmt(stats.joueurs_suspendus),icon: Users,      color: 'text-red-400',    bg: 'bg-red-400/10'    },
    { label: 'Livraisons en attente',value: fmt(stats.livraisons_en_attente), icon: Truck, color: 'text-orange-400', bg: 'bg-orange-400/10' },
  ]

  return (
    <div className="p-6 space-y-6">

      {/* Header */}
      <div>
        <h1 className="text-2xl font-black text-white">Dashboard</h1>
        <p className="text-gray-400 text-sm mt-1">
          Vue d'ensemble de Faso Nere
        </p>
      </div>

      {/* Stat cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        {statCards.map(({ label, value, icon: Icon, color, bg }) => (
          <div key={label}
            className="bg-surface border border-border rounded-2xl p-4">
            <div className="flex items-center justify-between mb-3">
              <p className="text-xs text-gray-400 font-medium">{label}</p>
              <div className={`w-8 h-8 rounded-lg ${bg} flex items-center justify-center`}>
                <Icon size={16} className={color} />
              </div>
            </div>
            <p className={`text-2xl font-black ${color}`}>{value ?? '—'}</p>
          </div>
        ))}
      </div>

      {/* Graphiques */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">

        {/* Inscriptions 7j */}
        <ChartCard title="Inscriptions (7 derniers jours)">
          <ResponsiveContainer width="100%" height={220}>
            <AreaChart data={data?.inscriptions_7j ?? []}>
              <defs>
                <linearGradient id="gradGold" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%"  stopColor="#F5A623" stopOpacity={0.3} />
                  <stop offset="95%" stopColor="#F5A623" stopOpacity={0}   />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="#3A3260" />
              <XAxis dataKey="jour" tick={{ fill: '#8A85A8', fontSize: 11 }}
                tickFormatter={v => fmtDate(v)} />
              <YAxis tick={{ fill: '#8A85A8', fontSize: 11 }} />
              <Tooltip
                contentStyle={{ background: '#1A1535', border: '1px solid #3A3260',
                                borderRadius: 8, color: '#fff' }}
                labelFormatter={v => fmtDate(v)}
              />
              <Area type="monotone" dataKey="nb" stroke="#F5A623"
                fill="url(#gradGold)" strokeWidth={2} name="Inscriptions" />
            </AreaChart>
          </ResponsiveContainer>
        </ChartCard>

        {/* Tirages 7j */}
        <ChartCard title="Tirages (7 derniers jours)">
          <ResponsiveContainer width="100%" height={220}>
            <BarChart data={data?.tirages_7j ?? []}>
              <CartesianGrid strokeDasharray="3 3" stroke="#3A3260" />
              <XAxis dataKey="jour" tick={{ fill: '#8A85A8', fontSize: 11 }}
                tickFormatter={v => fmtDate(v)} />
              <YAxis tick={{ fill: '#8A85A8', fontSize: 11 }} />
              <Tooltip
                contentStyle={{ background: '#1A1535', border: '1px solid #3A3260',
                                borderRadius: 8, color: '#fff' }}
                labelFormatter={v => fmtDate(v)}
              />
              <Bar dataKey="total"    fill="#7B5EA7" name="Total"    radius={[4,4,0,0]} />
              <Bar dataKey="gagnants" fill="#F5A623" name="Gagnants" radius={[4,4,0,0]} />
              <Legend wrapperStyle={{ color: '#8A85A8', fontSize: 12 }} />
            </BarChart>
          </ResponsiveContainer>
        </ChartCard>

        {/* Comparatif Dépôts vs Retraits (30 derniers jours) */}
        <div className="col-span-1 lg:col-span-2">
          <ChartCard title="Comparatif Financier (Dépôts vs Retraits - 30 derniers jours)">
            <ResponsiveContainer width="100%" height={260}>
              <AreaChart data={data?.comparatif ?? []}>
                <defs>
                  <linearGradient id="gradDepots" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%"  stopColor="#2ECC71" stopOpacity={0.3} />
                    <stop offset="95%" stopColor="#2ECC71" stopOpacity={0}   />
                  </linearGradient>
                  <linearGradient id="gradRetraits" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%"  stopColor="#E74C3C" stopOpacity={0.3} />
                    <stop offset="95%" stopColor="#E74C3C" stopOpacity={0}   />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#3A3260" />
                <XAxis dataKey="jour" tick={{ fill: '#8A85A8', fontSize: 11 }}
                  tickFormatter={v => fmtDate(v)} />
                <YAxis tick={{ fill: '#8A85A8', fontSize: 11 }}
                  tickFormatter={v => `${fmt(v)} F`} />
                <Tooltip
                  contentStyle={{ background: '#1A1535', border: '1px solid #3A3260',
                                  borderRadius: 8, color: '#fff' }}
                  labelFormatter={v => fmtDate(v)}
                />
                <Area type="monotone" dataKey="depots" stroke="#2ECC71"
                  fill="url(#gradDepots)" strokeWidth={2} name="Dépôts" />
                <Area type="monotone" dataKey="retraits" stroke="#E74C3C"
                  fill="url(#gradRetraits)" strokeWidth={2} name="Retraits" />
                <Legend wrapperStyle={{ color: '#8A85A8', fontSize: 12 }} />
              </AreaChart>
            </ResponsiveContainer>
          </ChartCard>
        </div>

        {/* Revenus par méthode */}
        <ChartCard title="Revenus par méthode de paiement">
          <ResponsiveContainer width="100%" height={220}>
            <PieChart>
              <Pie
                data={data?.revenus_methode ?? []}
                dataKey="total"
                nameKey="methode"
                cx="50%" cy="50%"
                outerRadius={80}
                label={({ methode, percent }) =>
                  `${methode} ${(percent * 100).toFixed(0)}%`}
                labelLine={false}
              >
                {(data?.revenus_methode ?? []).map((_, i) => (
                  <Cell key={i} fill={COLORS[i % COLORS.length]} />
                ))}
              </Pie>
              <Tooltip
                contentStyle={{ background: '#1A1535', border: '1px solid #3A3260',
                                borderRadius: 8, color: '#fff' }}
                formatter={v => [`${fmt(v)} FCFA`, 'Revenus']}
              />
            </PieChart>
          </ResponsiveContainer>
        </ChartCard>

        {/* Résumé rapide */}
        <ChartCard title="Résumé rapide">
          <div className="space-y-3 p-2">
            {[
              { label: 'Tirages ce mois',    value: fmt(stats.tirages_30j),            color: 'text-purple-400' },
              { label: 'Revenus ce mois',    value: `${fmt(stats.revenus_30j)} FCFA`,  color: 'text-gold'       },
              { label: 'Gains distribués',   value: fmt(stats.total_gains),            color: 'text-green-400'  },
              { label: 'Livraisons livrées', value: fmt(stats.livraisons_terminees),   color: 'text-blue-400'   },
            ].map(({ label, value, color }) => (
              <div key={label}
                className="flex items-center justify-between
                           bg-surface2 rounded-xl px-4 py-3">
                <span className="text-sm text-gray-400">{label}</span>
                <span className={`text-sm font-bold ${color}`}>{value ?? '—'}</span>
              </div>
            ))}
          </div>
        </ChartCard>

      </div>
    </div>
  )
}

function ChartCard({ title, children }) {
  return (
    <div className="bg-surface border border-border rounded-2xl p-5">
      <h3 className="text-sm font-bold text-gray-300 mb-4">{title}</h3>
      {children}
    </div>
  )
}

function PageLoader() {
  return (
    <div className="p-6 space-y-6 animate-pulse">
      <div>
        <div className="h-8 bg-surface2 rounded w-48 mb-2"></div>
        <div className="h-4 bg-surface2 rounded w-64"></div>
      </div>
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        {[...Array(8)].map((_, i) => (
          <div key={i} className="h-24 bg-surface border border-border rounded-2xl"></div>
        ))}
      </div>
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="h-64 bg-surface border border-border rounded-2xl"></div>
        <div className="h-64 bg-surface border border-border rounded-2xl"></div>
      </div>
    </div>
  )
}