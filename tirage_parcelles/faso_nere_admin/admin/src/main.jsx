import React from 'react'
import ReactDOM from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import { Toaster } from 'react-hot-toast'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import App from './App'
import './index.css'

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,
      retry: 1,
    },
  },
})

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <App />
        <Toaster
        position="top-right"
        toastOptions={{
          style: {
            background: '#1A1535',
            color:      '#fff',
            border:     '1px solid #3A3260',
          },
          success: { iconTheme: { primary: '#F5A623', secondary: '#0E0B1E' } },
          error:   { iconTheme: { primary: '#E74C3C', secondary: '#fff'    } },
        }}
      />
      </BrowserRouter>
    </QueryClientProvider>
  </React.StrictMode>
)