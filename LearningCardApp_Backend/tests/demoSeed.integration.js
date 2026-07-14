const { spawn } = require('child_process');
const path = require('path');
const dotenv = require('dotenv');

const root = path.join(__dirname, '..');
dotenv.config({ path: path.join(root, '.env'), quiet: true });

const baseUrl = `http://localhost:${process.env.PORT || 5000}/api`;
const password = 'Demo@123';

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
    throw new Error(
      `${method} ${endpoint}: ${body.message || response.status}${body.error ? ` (${body.error})` : ''}`
    );
  }
  return body;
};

const login = (email) => request('POST', '/auth/login', null, { email, password });

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

  try {
    const [minhLogin, lanLogin] = await Promise.all([
      login('minh.demo@learningcard.local'),
      login('lan.demo@learningcard.local'),
    ]);
    const minhToken = minhLogin.token;
    const lanToken = lanLogin.token;

    const [minhSets, lanSets, minhNotes, lanNotes] = await Promise.all([
      request('GET', '/sets', minhToken),
      request('GET', '/sets', lanToken),
      request('GET', '/notes', minhToken),
      request('GET', '/notes', lanToken),
    ]);

    assert(minhSets.data.length === 4, 'Minh should see 3 owned sets and 1 shared set');
    assert(lanSets.data.length === 3, 'Lan should see 2 owned sets and 1 shared set');
    assert(minhNotes.data.length === 4, 'Minh should see 3 owned notes and 1 shared note');
    assert(lanNotes.data.length === 3, 'Lan should see 2 owned notes and 1 shared note');
    assert(
      !lanSets.data.some((set) => set.title === 'Tiếng Anh học thuật – Cốt lõi'),
      'Lan can see Minh private English set'
    );
    assert(
      !minhSets.data.some((set) => set.title === 'Kinh tế vi mô căn bản'),
      'Minh can see Lan private economics set'
    );
    assert(
      lanSets.data.some(
        (set) => set.title === 'Sinh học – Tế bào' && set.owner_name === 'Minh Anh Demo'
      ),
      'Shared set or creator attribution is missing'
    );
    assert(
      lanNotes.data.some(
        (note) => note.title === 'Tóm tắt Sinh học tế bào' && note.owner_name === 'Minh Anh Demo'
      ),
      'Shared note or creator attribution is missing'
    );

    const [dashboard, review, publicSearch, privateSearch] = await Promise.all([
      request('GET', '/dashboard', minhToken),
      request('GET', '/dashboard/review', minhToken),
      request('GET', `/search?q=${encodeURIComponent('Kỹ năng học hiệu quả')}`, lanToken),
      request('GET', `/search?q=${encodeURIComponent('Tiếng Anh học thuật')}`, lanToken),
    ]);

    assert(dashboard.data.today.sessions === 2, 'Seeded today session count is incorrect');
    assert(dashboard.data.study_streak === 7, 'Seeded study streak is incorrect');
    assert(dashboard.data.shared_sets === 1, 'Seeded shared set count is incorrect');
    assert(review.data.due_count > 0, 'Seeded review queue is empty');
    assert(
      publicSearch.data.sets.some((set) => set.title === 'Kỹ năng học hiệu quả'),
      'Public sample set is not searchable'
    );
    assert(privateSearch.data.sets.length === 0, 'Private sample set leaked through search');

    console.log('Demo seed integration passed: login → private/shared → dashboard → review → search.');
  } finally {
    if (server) server.kill();
  }
}

run().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
