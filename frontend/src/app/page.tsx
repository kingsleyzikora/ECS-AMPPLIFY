'use client'

import { useState, useEffect } from 'react'
import axios from 'axios'

const API_URL = process.env.NEXT_PUBLIC_API_URL

export default function Home() {
  const [users, setUsers] = useState([])
  const [products, setProducts] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchData()
  }, [])

  const fetchData = async () => {
    try {
      const [usersRes, productsRes] = await Promise.all([
        axios.get(`${API_URL}/api/users`),
        axios.get(`${API_URL}/api/products`)
      ])

      setUsers(usersRes.data.data || [])
      setProducts(productsRes.data.data || [])
    } catch (error) {
      console.error('Error fetching data:', error)
    } finally {
      setLoading(false)
    }
  }

  return (
    <main className="container">
      <h1>ECS Microservices Dashboard</h1>

      <section className="section">
        <h2>Users</h2>
        {loading ? (
          <p>Loading...</p>
        ) : (
          <div className="grid">
            {users.map((user: any) => (
              <div key={user.id} className="card">
                <h3>{user.name}</h3>
                <p>{user.email}</p>
              </div>
            ))}
          </div>
        )}
      </section>

      <section className="section">
        <h2>Products</h2>
        {loading ? (
          <p>Loading...</p>
        ) : (
          <div className="grid">
            {products.map((product: any) => (
              <div key={product.id} className="card">
                <h3>{product.name}</h3>
                <p>${product.price}</p>
                <p>Stock: {product.stock}</p>
              </div>
            ))}
          </div>
        )}
      </section>
    </main>
  )
}
