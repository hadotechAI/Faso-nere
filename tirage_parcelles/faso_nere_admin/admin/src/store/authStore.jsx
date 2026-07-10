import { useState, useEffect, createContext, useContext } from 'react'
import api from '../api/client'

const AuthContext = createContext(null)

export function AuthProvider({ children }) {
  const [user,    setUser]    = useState(() => {
    const u = localStorage.getItem('admin_user')
    return u ? JSON.parse(u) : null
  })
  const [loading, setLoading] = useState(false)

  const login = async (telephone, motDePasse) => {
    setLoading(true)
    try {
      const { data } = await api.post('/auth/login', {
        telephone,
        mot_de_passe: motDePasse,
      })

      // Vérifier le rôle admin
      if (!['admin', 'super_admin'].includes(data.user?.role)) {
        throw new Error('Accès réservé aux administrateurs')
      }

      localStorage.setItem('admin_token', data.access_token)
      localStorage.setItem('admin_user',  JSON.stringify(data.user))
      setUser(data.user)
      return data.user
    } finally {
      setLoading(false)
    }
  }

  const logout = async () => {
    try { await api.post('/auth/logout') } catch (_) {}
    localStorage.removeItem('admin_token')
    localStorage.removeItem('admin_user')
    setUser(null)
  }

  const isAdmin      = user?.role === 'admin'
  const isSuperAdmin = user?.role === 'super_admin'

  return (
    <AuthContext.Provider value={{
      user, loading, login, logout, isAdmin, isSuperAdmin,
      isAuthenticated: !!user,
    }}>
      {children}
    </AuthContext.Provider>
  )
}

export const useAuth = () => useContext(AuthContext)

