import { Outlet, NavLink, useNavigate } from 'react-router-dom'
import { useAuth } from '../store/authStore'
import {
  LayoutDashboard, Users, Gift, Trophy, CreditCard,
  Package, Bell, FileText, Settings, LogOut, Menu, X,
  ChevronRight, Activity, ShieldAlert, Ticket, MapPin
} from 'lucide-react'
import { useState } from 'react'
import clsx from 'clsx'

const navItems = [
  { path: '/',              icon: LayoutDashboard, label: 'Dashboard'      },
  { path: '/analytics',     icon: Activity,        label: 'Analytics'      },
  { path: '/joueurs',       icon: Users,           label: 'Joueurs'        },
  { path: '/lots',          icon: Gift,            label: 'Lots & Cadeaux' },
  { path: '/gains',         icon: Trophy,          label: 'Gains'          },
  { path: '/transactions',  icon: CreditCard,      label: 'Transactions'   },
  { path: '/packs',         icon: Package,         label: 'Packs'          },
  { path: '/promo-codes',   icon: Ticket,          label: 'Codes Promo'    },
  { path: '/campagnes',     icon: MapPin,          label: 'Campagnes'      },
  { path: '/notifications', icon: Bell,            label: 'Notifications'  },
  { path: '/audit',         icon: FileText,        label: 'Audit'          },
  { path: '/fraudes',       icon: ShieldAlert,     label: 'Anti-Fraude'    },
  { path: '/parametres',    icon: Settings,        label: 'Paramètres'     },
]

export default function Layout() {
  const { user, logout } = useAuth()
  const navigate          = useNavigate()
  const [open, setOpen]   = useState(true)

  const handleLogout = async () => {
    await logout()
    navigate('/login')
  }

  return (
    <div className="flex h-screen overflow-hidden bg-bg">

      {/* ── Sidebar ── */}
      <aside className={clsx(
        'flex flex-col bg-surface border-r border-border transition-all duration-300 z-20',
        open ? 'w-64' : 'w-16'
      )}>

        {/* Logo */}
        <div className="flex items-center gap-3 px-4 py-5 border-b border-border">
          <div className="w-9 h-9 rounded-xl bg-gold flex items-center justify-center flex-shrink-0">
            <span className="text-lg">🏗️</span>
          </div>
          {open && (
            <div>
              <p className="text-sm font-black text-gold tracking-wider">FASO NERE</p>
              <p className="text-xs text-gray-500">Administration</p>
            </div>
          )}
          <button
            onClick={() => setOpen(!open)}
            className="ml-auto text-gray-500 hover:text-white transition-colors"
          >
            {open ? <X size={18} /> : <Menu size={18} />}
          </button>
        </div>

        {/* Navigation */}
        <nav className="flex-1 py-4 overflow-y-auto">
          {navItems.map(({ path, icon: Icon, label }) => (
            <NavLink
              key={path}
              to={path}
              end={path === '/'}
              className={({ isActive }) => clsx(
                'flex items-center gap-3 mx-2 px-3 py-2.5 rounded-xl mb-1 transition-all',
                'text-sm font-semibold group',
                isActive
                  ? 'bg-gold/10 text-gold border border-gold/30'
                  : 'text-gray-400 hover:bg-surface2 hover:text-white'
              )}
            >
              <Icon size={18} className="flex-shrink-0" />
              {open && <span>{label}</span>}
              {open && (
                <ChevronRight
                  size={14}
                  className="ml-auto opacity-0 group-hover:opacity-100 transition-opacity"
                />
              )}
            </NavLink>
          ))}
        </nav>

        {/* Profil admin */}
        <div className="border-t border-border p-3">
          <div className={clsx(
            'flex items-center gap-3 px-2 py-2 rounded-xl',
            open && 'bg-surface2'
          )}>
            <div className="w-8 h-8 rounded-lg bg-purple flex items-center justify-center flex-shrink-0">
              <span className="text-sm font-bold text-white">
                {user?.nom?.[0]?.toUpperCase() ?? 'A'}
              </span>
            </div>
            {open && (
              <div className="flex-1 min-w-0">
                <p className="text-sm font-semibold text-white truncate">
                  {user?.nom} {user?.prenom}
                </p>
                <p className="text-xs text-gold capitalize">{user?.role}</p>
              </div>
            )}
            <button
              onClick={handleLogout}
              title="Déconnexion"
              className="text-gray-500 hover:text-red-400 transition-colors flex-shrink-0"
            >
              <LogOut size={16} />
            </button>
          </div>
        </div>
      </aside>

      {/* ── Contenu principal ── */}
      <main className="flex-1 overflow-y-auto">
        <Outlet />
      </main>

    </div>
  )
}