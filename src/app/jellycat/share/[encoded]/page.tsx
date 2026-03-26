import { SharedCollectionView } from '@/components/jellycat/SharedCollectionView'

export default async function SharedCollectionPage({
  params,
}: {
  params: Promise<{ encoded: string }>
}) {
  const { encoded } = await params
  return <SharedCollectionView encoded={encoded} />
}
