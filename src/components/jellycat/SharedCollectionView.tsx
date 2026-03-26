'use client'

import Link from 'next/link'
import { decodeCollection } from './types'
import { JellycatCard } from './JellycatCard'
import { StatsBar } from './StatsBar'

export function SharedCollectionView({ encoded }: { encoded: string }) {
  let items
  try {
    items = decodeCollection(encoded)
  } catch {
    return (
      <div className="min-h-screen bg-[#fdf6f0] flex items-center justify-center p-4">
        <div className="text-center">
          <div className="text-6xl mb-4">😕</div>
          <h1 className="text-xl font-bold text-[#3d2c2c] mb-2">Invalid collection link</h1>
          <p className="text-[#b08080] text-sm mb-6">This link may be broken or expired.</p>
          <Link
            href="/jellycat"
            className="inline-block px-6 py-3 rounded-2xl bg-pink-400 text-white text-sm hover:bg-pink-500 transition-colors"
          >
            Start your own collection →
          </Link>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-[#fdf6f0] text-[#3d2c2c]">
      <div className="max-w-5xl mx-auto px-4 py-12">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-4xl font-bold text-[#3d2c2c] mb-1">🧸 Jellycat Collection</h1>
          <p className="text-[#b08080] text-sm">
            {items.length} plush{items.length !== 1 ? 'ies' : ''} in this collection
          </p>
        </div>

        {items.length > 0 && (
          <div className="mb-8">
            <StatsBar items={items} />
          </div>
        )}

        {items.length === 0 ? (
          <div className="text-center py-24">
            <div className="text-6xl mb-4">🧸</div>
            <p className="text-[#b08080]">This collection is empty.</p>
          </div>
        ) : (
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-4">
            {items.map((item) => (
              <JellycatCard key={item.id} item={item} readOnly />
            ))}
          </div>
        )}

        <div className="mt-16 text-center">
          <Link
            href="/jellycat"
            className="inline-block px-6 py-3 rounded-2xl bg-pink-400 text-white text-sm font-medium hover:bg-pink-500 transition-colors shadow-sm"
          >
            Create your own collection →
          </Link>
        </div>
      </div>
    </div>
  )
}
