import { useEffect, useState } from 'react'
import { User } from 'lucide-react'

interface Props {
  title: string
  subtitle?: string
}

export function Header({ title, subtitle }: Props) {
  const [userEmail, setUserEmail] = useState<string>('')

  useEffect(() => {
    fetch('/api/me')
      .then(r => r.json())
      .then(d => { if (d.email && d.email !== 'dev@local') setUserEmail(d.email) })
      .catch(() => {})
  }, [])

  return (
    <header className="bg-white border-b border-gray-200 px-6 py-3 flex items-center justify-between shadow-sm">
      <div className="flex items-center gap-3">
        <img src="/logo.png" alt="Logo" className="h-9 w-auto" onError={(e) => { (e.target as HTMLImageElement).style.display = 'none' }} />
        <div>
          <h1 className="text-xl font-bold text-red-600 leading-tight">{title}</h1>
          {subtitle && <p className="text-xs text-gray-500">{subtitle}</p>}
        </div>
      </div>

      {userEmail && (
        <div className="flex items-center gap-2">
          <div className="h-7 w-7 rounded-full bg-gray-100 border border-gray-200 flex items-center justify-center">
            <User size={14} className="text-gray-500" />
          </div>
          <span className="text-xs text-gray-600 font-medium hidden sm:inline">{userEmail}</span>
        </div>
      )}
    </header>
  )
}
