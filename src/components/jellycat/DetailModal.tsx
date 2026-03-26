'use client'

import { AnimatePresence, motion } from 'framer-motion'
import type { JellycatItem } from './types'

const SIZE_LABELS: Record<string, string> = {
  tiny: 'Tiny', small: 'Small', medium: 'Medium', large: 'Large', huge: 'Huge',
}

interface Props {
  item: JellycatItem | null
  onClose: () => void
  onEdit: (item: JellycatItem) => void
  onToggleFavorite: (id: string) => void
  readOnly?: boolean
}

export function DetailModal({ item, onClose, onEdit, onToggleFavorite, readOnly }: Props) {
  return (
    <AnimatePresence>
      {item && (
        <>
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
            className="fixed inset-0 bg-black/70 backdrop-blur-sm z-40"
          />
          <div className="fixed inset-0 flex items-end sm:items-center justify-center z-50 p-0 sm:p-4">
            <motion.div
              initial={{ opacity: 0, y: 40 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: 40 }}
              transition={{ duration: 0.22, ease: 'easeOut' }}
              className="bg-[#0F1E32] border border-[#1A3050] rounded-t-3xl sm:rounded-2xl w-full sm:max-w-sm overflow-hidden"
            >
              {/* Image */}
              <div className="aspect-square w-full bg-[#0A1320] relative overflow-hidden">
                {item.imageUrl ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img
                    src={item.imageUrl}
                    alt={item.name}
                    className="w-full h-full object-cover"
                  />
                ) : (
                  <div className="w-full h-full flex items-center justify-center text-8xl opacity-30 select-none">
                    🧸
                  </div>
                )}

                {/* Close */}
                <button
                  onClick={onClose}
                  className="absolute top-3 left-3 w-9 h-9 rounded-full bg-[#0A1320]/80 backdrop-blur-sm flex items-center justify-center text-[#4A6580] hover:text-white transition-colors text-xl"
                >
                  ←
                </button>

                {/* Favourite */}
                {!readOnly && (
                  <button
                    onClick={() => onToggleFavorite(item.id)}
                    className="absolute top-3 right-3 w-9 h-9 rounded-full bg-[#0A1320]/80 backdrop-blur-sm flex items-center justify-center text-lg transition-transform hover:scale-110"
                  >
                    {item.isFavorite ? '⭐' : '☆'}
                  </button>
                )}

                {/* Wishlist badge */}
                {item.isWishlist && (
                  <div className="absolute bottom-3 left-3 bg-[#3DD6CE] text-[#0A1320] text-xs font-bold px-3 py-1 rounded-full">
                    Wishlist
                  </div>
                )}
              </div>

              {/* Info */}
              <div className="p-5">
                <h2 className="text-xl font-bold text-white mb-3">{item.name}</h2>

                <div className="flex flex-wrap gap-2 mb-4">
                  {item.series && (
                    <span className="text-xs bg-[#3DD6CE]/15 text-[#3DD6CE] px-3 py-1 rounded-full border border-[#3DD6CE]/20">
                      {item.series}
                    </span>
                  )}
                  {item.size && (
                    <span className="text-xs bg-white/5 text-[#7A96B4] px-3 py-1 rounded-full border border-white/10">
                      {SIZE_LABELS[item.size]}
                    </span>
                  )}
                </div>

                <div className="space-y-2 mb-5">
                  {item.acquiredDate && (
                    <Row label="Acquired">
                      {new Date(item.acquiredDate).toLocaleDateString('en-US', {
                        day: 'numeric', month: 'long', year: 'numeric',
                      })}
                    </Row>
                  )}
                  {item.pricePaid != null && item.pricePaid > 0 && (
                    <Row label="Paid">${item.pricePaid.toFixed(2)}</Row>
                  )}
                  {item.notes && (
                    <Row label="Notes">{item.notes}</Row>
                  )}
                </div>

                {!readOnly && (
                  <button
                    onClick={() => { onEdit(item); onClose() }}
                    className="w-full py-3 rounded-xl bg-[#3DD6CE] text-[#0A1320] font-bold text-sm hover:bg-[#2EC5BD] transition-colors"
                  >
                    Edit
                  </button>
                )}
              </div>
            </motion.div>
          </div>
        </>
      )}
    </AnimatePresence>
  )
}

function Row({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div className="flex gap-3">
      <span className="text-xs text-[#4A6580] w-16 shrink-0 pt-0.5">{label}</span>
      <span className="text-sm text-[#7A96B4]">{children}</span>
    </div>
  )
}
