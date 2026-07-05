import client from './client'

export interface CurrentUser {
  id: string
  email: string
  authenticated: boolean
  role: 'admin' | 'user'
  groups: string[]
}

export async function fetchMe(): Promise<CurrentUser> {
  const { data } = await client.get<CurrentUser>('/me')
  return data
}

export async function login(username: string, password: string): Promise<void> {
  await client.post('/auth/login', { username, password })
}

export async function logout(): Promise<void> {
  await client.post('/auth/logout')
}
