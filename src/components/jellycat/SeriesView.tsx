'use client'

import { motion } from 'framer-motion'
import type { JellycatItem } from './types'

interface Props {
  items: JellycatItem[]
  onDetail: (item: JellycatItem) => void
}

export function SeriesView({ items, onDetail }: Props) {
  // Group owned items by series, uncategorised last
  const owned = items.filter((i) => !i.isWishlist)

  const grouped = owned.reduce<Record<string, JellycatItem[]>>((acc, item) => {
    const key = item.series.trim() || 'Uncategorised'
    acc[key] = acc[key] ?? []
    acc[key].push(item)
    return acc
  }, {})

  const sorted = Object.entries(grouped).sort(([a], [b]) => {
    if (a === 'Uncategorised') return 1
    if (b === 'Uncategorised') return -1
    return a.localeCompare(b)
  })

  if (sorted.length === 0) {
    return (
      <div className="text-center py-24">
        <div className="text-6xl mb-4 opacity-30">📚</div>
        <p className="text-[#4A6580] text-sm">No series yet — add some Jellycats first.</p>
      </div>
    )
  }

  return (
    <div className="space-y-8">
      {sorted.map(([series, seriesItems], gi) => (
        <motion.div
          key={series}
          initial={{ opacity: 0, y: 8 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: gi * 0.05 }}
        >
          {/* Series header */}
          <div className="flex items-center gap-3 mb-3">
            <h3 className="text-sm font-bold text-white">{series}</h3>
            <span className="text-xs text-[#3DD6CE] bg-[#3DD6CE]/10 border border-[#3DD6CE]/20 px-2 py-0.5 rounded-full">
              {seriesItems.length}
            </span>
            <div className="flex-1 h-px bg-[#1A3050]" />
          </div>

          {/* Horizontal scroll row */}
          <div className="flex gap-3 overflow-x-auto pb-1 scrollbar-hide">
            {seriesItems.map((item) => (
              <button
                key={item.id}
                onClick={() => onDetail(item)}
                className="flex-shrink-0 w-28 text-left group"
              >
                <div className="w-28 h-28 rounded-2xl bg-[#0A1320] border border-[#1A3050] overflow-hidden mb-2 transition-all duration-200 group-hover:border-[#3DD6CE]/40 group-hover:shadow-[0_0_16px_rgba(61,214,206,0.1)]">
                  {item.imageUrl ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img
                      src={item.imageUrl}
                      alt={item.name}
                      className="w-full h-full object-cover transition-transform duration-200 group-hover:scale-105"
                    />
                  ) : (
                    <div className="w-full h-full flex items-center justify-center text-3xl opacity-40 select-none">
                      🧸
                    </div>
                  )}
                </div>
                <p className="text-xs text-[#7A96B4] truncate leading-tight">{item.name}</p>
                {item.isFavorite && <span className="text-[10px]">⭐</span>}
              </button>
            ))}
          </div>
        </motion.div>
      ))}
    </div>
  )
}
