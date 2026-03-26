'use client'

import { useState } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import { useCollection } from '@/components/jellycat/useCollection'
import { JellycatCard } from '@/components/jellycat/JellycatCard'
import { StatsBar } from '@/components/jellycat/StatsBar'
import { AddModal } from '@/components/jellycat/AddModal'
import { DetailModal } from '@/components/jellycat/DetailModal'
import type { JellycatItem } from '@/components/jellycat/types'

type Tab    = 'collection' | 'wishlist'
type Filter = 'all' | 'favourites'
type Sort   = 'name' | 'newest' | 'oldest' | 'price-high' | 'price-low'

const SORT_LABELS: Record<Sort, string> = {
  name: 'Name A–Z',
  newest: 'Newest',
  oldest: 'Oldest',
  'price-high': 'Price ↓',
  'price-low': 'Price ↑',
}

function sortItems(items: JellycatItem[], sort: Sort): JellycatItem[] {
  return [...items].sort((a, b) => {
    switch (sort) {
      case 'name':       return a.name.localeCompare(b.name)
      case 'newest':     return (b.acquiredDate || '').localeCompare(a.acquiredDate || '')
      case 'oldest':     return (a.acquiredDate || '').localeCompare(b.acquiredDate || '')
      case 'price-high': return (b.pricePaid ?? 0) - (a.pricePaid ?? 0)
      case 'price-low':  return (a.pricePaid ?? 0) - (b.pricePaid ?? 0)
    }
  })
}

