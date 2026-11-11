/**
 * Seeds the group chat room the app opens from the Confession FAB (design
 * `S-03 · Hội bàn tròn`), so a fresh environment has a room to enter instead of
 * a 404 behind the button.
 *
 * Idempotent: upserts by the unique `slug` and does NOT overwrite an existing
 * row's fields, so a name edited later is never clobbered by a re-run.
 *
 * Run: npx ts-node scripts/seed-community-chat-rooms.ts   (reads MONGODB_URI from env/.env)
 */
import 'dotenv/config';
import mongoose from 'mongoose';

const LocalChatRoomSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    slug: { type: String, required: true, unique: true },
    isOfficial: Boolean,
    status: String,
    messageCount: Number,
    createdAt: Date,
    updatedAt: Date,
  },
  { collection: 'community_chat_rooms' },
);

// One room today. The client opens it by SLUG, so adding a second one — a chat
// per topic, say — is a row here plus the id the app asks for, not a migration.
const SEED_ROOMS = [
  {
    slug: 'hoi-ban-tron',
    name: 'Hội bàn tròn',
    isOfficial: true,
  },
];

async function main() {
  const uri = process.env.MONGODB_URI;
  if (!uri) {
    throw new Error('MONGODB_URI is not set — check your .env');
  }

  await mongoose.connect(uri);
  const Room = mongoose.model('CommunityChatRoomSeed', LocalChatRoomSchema);

  for (const room of SEED_ROOMS) {
    const now = new Date();
    const result = await Room.updateOne(
      { slug: room.slug },
      {
        $setOnInsert: {
          ...room,
          status: 'VISIBLE',
          messageCount: 0,
          createdAt: now,
          updatedAt: now,
        },
      },
      { upsert: true },
    );

    const action = result.upsertedCount ? 'created' : 'kept';
    // eslint-disable-next-line no-console
    console.log(`${action}: ${room.slug} (${room.name})`);
  }

  await mongoose.disconnect();
}

main().catch((error) => {
  // eslint-disable-next-line no-console
  console.error(error);
  process.exit(1);
});
