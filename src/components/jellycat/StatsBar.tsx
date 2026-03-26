import type { JellycatItem } from './types'

export function StatsBar({ items }: { items: JellycatItem[] }) {
  const favorites = items.filter((i) => i.isFavorite).length
  const series = new Set(items.map((i) => i.series).filter(Boolean)).size
  const totalValue = items.reduce((acc, i) => acc + (i.pricePaid ?? 0), 0)

  const stats = [
    { label: 'Total', value: items.length },
    { label: 'Favourites', value: favorites },
    { label: 'Series', value: series },
    ...(totalValue > 0
      ? [{ label: 'Collection Value', value: `$${totalValue.toFixed(0)}` }]
      : []),
  ]

  return (
    <div className="flex gap-3 flex-wrap">
      {stats.map((s) => (
        <div
          key={s.label}
          className="bg-[#0F1E32] rounded-xl px-5 py-3 border border-[#1A3050]"
        >
          <div className="text-2xl font-bold text-[#3DD6CE]">{s.value}</div>
          <div className="text-xs text-[#4A6580]">{s.label}</div>
        </div>
      ))}
    </div>
  )
}
