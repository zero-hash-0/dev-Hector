'use client'

import Link from 'next/link'
import { decodeCollection } from './types'
import { JellycatCard } from './JellycatCard'
import { StatsBar } from './StatsBar'
import { DetailModal } from './DetailModal'
import { useState } from 'react'
import type { JellycatItem } from './types'

export function SharedCollectionView({ encoded }: { encoded: string }) {
  const [detail, setDetail] = useState<JellycatItem | null>(null)

  let items: JellycatItem[]
  try {
    items = decodeCollection(encoded)
  } catch {
    return (
      <div className="min-h-screen bg-[#0A1320] flex items-center justify-center p-4">
        <div className="text-center">
          <div className="text-6xl mb-4">😕</div>
          <h1 className="text-xl font-bold text-white mb-2">Invalid collection link</h1>
          <p className="text-[#4A6580] text-sm mb-6">This link may be broken or expired.</p>
          <Link
            href="/jellycat"
            className="inline-block px-6 py-3 rounded-xl bg-[#3DD6CE] text-[#0A1320] text-sm font-bold hover:bg-[#2EC5BD] transition-colors"
          >
            Start your own collection →
          </Link>
        </div>
      </div>
    )
  }

  const owned    = items.filter((i) => !i.isWishlist)
  const wishlist = items.filter((i) => i.isWishlist)
  const favorites = owned.filter((i) => i.isFavorite)
  const series = [...new Set(owned.map((i) => i.series).filter(Boolean))]

  return (
    <div className="min-h-screen bg-[#0A1320] text-white">
      <div className="max-w-5xl mx-auto px-4 py-12">

        {/* Header */}
        <div className="mb-10">
          <div className="flex items-center gap-3 mb-2">
            <span className="text-4xl">🧸</span>
            <h1 className="text-3xl font-bold text-white tracking-tight">
              Jellycat <span className="text-[#3DD6CE]">Collection</span>
            </h1>
          </div>
          <p className="text-[#4A6580] text-sm pl-[52px]">
            {owned.length} plush{owned.length !== 1 ? 'ies' : ''}
            {wishlist.length > 0 && ` · ${wishlist.length} on wishlist`}
            {series.length > 0 && ` · ${series.length} series`}
          </p>
        </div>

        {/* Stats */}
        {owned.length > 0 && (
          <div className="mb-10">
            <StatsBar items={owned} />
          </div>
        )}

        {/* Favourites highlight row */}
        {favorites.length > 0 && (
          <div className="mb-10">
            <div className="flex items-center gap-3 mb-4">
              <h2 className="text-sm font-bold text-white">⭐ Favourites</h2>
              <div className="flex-1 h-px bg-[#1A3050]" />
            </div>
            <div className="flex gap-3 overflow-x-auto pb-1">
              {favorites.map((item) => (
                <button
                  key={item.id}
                  onClick={() => setDetail(item)}
                  className="flex-shrink-0 w-32 text-left group"
                >
                  <div className="w-32 h-32 rounded-2xl bg-[#0F1E32] border border-[#1A3050] overflow-hidden mb-2 transition-all duration-200 group-hover:border-[#3DD6CE]/40">
                    {item.imageUrl ? (
                      // eslint-disable-next-line @next/next/no-img-element
                      <img src={item.imageUrl} alt={item.name} className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-200" />
                    ) : (
                      <div className="w-full h-full flex items-center justify-center text-4xl opacity-40">🧸</div>
                    )}
                  </div>
                  <p className="text-xs text-[#7A96B4] truncate">{item.name}</p>
                </button>
              ))}
            </div>
          </div>
        )}

        {/* Full collection */}
        {owned.length === 0 ? (
          <div className="text-center py-24">
            <div className="text-6xl mb-4 opacity-30">🧸</div>
            <p className="text-[#4A6580]">This collection is empty.</p>
          </div>
        ) : (
          <>
            <div className="flex items-center gap-3 mb-4">
              <h2 className="text-sm font-bold text-white">All Plushies</h2>
              <div className="flex-1 h-px bg-[#1A3050]" />
            </div>
            <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-4">
              {owned.map((item) => (
                <JellycatCard key={item.id} item={item} readOnly onDetail={setDetail} />
              ))}
            </div>
          </>
        )}

        {/* Wishlist section */}
        {wishlist.length > 0 && (
          <div className="mt-12">
            <div className="flex items-center gap-3 mb-4">
              <h2 className="text-sm font-bold text-white">🌟 Wishlist</h2>
              <div className="flex-1 h-px bg-[#1A3050]" />
            </div>
            <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-4">
              {wishlist.map((item) => (
                <JellycatCard key={item.id} item={item} readOnly onDetail={setDetail} />
              ))}
            </div>
          </div>
        )}

        {/* CTA */}
        <div className="mt-16 pt-10 border-t border-[#1A3050] text-center">
          <p className="text-[#4A6580] text-sm mb-4">Want to track your own Jellycat collection?</p>
          <Link
            href="/jellycat"
            className="inline-block px-8 py-3 rounded-xl bg-[#3DD6CE] text-[#0A1320] text-sm font-bold hover:bg-[#2EC5BD] transition-colors"
          >
            Start your collection →
          </Link>
        </div>
      </div>

      <DetailModal
        item={detail}
        onClose={() => setDetail(null)}
        onEdit={() => {}}
        onToggleFavorite={() => {}}
        readOnly
      />
    </div>
  )
}
