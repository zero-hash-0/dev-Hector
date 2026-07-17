import type { Metadata } from "next";
import ArenaGame from "./ArenaGame";

export const metadata: Metadata = {
  title: "Creature Arena — a pocket MOBA",
  description:
    "Pick a creature, pick a battle board, push the lane, and shatter the enemy core. A browser MOBA with original pocket-monster style fighters.",
};

export default function ArenaPage() {
  return <ArenaGame />;
}
