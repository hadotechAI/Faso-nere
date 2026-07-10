import { Routes, Route, Navigate } from 'react-router-dom'
import { AuthProvider, useAuth } from './store/authStore'
import Layout     from './components/Layout'
import LoginPage  from './pages/LoginPage'
import Dashboard  from './pages/Dashboard'
import DataAnalytics from './pages/DataAnalytics'
import Joueurs    from './pages/joueur'
import JoueurDetail from './pages/joueurDetail'
import Lots       from './pages/Lots'
import Gains      from './pages/Gain'
import Transactions from './pages/Transactions'
import Packs      from './pages/packs'
import PromoCodes from './pages/PromoCodes'
import Notifications from './pages/notifications'
import Audit      from './pages/Audits'
import Fraudes    from './pages/Fraudes'
import Parametres from './pages/parametre'
import Campagnes  from './pages/Campagnes'

function PrivateRoute({ children }) {
  const { isAuthenticated } = useAuth()
  return isAuthenticated ? children : <Navigate to="/login" replace />
}

function PublicRoute({ children }) {
  const { isAuthenticated } = useAuth()
  return isAuthenticated ? <Navigate to="/" replace /> : children
}

export default function App() {
  return (
    <AuthProvider>
      <Routes>
        {/* Route publique */}
        <Route path="/login" element={
          <PublicRoute><LoginPage /></PublicRoute>
        } />

        {/* Routes privées */}
        <Route path="/" element={
          <PrivateRoute><Layout /></PrivateRoute>
        }>
          <Route index                      element={<Dashboard />} />
          <Route path="analytics"           element={<DataAnalytics />} />
          <Route path="joueurs"             element={<Joueurs />} />
          <Route path="joueurs/:id"         element={<JoueurDetail />} />
          <Route path="lots"                element={<Lots />} />
          <Route path="gains"               element={<Gains />} />
          <Route path="transactions"        element={<Transactions />} />
          <Route path="packs"               element={<Packs />} />
          <Route path="promo-codes"         element={<PromoCodes />} />
          <Route path="notifications"       element={<Notifications />} />
          <Route path="audit"               element={<Audit />} />
          <Route path="fraudes"             element={<Fraudes />} />
          <Route path="parametres"          element={<Parametres />} />
          <Route path="campagnes"           element={<Campagnes />} />
        </Route>

        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </AuthProvider>
  )
}