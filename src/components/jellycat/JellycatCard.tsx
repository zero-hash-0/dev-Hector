'use client'

import { motion } from 'framer-motion'
import type { JellycatItem } from './types'

const SIZE_LABELS: Record<string, string> = {
  tiny: 'Tiny',
  small: 'Small',
  medium: 'Medium',
  large: 'Large',
  huge: 'Huge',
}

interface Props {
  item: JellycatItem
  readOnly?: boolean
  onEdit?: (item: JellycatItem) => void
  onDelete?: (id: string) => void
  onToggleFavorite?: (id: string) => void
}

export function JellycatCard({ item, readOnly, onEdit, onDelete, onToggleFavorite }: Props) {
  return (
    <motion.div
      layout
      initial={{ opacity: 0, scale: 0.95 }}
      animate={{ opacity: 1, scale: 1 }}
      exit={{ opacity: 0, scale: 0.9 }}
      transition={{ duration: 0.2 }}
      className="bg-white rounded-3xl overflow-hidden shadow-[0_2px_16px_rgba(0,0,0,0.06)] border border-pink-100 group"
    >
      {/* Image */}
      <div className="aspect-square bg-pink-50 overflow-hidden relative">
        {item.imageUrl ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={item.imageUrl}
            alt={item.name}
            className="w-full h-full object-cover transition-transform duration-300 group-hover:scale-105"
          />
        ) : (
          <div className="w-full h-full flex items-center justify-center text-5xl select-none">
            🧸
          </div>
        )}

        {!readOnly && onToggleFavorite && (
          <button
            onClick={() => onToggleFavorite(item.id)}
            className="absolute top-2 right-2 w-8 h-8 rounded-full bg-white/80 backdrop-blur-sm flex items-center justify-center text-base transition-transform hover:scale-110 shadow-sm"
            aria-label={item.isFavorite ? 'Remove from favourites' : 'Add to favourites'}
          >
            {item.isFavorite ? '⭐' : '☆'}
          </button>
        )}
        {readOnly && item.isFavorite && (
          <div className="absolute top-2 right-2 text-base">⭐</div>
        )}
      </div>

      {/* Info */}
      <div className="p-4">
        <h3 className="font-semibold text-[#3d2c2c] text-sm leading-tight mb-2 truncate">
          {item.name}
        </h3>

        <div className="flex flex-wrap gap-1.5 mb-2">
          {item.series && (
            <span className="text-xs bg-pink-100 text-pink-700 px-2 py-0.5 rounded-full">
              {item.series}
            </span>
          )}
          {item.size && (
            <span className="text-xs bg-purple-100 text-purple-700 px-2 py-0.5 rounded-full">
              {SIZE_LABELS[item.size]}
            </span>
          )}
        </div>

        <div className="space-y-0.5">
          {item.acquiredDate && (
            <p className="text-xs text-[#b08080]">
              {new Date(item.acquiredDate).toLocaleDateString('en-US', {
                month: 'short',
                year: 'numeric',
              })}
            </p>
          )}
          {item.pricePaid != null && item.pricePaid > 0 && (
            <p className="text-xs text-[#b08080]">${item.pricePaid.toFixed(2)}</p>
          )}
          {item.notes && (
            <p className="text-xs text-[#b08080] line-clamp-2 mt-1">{item.notes}</p>
          )}
        </div>

        {!readOnly && (onEdit || onDelete) && (
          <div className="flex gap-2 mt-3">
            {onEdit && (
              <button
                onClick={() => onEdit(item)}
                className="flex-1 text-xs py-1.5 rounded-xl bg-pink-50 text-pink-700 hover:bg-pink-100 transition-colors"
              >
                Edit
              </button>
            )}
            {onDelete && (
              <button
                onClick={() => onDelete(item.id)}
                className="flex-1 text-xs py-1.5 rounded-xl bg-red-50 text-red-400 hover:bg-red-100 transition-colors"
              >
                Remove
              </button>
            )}
          </div>
        )}
      </div>
    </motion.div>
  )
}