export default function JellycatPage() {
  const { items, loaded, add, update, remove, toggleFavorite, getShareUrl } = useCollection()
  const [tab, setTab]         = useState<Tab>('collection')
  const [modalOpen, setModalOpen] = useState(false)
  const [editing, setEditing] = useState<JellycatItem | null>(null)
  const [detail, setDetail]   = useState<JellycatItem | null>(null)
  const [search, setSearch]   = useState('')
  const [filter, setFilter]   = useState<Filter>('all')
  const [sort, setSort]       = useState<Sort>('newest')
  const [copied, setCopied]   = useState(false)

  const owned    = items.filter((i) => !i.isWishlist)
  const wishlist = items.filter((i) => i.isWishlist)
  const pool     = tab === 'collection' ? owned : wishlist

  const filtered = sortItems(
    pool.filter((item) => {
      const matchesSearch =
        item.name.toLowerCase().includes(search.toLowerCase()) ||
        item.series.toLowerCase().includes(search.toLowerCase())
      const matchesFilter = filter === 'all' || item.isFavorite
      return matchesSearch && matchesFilter
    }),
    sort,
  )

  const handleShare = async () => {
    try {
      await navigator.clipboard.writeText(getShareUrl())
      setCopied(true)
      setTimeout(() => setCopied(false), 2500)
    } catch {
      window.open(getShareUrl(), '_blank')
    }
  }

  const openAdd = (defaultWishlist = false) => {
    setEditing(defaultWishlist ? ({ isWishlist: true } as JellycatItem) : null)
    setModalOpen(true)
  }

  const openEdit = (item: JellycatItem) => {
    setEditing(item)
    setModalOpen(true)
  }

  const handleSave = (item: JellycatItem) => {
    editing?.id ? update(item) : add(item)
    setModalOpen(false)
    setEditing(null)
  }

  if (!loaded) return null

  return (
    <div className="min-h-screen bg-[#0A1320] text-white">
      <div className="max-w-5xl mx-auto px-4 py-10">

        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: -8 }}
          animate={{ opacity: 1, y: 0 }}
          className="flex items-start justify-between flex-wrap gap-4 mb-8"
        >
          <div className="flex items-center gap-3">
            <span className="text-3xl">🧸</span>
            <div>
              <h1 className="text-3xl font-bold tracking-tight">
                My <span className="text-[#3DD6CE]">Jellycat</span> Collection
              </h1>
              <p className="text-[#4A6580] text-sm mt-0.5">Your soft toy portfolio</p>
            </div>
          </div>

          <div className="flex gap-3 flex-wrap">
            {owned.length > 0 && (
              <motion.button
                whileTap={{ scale: 0.97 }}
                onClick={handleShare}
                className="px-4 py-2 rounded-xl bg-[#0F1E32] border border-[#1A3050] text-[#3DD6CE] text-sm hover:border-[#3DD6CE]/40 transition-colors"
              >
                {copied ? '✓ Copied!' : '🔗 Share'}
              </motion.button>
            )}
            <motion.button
              whileTap={{ scale: 0.97 }}
              onClick={() => openAdd(tab === 'wishlist')}
              className="px-4 py-2 rounded-xl bg-[#3DD6CE] text-[#0A1320] text-sm font-bold hover:bg-[#2EC5BD] transition-colors"
            >
              + Add {tab === 'wishlist' ? 'to Wishlist' : 'Jellycat'}
            </motion.button>
          </div>
        </motion.div>

        {/* Stats (collection only) */}
        {tab === 'collection' && owned.length > 0 && (
          <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="mb-7">
            <StatsBar items={owned} />
          </motion.div>
        )}

        {/* Tabs */}
        <div className="flex gap-1 mb-6 bg-[#0F1E32] border border-[#1A3050] rounded-xl p-1 w-fit">
          {([['collection', `Collection${owned.length ? ` · ${owned.length}` : ''}`],
             ['wishlist',   `Wishlist${wishlist.length ? ` · ${wishlist.length}` : ''}`]] as [Tab, string][])
            .map(([t, label]) => (
              <button
                key={t}
                onClick={() => setTab(t)}
                className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                  tab === t
                    ? 'bg-[#3DD6CE] text-[#0A1320]'
                    : 'text-[#4A6580] hover:text-white'
                }`}
              >
                {label}
              </button>
            ))}
        </div>

        {/* Toolbar */}
        {pool.length > 0 && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            className="flex flex-wrap gap-2 mb-5"
          >
            <input
              type="text"
              placeholder="Search…"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="px-3 py-2 rounded-xl border border-[#1A3050] bg-[#0F1E32] text-white placeholder-[#2A4060] text-sm focus:outline-none focus:ring-2 focus:ring-[#3DD6CE]/30 w-44"
            />

            {tab === 'collection' && (
              <button
                onClick={() => setFilter(f => f === 'all' ? 'favourites' : 'all')}
                className={`px-3 py-2 rounded-xl text-sm transition-colors border ${
                  filter === 'favourites'
                    ? 'bg-[#3DD6CE] text-[#0A1320] font-bold border-[#3DD6CE]'
                    : 'bg-[#0F1E32] border-[#1A3050] text-[#4A6580] hover:border-[#3DD6CE]/30'
                }`}
              >
                ⭐ Favs
              </button>
            )}

            <select
              value={sort}
              onChange={(e) => setSort(e.target.value as Sort)}
              className="px-3 py-2 rounded-xl border border-[#1A3050] bg-[#0F1E32] text-[#7A96B4] text-sm focus:outline-none focus:ring-2 focus:ring-[#3DD6CE]/30"
            >
              {(Object.entries(SORT_LABELS) as [Sort, string][]).map(([val, label]) => (
                <option key={val} value={val}>{label}</option>
              ))}
            </select>
          </motion.div>
        )}

        {/* Empty state */}
        {pool.length === 0 ? (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            className="text-center py-24"
          >
            <div className="text-7xl mb-5 select-none opacity-30">
              {tab === 'wishlist' ? '🌟' : '🧸'}
            </div>
            <h2 className="text-xl font-semibold text-white mb-2">
              {tab === 'wishlist' ? 'No wishlist items yet' : 'No Jellycats yet!'}
            </h2>
            <p className="text-[#4A6580] text-sm mb-8">
              {tab === 'wishlist'
                ? 'Save Jellycats you want to own.'
                : 'Start building your soft toy portfolio.'}
            </p>
            <motion.button
              whileTap={{ scale: 0.97 }}
              onClick={() => openAdd(tab === 'wishlist')}
              className="px-6 py-3 rounded-xl bg-[#3DD6CE] text-[#0A1320] font-bold hover:bg-[#2EC5BD] transition-colors"
            >
              {tab === 'wishlist' ? 'Add to Wishlist' : 'Add your first Jellycat'}
            </motion.button>
          </motion.div>
        ) : filtered.length === 0 ? (
          <p className="text-[#4A6580] text-sm text-center py-16">
            No results for &ldquo;{search}&rdquo;
          </p>
        ) : (
          <motion.div layout className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3">
            <AnimatePresence>
              {filtered.map((item) => (
                <JellycatCard
                  key={item.id}
                  item={item}
                  onDetail={setDetail}
                  onEdit={openEdit}
                  onDelete={remove}
                  onToggleFavorite={toggleFavorite}
                />
              ))}
            </AnimatePresence>
          </motion.div>
        )}
      </div>

      <AddModal
        open={modalOpen}
        item={editing}
        onClose={() => { setModalOpen(false); setEditing(null) }}
        onSave={handleSave}
      />

      <DetailModal
        item={detail}
        onClose={() => setDetail(null)}
        onEdit={openEdit}
        onToggleFavorite={toggleFavorite}
      />
    </div>
  )
}
