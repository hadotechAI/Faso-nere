import { useQuery } from '@tanstack/react-query'
import {
  AreaChart, Area, BarChart, Bar, PieChart, Pie, Cell,
  XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend
} from 'recharts'
import { AlertTriangle, Activity, TrendingUp } from 'lucide-react'
import api from '../api/client'
import { PageHeader, Card } from '../components/UI'

const COLORS = ['#E74C3C', '#F5A623', '#7B5EA7', '#2ECC71', '#3498DB']

function Skeleton() {
  return (
    <div className="p-6 space-y-6 animate-pulse">
      <div className="h-8 bg-surface2 rounded w-48 mb-2"></div>
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="h-64 bg-surface border border-border rounded-2xl"></div>
        <div className="h-64 bg-surface border border-border rounded-2xl"></div>
        <div className="h-64 bg-surface border border-border rounded-2xl"></div>
      </div>
    </div>
  )
}

export default function DataAnalytics() {
  const { data, isLoading } = useQuery({
    queryKey: ['admin_analytics'],
    queryFn: () => api.get('/admin/analytics').then(res => res.data),
    refetchInterval: 60000,
  })

  if (isLoading) return <Skeleton />

  const { transactions_30j = [], gains_30j = [], erreurs_repartition = [] } = data || {}

  return (
    <div className="p-6 space-y-6 max-w-7xl mx-auto">
      <PageHeader
        title="Data Analytics"
        subtitle="Modélisation des données globales sur 30 jours"
        actions={
          <div className="flex items-center gap-2 text-gold bg-gold/10 px-3 py-1.5 rounded-full border border-gold/30">
            <Activity size={16} />
            <span className="text-sm font-semibold">Live Data</span>
          </div>
        }
      />

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        
        {/* Transactions / Dépôts */}
        <Card className="p-4">
          <div className="flex items-center gap-2 mb-4 text-white">
            <TrendingUp size={18} className="text-green-400" />
            <h3 className="font-semibold">Volume des Transactions Réussies (30j)</h3>
          </div>
          <div className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={transactions_30j}>
                <defs>
                  <linearGradient id="colorVol" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#2ECC71" stopOpacity={0.3}/>
                    <stop offset="95%" stopColor="#2ECC71" stopOpacity={0}/>
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#2d2d2d" vertical={false} />
                <XAxis dataKey="jour" stroke="#888" fontSize={12} tickMargin={10} minTickGap={30} />
                <YAxis stroke="#888" fontSize={12} width={60} />
                <Tooltip 
                  contentStyle={{ backgroundColor: '#1A1535', borderColor: '#3A3260', borderRadius: '8px' }}
                  itemStyle={{ color: '#fff' }}
                />
                <Area type="monotone" dataKey="volume_success" stroke="#2ECC71" strokeWidth={3} fill="url(#colorVol)" name="Volume CFA" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </Card>

        {/* Gains Distribués */}
        <Card className="p-4">
          <div className="flex items-center gap-2 mb-4 text-white">
            <TrendingUp size={18} className="text-gold" />
            <h3 className="font-semibold">Valeurs Gagnées par les Joueurs (30j)</h3>
          </div>
          <div className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={gains_30j}>
                <CartesianGrid strokeDasharray="3 3" stroke="#2d2d2d" vertical={false} />
                <XAxis dataKey="jour" stroke="#888" fontSize={12} tickMargin={10} minTickGap={30} />
                <YAxis stroke="#888" fontSize={12} width={60} />
                <Tooltip 
                  contentStyle={{ backgroundColor: '#1A1535', borderColor: '#3A3260', borderRadius: '8px' }}
                  cursor={{ fill: '#ffffff10' }}
                />
                <Bar dataKey="total_gagne" fill="#F5A623" radius={[4, 4, 0, 0]} name="Valeur Gagnée (CFA)" />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </Card>

        {/* Répartition des erreurs serveurs / problèmes */}
        <Card className="p-4">
          <div className="flex items-center gap-2 mb-4 text-white">
            <AlertTriangle size={18} className="text-red-400" />
            <h3 className="font-semibold">Anomalies & Problèmes Serveurs (Total)</h3>
          </div>
          <div className="h-64 flex items-center justify-center">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={erreurs_repartition}
                  cx="50%"
                  cy="50%"
                  innerRadius={60}
                  outerRadius={80}
                  paddingAngle={5}
                  dataKey="value"
                >
                  {erreurs_repartition.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip 
                  contentStyle={{ backgroundColor: '#1A1535', borderColor: '#3A3260', borderRadius: '8px', color: '#fff' }}
                />
                <Legend verticalAlign="bottom" height={36} iconType="circle" />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </Card>

      </div>
    </div>
  )
}
