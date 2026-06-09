import axios from 'axios'

// IAP handles authentication at the load balancer — no Authorization header needed.
const client = axios.create({ baseURL: '/api' })

export default client
