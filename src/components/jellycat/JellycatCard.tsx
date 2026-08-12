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
      className="bg-[#0F1E32] rounded-2xl overflow-hidden border border-[#1A3050] group transition-all duration-300 hover:border-[#3DD6CE]/40 hover:shadow-[0_0_24px_rgba(61,214,206,0.08)]"
    >
      {/* Image */}
      <div className="aspect-square bg-[#0A1320] overflow-hidden relative">
        {item.imageUrl ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={item.imageUrl}
            alt={item.name}
            className="w-full h-full object-cover transition-transform duration-300 group-hover:scale-105"
          />
        ) : (
          <div className="w-full h-full flex items-center justify-center text-5xl select-none opacity-60">
            ⚡
          </div>
        )}

        {!readOnly && onToggleFavorite && (
          <button
            onClick={() => onToggleFavorite(item.id)}
            className="absolute top-2 right-2 w-8 h-8 rounded-full bg-[#0A1320]/80 backdrop-blur-sm flex items-center justify-center text-base transition-transform hover:scale-110"
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
        <h3 className="font-semibold text-white text-sm leading-tight mb-1 truncate">
          {item.name}
        </h3>

        {item.dexNumber && (
          <p className="text-xs text-[#7A96B4] mb-2">#{item.dexNumber.toString().padStart(4, '0')}</p>
        )}

        <div className="flex flex-wrap gap-1.5 mb-2">
          {item.series && (
            <span className="text-xs bg-[#3DD6CE]/15 text-[#3DD6CE] px-2 py-0.5 rounded-full border border-[#3DD6CE]/20">
              {item.series}
            </span>
          )}
          {item.size && (
            <span className="text-xs bg-white/5 text-[#7A96B4] px-2 py-0.5 rounded-full border border-white/10">
              {SIZE_LABELS[item.size]}
            </span>
          )}
        </div>

        <div className="space-y-0.5">
          {item.acquiredDate && (
            <p className="text-xs text-[#4A6580]">
              {new Date(item.acquiredDate).toLocaleDateString('en-US', {
                month: 'short',
                year: 'numeric',
              })}
            </p>
          )}
          {item.pricePaid != null && item.pricePaid > 0 && (
            <p className="text-xs text-[#4A6580]">${item.pricePaid.toFixed(2)}</p>
          )}
          {item.notes && (
            <p className="text-xs text-[#4A6580] line-clamp-2 mt-1">{item.notes}</p>
          )}
        </div>

        {!readOnly && (onEdit || onDelete) && (
          <div className="flex gap-2 mt-3">
            {onEdit && (
              <button
                onClick={() => onEdit(item)}
                className="flex-1 text-xs py-1.5 rounded-lg bg-[#3DD6CE]/10 text-[#3DD6CE] hover:bg-[#3DD6CE]/20 transition-colors border border-[#3DD6CE]/20"
              >
                Edit
              </button>
            )}
            {onDelete && (
              <button
                onClick={() => onDelete(item.id)}
                className="flex-1 text-xs py-1.5 rounded-lg bg-white/5 text-[#4A6580] hover:bg-red-500/10 hover:text-red-400 transition-colors border border-white/10"
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
