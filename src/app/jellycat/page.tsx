'use client'

import { useState } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import { useCollection } from '@/components/jellycat/useCollection'
import { JellycatCard } from '@/components/jellycat/JellycatCard'
import { StatsBar } from '@/components/jellycat/StatsBar'
import { AddModal } from '@/components/jellycat/AddModal'
import type { JellycatItem } from '@/components/jellycat/types'

type Filter = 'all' | 'favourites'

export default function JellycatPage() {
  const { items, loaded, add, update, remove, toggleFavorite, getShareUrl } = useCollection()
  const [modalOpen, setModalOpen] = useState(false)
  const [editing, setEditing] = useState<JellycatItem | null>(null)
  const [search, setSearch] = useState('')
  const [filter, setFilter] = useState<Filter>('all')
  const [copied, setCopied] = useState(false)

  const filtered = items.filter((item) => {
    const matchesSearch =
      item.name.toLowerCase().includes(search.toLowerCase()) ||
      item.series.toLowerCase().includes(search.toLowerCase())
    const matchesFilter = filter === 'all' || item.isFavorite
    return matchesSearch && matchesFilter
  })

  const handleShare = async () => {
    try {
      await navigator.clipboard.writeText(getShareUrl())
      setCopied(true)
      setTimeout(() => setCopied(false), 2500)
    } catch {
      window.open(getShareUrl(), '_blank')
    }
  }

  const openAdd = () => {
    setEditing(null)
    setModalOpen(true)
  }

  const openEdit = (item: JellycatItem) => {
    setEditing(item)
    setModalOpen(true)
  }

  const handleSave = (item: JellycatItem) => {
    editing ? update(item) : add(item)
    setModalOpen(false)
    setEditing(null)
  }

  if (!loaded) return null

  return (
    <div className="min-h-screen bg-[#0A1320] text-white">
      <div className="max-w-5xl mx-auto px-4 py-12">

        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: -8 }}
          animate={{ opacity: 1, y: 0 }}
          className="flex items-start justify-between flex-wrap gap-4 mb-10"
        >
          <div>
            <div className="flex items-center gap-3 mb-1">
              <span className="text-3xl">🧸</span>
              <h1 className="text-3xl font-bold text-white tracking-tight">
                My <span className="text-[#3DD6CE]">Jellycat</span> Collection
              </h1>
            </div>
            <p className="text-[#4A6580] text-sm pl-[52px]">Your soft toy portfolio</p>
          </div>

          <div className="flex gap-3 flex-wrap">
            {items.length > 0 && (
              <motion.button
                whileTap={{ scale: 0.97 }}
                onClick={handleShare}
                className="px-4 py-2 rounded-xl bg-[#0F1E32] border border-[#1A3050] text-[#3DD6CE] text-sm hover:border-[#3DD6CE]/40 transition-colors"
              >
                {copied ? '✓ Copied!' : '🔗 Share Collection'}
              </motion.button>
            )}
            <motion.button
              whileTap={{ scale: 0.97 }}
              onClick={openAdd}
              className="px-4 py-2 rounded-xl bg-[#3DD6CE] text-[#0A1320] text-sm font-bold hover:bg-[#2EC5BD] transition-colors"
            >
              + Add Jellycat
            </motion.button>
          </div>
        </motion.div>

        {/* Stats */}
        {items.length > 0 && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.05 }}
            className="mb-8"
          >
            <StatsBar items={items} />
          </motion.div>
        )}

        {/* Search + Filter */}
        {items.length > 0 && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.1 }}
            className="flex flex-wrap gap-3 mb-6"
          >
            <input
              type="text"
              placeholder="Search by name or series…"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="px-4 py-2 rounded-xl border border-[#1A3050] bg-[#0F1E32] text-white placeholder-[#2A4060] text-sm focus:outline-none focus:ring-2 focus:ring-[#3DD6CE]/30 w-64"
            />
            <div className="flex gap-2">
              {(['all', 'favourites'] as Filter[]).map((f) => (
                <button
                  key={f}
                  onClick={() => setFilter(f)}
                  className={`px-4 py-2 rounded-xl text-sm transition-colors ${
                    filter === f
                      ? 'bg-[#3DD6CE] text-[#0A1320] font-bold'
                      : 'bg-[#0F1E32] border border-[#1A3050] text-[#4A6580] hover:border-[#3DD6CE]/30 hover:text-[#3DD6CE]'
                  }`}
                >
                  {f === 'all' ? 'All' : '⭐ Favourites'}
                </button>
              ))}
            </div>
          </motion.div>
        )}

        {/* Empty state */}
        {items.length === 0 ? (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.15 }}
            className="text-center py-28"
          >
            <div className="text-7xl mb-5 select-none opacity-40">🧸</div>
            <h2 className="text-xl font-semibold text-white mb-2">No Jellycats yet!</h2>
            <p className="text-[#4A6580] text-sm mb-8">Start building your soft toy portfolio.</p>
            <motion.button
              whileTap={{ scale: 0.97 }}
              onClick={openAdd}
              className="px-6 py-3 rounded-xl bg-[#3DD6CE] text-[#0A1320] font-bold hover:bg-[#2EC5BD] transition-colors"
            >
              Add your first Jellycat
            </motion.button>
          </motion.div>
        ) : filtered.length === 0 ? (
          <p className="text-[#4A6580] text-sm text-center py-16">
            No results for &ldquo;{search}&rdquo;
            {filter === 'favourites' ? ' in favourites' : ''}
          </p>
        ) : (
          <motion.div layout className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-4">
            <AnimatePresence>
              {filtered.map((item) => (
                <JellycatCard
                  key={item.id}
                  item={item}
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
        onClose={() => {
          setModalOpen(false)
          setEditing(null)
        }}
        onSave={handleSave}
      />
    </div>
  )
}
