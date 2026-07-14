const { spawn } = require('child_process');
const path = require('path');
const mysql = require('mysql2/promise');
const dotenv = require('dotenv');

const root = path.join(__dirname, '..');
dotenv.config({ path: path.join(root, '.env'), quiet: true });

const baseUrl = `http://localhost:${process.env.PORT || 5000}/api`;

const assert = (condition, message) => {
  if (!condition) throw new Error(message);
};

const waitForServer = async () => {
  for (let attempt = 0; attempt < 30; attempt += 1) {
    try {
      const response = await fetch(`${baseUrl}/health`);
      if (response.ok) return;
    } catch (_) {
      // Server is still starting.
    }
    await new Promise((resolve) => setTimeout(resolve, 200));
  }
  throw new Error('Backend did not start in time');
};

const request = async (method, endpoint, token, data) => {
  const response = await fetch(`${baseUrl}${endpoint}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    ...(data ? { body: JSON.stringify(data) } : {}),
  });
  const body = await response.json();
  if (!response.ok) {
    throw new Error(`${method} ${endpoint}: ${body.message || response.status}`);
  }
  return body;
};

async function run() {
  let server;
  try {
    await waitForServer();
  } catch (_) {
    server = spawn(process.execPath, ['server.js'], {
      cwd: root,
      env: process.env,
      stdio: 'ignore',
      windowsHide: true,
    });
    await waitForServer();
  }

  const stamp = `${Date.now()}_${Math.floor(Math.random() * 10000)}`;
  const emailA = `privacy_a_${stamp}@example.com`;
  const emailB = `privacy_b_${stamp}@example.com`;
  const nameA = `Privacy A ${stamp}`;
  const nameB = `Privacy B ${stamp}`;
  const password = 'Test12345';
  const connection = await mysql.createConnection({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
  });

  try {
    const registeredA = await request('POST', '/auth/register', null, {
      name: nameA,
      email: emailA,
      password,
    });
    const registeredB = await request('POST', '/auth/register', null, {
      name: nameB,
      email: emailB,
      password,
    });
    const tokenA = registeredA.token;
    const tokenB = registeredB.token;

    const createdSet = await request('POST', '/sets', tokenA, {
      title: `Private Biology ${stamp}`,
      description: 'Ownership integration test',
      color: '#17233C',
    });
    const setId = createdSet.data.id;
    const createdCard = await request('POST', '/cards', tokenA, {
      set_id: setId,
      front: `Mitochondria ${stamp}`,
      back: 'Powerhouse of the cell',
      example: 'Cell biology',
    });
    const createdNote = await request('POST', '/notes', tokenA, {
      title: `Private note ${stamp}`,
      content_text: 'Only A should see this before sharing',
      drawing_data: [],
    });
    const noteId = createdNote.data.id;

    const beforeSets = await request('GET', '/sets', tokenB);
    const beforeNotes = await request('GET', '/notes', tokenB);
    assert(!beforeSets.data.some((set) => set.id === setId), 'B saw A set before sharing');
    assert(!beforeNotes.data.some((note) => note.id === noteId), 'B saw A note before sharing');

    await request('POST', `/sets/${setId}/share`, tokenA, { email: emailB });
    await request('POST', `/notes/${noteId}/share`, tokenA, { email: emailB });

    const afterSets = await request('GET', '/sets', tokenB);
    const afterNotes = await request('GET', '/notes', tokenB);
    const sharedSet = afterSets.data.find((set) => set.id === setId);
    const sharedNote = afterNotes.data.find((note) => note.id === noteId);
    assert(sharedSet, 'B did not receive the shared set');
    assert(sharedNote, 'B did not receive the shared note');
    assert(sharedSet.owner_name === nameA, 'Set creator name is missing');
    assert(sharedSet.is_owner === 0, 'Shared set was incorrectly marked as owned');
    assert(sharedNote.owner_name === nameA, 'Note creator name is missing');

    const cards = await request('GET', `/cards/set/${setId}`, tokenB);
    assert(cards.data.some((card) => card.id === createdCard.data.id), 'B cannot read shared cards');

    const search = await request(
      'GET',
      `/search?q=${encodeURIComponent(`Mitochondria ${stamp}`)}`,
      tokenB
    );
    assert(search.data.cards.length === 1, 'Unified search did not return shared card');

    await request('POST', '/progress/review', tokenB, {
      card_id: createdCard.data.id,
      rating: 'learning',
    });
    await request('POST', '/progress', tokenB, {
      set_id: setId,
      total_cards: 1,
      learned_cards: 1,
      correct_answers: 1,
      wrong_answers: 0,
    });
    const dashboard = await request('GET', '/dashboard', tokenB);
    assert(dashboard.data.today.sessions >= 1, 'Dashboard session data is not real');
    assert(dashboard.data.learned_cards >= 1, 'Dashboard learned card count is not real');

    console.log('Privacy integration passed: private → share → creator → search → dashboard.');
  } finally {
    await connection.query('DELETE FROM users WHERE email IN (?, ?)', [emailA, emailB]);
    await connection.end();
    if (server) server.kill();
  }
}

run().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
