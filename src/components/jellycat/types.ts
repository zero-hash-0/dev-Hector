export interface JellycatItem {
  id: string
  name: string
  series: string
  dexNumber: number | null
  size: 'tiny' | 'small' | 'medium' | 'large' | 'huge' | ''
  imageUrl: string
  acquiredDate: string
  pricePaid: number | null
  notes: string
  isFavorite: boolean
}

/** Base64url encode a collection for sharing via URL path segment */
export function encodeCollection(items: JellycatItem[]): string {
  const json = JSON.stringify(items)
  const bytes = new TextEncoder().encode(json)
  const binary = Array.from(bytes, (b) => String.fromCharCode(b)).join('')
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '')
}

/** Decode a base64url path segment back into a collection */
export function decodeCollection(encoded: string): JellycatItem[] {
  const base64 = encoded.replace(/-/g, '+').replace(/_/g, '/')
  const padding = (4 - (base64.length % 4)) % 4
  const padded = base64 + '='.repeat(padding)
  const binary = atob(padded)
  const bytes = Uint8Array.from(binary, (c) => c.charCodeAt(0))
  const json = new TextDecoder().decode(bytes)
  return JSON.parse(json)
}
