import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../store/authStore'
import { Eye, EyeOff, Lock, Phone, AlertCircle } from 'lucide-react'
import toast from 'react-hot-toast'

export default function LoginPage() {
  const { login, loading } = useAuth()
  const navigate           = useNavigate()
  const [tel,      setTel]      = useState('')
  const [pass,     setPass]     = useState('')
  const [showPass, setShowPass] = useState(false)
  const [error,    setError]    = useState('')

  const handleSubmit = async e => {
    e.preventDefault()
    setError('')
    if (!tel || !pass) {
      setError('Remplissez tous les champs')
      return
    }
    try {
      await login(tel, pass)
      toast.success('Connexion réussie !')
      navigate('/')
    } catch (err) {
      const msg = err.response?.data?.detail || err.message || 'Erreur de connexion'
      setError(msg)
    }
  }

  return (
    <div className="min-h-screen bg-bg flex items-center justify-center p-4">
      {/* Fond décoratif */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-purple/10 rounded-full blur-3xl" />
        <div className="absolute bottom-1/4 right-1/4 w-96 h-96 bg-gold/5  rounded-full blur-3xl" />
      </div>

      <div className="w-full max-w-md relative z-10">

        {/* Logo */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-20 h-20
                          rounded-2xl bg-gold/10 border border-gold/30 mb-4">
            <span className="text-4xl">🏗️</span>
          </div>
          <h1 className="text-2xl font-black text-gold tracking-wider">FASO NERE</h1>
          <p className="text-gray-400 text-sm mt-1">Panneau d'administration</p>
        </div>

        {/* Formulaire */}
        <div className="bg-surface border border-border rounded-2xl p-8">
          <h2 className="text-xl font-bold text-white mb-6">Connexion Admin</h2>

          {error && (
            <div className="flex items-center gap-2 bg-red-500/10 border border-red-500/30
                            rounded-xl p-3 mb-4">
              <AlertCircle size={16} className="text-red-400 flex-shrink-0" />
              <p className="text-red-400 text-sm">{error}</p>
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">

            {/* Téléphone */}
            <div>
              <label className="text-sm font-semibold text-gray-300 block mb-2">
                Numéro de téléphone
              </label>
              <div className="relative">
                <Phone size={16}
                  className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-500" />
                <input
                  type="tel"
                  value={tel}
                  onChange={e => setTel(e.target.value)}
                  placeholder="+22600000000"
                  className="w-full bg-surface2 border border-border rounded-xl
                             pl-10 pr-4 py-3 text-white placeholder-gray-500
                             focus:outline-none focus:border-gold transition-colors"
                />
              </div>
            </div>

            {/* Mot de passe */}
            <div>
              <label className="text-sm font-semibold text-gray-300 block mb-2">
                Mot de passe
              </label>
              <div className="relative">
                <Lock size={16}
                  className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-500" />
                <input
                  type={showPass ? 'text' : 'password'}
                  value={pass}
                  onChange={e => setPass(e.target.value)}
                  placeholder="••••••••"
                  className="w-full bg-surface2 border border-border rounded-xl
                             pl-10 pr-12 py-3 text-white placeholder-gray-500
                             focus:outline-none focus:border-gold transition-colors"
                />
                <button
                  type="button"
                  onClick={() => setShowPass(!showPass)}
                  className="absolute right-3 top-1/2 -translate-y-1/2
                             text-gray-500 hover:text-white transition-colors"
                >
                  {showPass ? <EyeOff size={16} /> : <Eye size={16} />}
                </button>
              </div>
            </div>

            {/* Bouton */}
            <button
              type="submit"
              disabled={loading}
              className="w-full bg-gold hover:bg-yellow-400 text-bg font-bold
                         py-3 rounded-xl transition-all disabled:opacity-50
                         disabled:cursor-not-allowed mt-2"
            >
              {loading ? (
                <span className="flex items-center justify-center gap-2">
                  <span className="w-4 h-4 border-2 border-bg/30 border-t-bg
                                   rounded-full animate-spin" />
                  Connexion...
                </span>
              ) : 'Se connecter'}
            </button>

          </form>
        </div>

        <p className="text-center text-gray-600 text-xs mt-4">
          Accès réservé aux administrateurs Faso Nere
        </p>
      </div>
    </div>
  )
}