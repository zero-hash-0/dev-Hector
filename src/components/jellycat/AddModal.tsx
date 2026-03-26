'use client'

import { useEffect, useState, type FormEvent, type ReactNode } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import type { JellycatItem } from './types'

const SIZES = ['tiny', 'small', 'medium', 'large', 'huge'] as const

function blank(): JellycatItem {
  return {
    id: crypto.randomUUID(),
    name: '',
    series: '',
    size: '',
    imageUrl: '',
    acquiredDate: '',
    pricePaid: null,
    notes: '',
    isFavorite: false,
  }
}

interface Props {
  open: boolean
  item: JellycatItem | null
  onClose: () => void
  onSave: (item: JellycatItem) => void
}

export function AddModal({ open, item, onClose, onSave }: Props) {
  const [form, setForm] = useState<JellycatItem>(blank())
  const [preview, setPreview] = useState(false)

  useEffect(() => {
    if (open) {
      setForm(item ?? blank())
      setPreview(false)
    }
  }, [open, item])

  const set = <K extends keyof JellycatItem>(key: K, value: JellycatItem[K]) =>
    setForm((f) => ({ ...f, [key]: value }))

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault()
    if (!form.name.trim()) return
    onSave(form)
  }

  return (
    <AnimatePresence>
      {open && (
        <>
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
            className="fixed inset-0 bg-black/60 backdrop-blur-sm z-40"
          />

          <div className="fixed inset-0 flex items-center justify-center z-50 p-4">
            <motion.div
              initial={{ opacity: 0, scale: 0.95, y: 16 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.95, y: 16 }}
              transition={{ duration: 0.2 }}
              className="bg-[#0F1E32] border border-[#1A3050] rounded-2xl shadow-2xl w-full max-w-md max-h-[90vh] overflow-y-auto"
            >
              <div className="p-6">
                <div className="flex items-center justify-between mb-5">
                  <h2 className="text-xl font-bold text-white">
                    {item ? 'Edit Jellycat' : 'Add Jellycat'} 🧸
                  </h2>
                  <button
                    type="button"
                    onClick={onClose}
                    className="w-8 h-8 rounded-full bg-white/5 text-[#4A6580] hover:bg-white/10 flex items-center justify-center text-lg transition-colors"
                  >
                    ×
                  </button>
                </div>

                <form onSubmit={handleSubmit} className="space-y-4">
                  <Field label="Name *">
                    <input
                      required
                      value={form.name}
                      onChange={(e) => set('name', e.target.value)}
                      placeholder="e.g. Bashful Bunny"
                      className={input}
                    />
                  </Field>

                  <Field label="Series">
                    <input
                      value={form.series}
                      onChange={(e) => set('series', e.target.value)}
                      placeholder="e.g. Bashful, Amuseable, Blossom…"
                      className={input}
                    />
                  </Field>

                  <Field label="Size">
                    <select
                      value={form.size}
                      onChange={(e) =>
                        set('size', e.target.value as JellycatItem['size'])
                      }
                      className={input}
                    >
                      <option value="">Select size…</option>
                      {SIZES.map((s) => (
                        <option key={s} value={s}>
                          {s.charAt(0).toUpperCase() + s.slice(1)}
                        </option>
                      ))}
                    </select>
                  </Field>

                  <Field label="Image URL">
                    <input
                      type="url"
                      value={form.imageUrl}
                      onChange={(e) => {
                        set('imageUrl', e.target.value)
                        setPreview(false)
                      }}
                      onBlur={() => setPreview(!!form.imageUrl)}
                      placeholder="https://…"
                      className={input}
                    />
                  </Field>

                  {preview && form.imageUrl && (
                    <div className="rounded-xl overflow-hidden w-28 h-28 bg-[#0A1320] border border-[#1A3050]">
                      {/* eslint-disable-next-line @next/next/no-img-element */}
                      <img
                        src={form.imageUrl}
                        alt="preview"
                        className="w-full h-full object-cover"
                        onError={() => setPreview(false)}
                      />
                    </div>
                  )}

                  <div className="grid grid-cols-2 gap-3">
                    <Field label="Date Acquired">
                      <input
                        type="date"
                        value={form.acquiredDate}
                        onChange={(e) => set('acquiredDate', e.target.value)}
                        className={input}
                      />
                    </Field>
                    <Field label="Price Paid ($)">
                      <input
                        type="number"
                        min="0"
                        step="0.01"
                        value={form.pricePaid ?? ''}
                        onChange={(e) =>
                          set(
                            'pricePaid',
                            e.target.value ? parseFloat(e.target.value) : null,
                          )
                        }
                        placeholder="0.00"
                        className={input}
                      />
                    </Field>
                  </div>

                  <Field label="Notes">
                    <textarea
                      value={form.notes}
                      onChange={(e) => set('notes', e.target.value)}
                      placeholder="Limited edition, gift from…"
                      rows={3}
                      className={`${input} resize-none`}
                    />
                  </Field>

                  <label className="flex items-center gap-2.5 cursor-pointer select-none">
                    <input
                      type="checkbox"
                      checked={form.isFavorite}
                      onChange={(e) => set('isFavorite', e.target.checked)}
                      className="w-4 h-4 accent-[#3DD6CE]"
                    />
                    <span className="text-sm text-[#7A96B4]">Mark as favourite ⭐</span>
                  </label>

                  <div className="flex gap-3 pt-2">
                    <button
                      type="button"
                      onClick={onClose}
                      className="flex-1 py-2.5 rounded-xl border border-[#1A3050] text-[#4A6580] text-sm hover:bg-white/5 transition-colors"
                    >
                      Cancel
                    </button>
                    <button
                      type="submit"
                      className="flex-1 py-2.5 rounded-xl bg-[#3DD6CE] text-[#0A1320] text-sm font-bold hover:bg-[#2EC5BD] transition-colors"
                    >
                      {item ? 'Save Changes' : 'Add to Collection'}
                    </button>
                  </div>
                </form>
              </div>
            </motion.div>
          </div>
        </>
      )}
    </AnimatePresence>
  )
}

const input =
  'w-full px-3 py-2 rounded-xl border border-[#1A3050] bg-[#0A1320] text-white text-sm focus:outline-none focus:ring-2 focus:ring-[#3DD6CE]/40 placeholder-[#2A4060]'

function Field({ label, children }: { label: string; children: ReactNode }) {
  return (
    <div>
      <label className="block text-xs text-[#4A6580] mb-1">{label}</label>
      {children}
    </div>
  )
}
