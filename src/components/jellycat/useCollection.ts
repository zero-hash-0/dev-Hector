'use client'

import { useState } from 'react'
import { type JellycatItem, encodeCollection } from './types'

const STORAGE_KEY = 'jellycat-collection'

function loadInitialItems(): JellycatItem[] {
  if (typeof window === 'undefined') return []

  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) return []

    const parsed = JSON.parse(raw) as JellycatItem[]
    return Array.isArray(parsed) ? parsed : []
  } catch {
    return []
  }
}

export function useCollection() {
  const [items, setItems] = useState<JellycatItem[]>(() => loadInitialItems())

  const save = (next: JellycatItem[]) => {
    setItems(next)
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(next))
    } catch {}
  }

  const add = (item: JellycatItem) => save([...items, item])

  const update = (item: JellycatItem) =>
    save(items.map((i) => (i.id === item.id ? item : i)))

  const remove = (id: string) => save(items.filter((i) => i.id !== id))

  const toggleFavorite = (id: string) =>
    save(items.map((i) => (i.id === id ? { ...i, isFavorite: !i.isFavorite } : i)))

  const getShareUrl = () => {
    const encoded = encodeCollection(items)
    return `${window.location.origin}/jellycat/share/${encoded}`
  }

  return { items, loaded: true, add, update, remove, toggleFavorite, getShareUrl }
}
