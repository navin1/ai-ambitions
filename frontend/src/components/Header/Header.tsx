import { LogOut, Upload, User } from 'lucide-react'

interface Props {
  title: string
  subtitle?: string
  userEmail?: string
  role?: 'admin' | 'user'
  onLogout?: () => void
  onUploadClick?: () => void
}

export function Header({ title, subtitle, userEmail, role, onLogout, onUploadClick }: Props) {
  return (
    <header className="bg-white border-b border-gray-200 px-3 sm:px-6 py-3 flex items-center gap-2 shadow-sm">
      <div className="flex items-center gap-2 sm:gap-3 min-w-0 flex-1">
        <img src="/logo.png" alt="Logo" className="h-7 sm:h-9 w-auto shrink-0" onError={(e) => { (e.target as HTMLImageElement).style.display = 'none' }} />
        <div className="min-w-0">
          <h1 className="text-base sm:text-2xl font-bold text-red-600 leading-tight truncate">{title}</h1>
          {subtitle && <p className="text-xs text-gray-500 truncate hidden sm:block">{subtitle}</p>}
        </div>
      </div>

      {userEmail && (
        <div className="flex items-center gap-1.5 sm:gap-3 shrink-0">
          <div className="flex items-center gap-1.5 sm:gap-2">
            <div className="h-7 w-7 rounded-full bg-gray-100 border border-gray-200 flex items-center justify-center shrink-0">
              <User size={14} className="text-gray-500" />
            </div>
            <span className="text-xs text-gray-600 font-medium hidden md:inline">{userEmail}</span>
          </div>

          {role === 'admin' && onUploadClick && (
            <button
              onClick={onUploadClick}
              title="Upload file to GCS"
              className="flex items-center gap-1.5 text-xs font-medium text-gray-500 hover:text-red-600 border border-gray-200 hover:border-red-200 hover:bg-red-50 rounded-lg px-2 sm:px-2.5 py-1.5 transition shrink-0"
            >
              <Upload size={14} />
              <span className="hidden sm:inline">Upload</span>
            </button>
          )}

          {onLogout && (
            <button
              onClick={onLogout}
              title="Sign out"
              className="flex items-center gap-1.5 text-xs font-medium text-gray-500 hover:text-red-600 border border-gray-200 hover:border-red-200 hover:bg-red-50 rounded-lg px-2 sm:px-2.5 py-1.5 transition shrink-0"
            >
              <LogOut size={14} />
              <span className="hidden sm:inline">Sign out</span>
            </button>
          )}
        </div>
      )}
    </header>
  )
}
