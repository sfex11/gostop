/**
 * 고스톱 P2P 시그널링 서버
 *
 * 역할:
 * - 방 생성/참가 (코드 매칭)
 * - 랜덤 매칭 대기열
 * - WebRTC SDP/ICE 후보 교환
 *
 * 프로토콜: WebSocket (JSON 메시지)
 */

const { WebSocketServer } = require('ws');
const http = require('http');

const PORT = process.env.PORT || 3000;

// HTTP 서버 (헬스체크용)
const httpServer = http.createServer((req, res) => {
  if (req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      status: 'ok',
      rooms: rooms.size,
      matchQueue: matchQueue.length,
      connections: wss.clients.size,
    }));
    return;
  }
  res.writeHead(404);
  res.end();
});

const wss = new WebSocketServer({ server: httpServer });

// === 상태 관리 ===

/** @type {Map<string, Set<WebSocket>>} roomId → Set<WebSocket> */
const rooms = new Map();

/** @type {WebSocket[]} 랜덤 매칭 대기열 */
const matchQueue = [];

/** @type {Map<WebSocket, string>} ws → roomId */
const clientRooms = new Map();

// === WebSocket 이벤트 ===

wss.on('connection', (ws) => {
  console.log(`[연결] 클라이언트 접속 (총 ${wss.clients.size}명)`);

  ws.isAlive = true;
  ws.on('pong', () => { ws.isAlive = true; });

  ws.on('message', (raw) => {
    try {
      const msg = JSON.parse(raw.toString());
      handleMessage(ws, msg);
    } catch (e) {
      sendError(ws, '잘못된 메시지 형식');
    }
  });

  ws.on('close', () => {
    handleDisconnect(ws);
    console.log(`[연결 해제] 총 ${wss.clients.size}명 남음`);
  });

  ws.on('error', (err) => {
    console.error('[에러]', err.message);
  });
});

// === 메시지 핸들러 ===

function handleMessage(ws, msg) {
  switch (msg.event) {
    case 'create-room':
      handleCreateRoom(ws, msg.roomId);
      break;
    case 'join-room':
      handleJoinRoom(ws, msg.roomId);
      break;
    case 'leave-room':
      handleLeaveRoom(ws, msg.roomId);
      break;
    case 'signal':
      handleSignal(ws, msg);
      break;
    case 'join-matchmaking':
      handleJoinMatchmaking(ws);
      break;
    case 'cancel-matchmaking':
      handleCancelMatchmaking(ws);
      break;
    default:
      sendError(ws, `알 수 없는 이벤트: ${msg.event}`);
  }
}

// --- 방 생성 ---
function handleCreateRoom(ws, roomId) {
  if (!roomId || roomId.length < 4) {
    sendError(ws, '방 코드는 4자 이상이어야 합니다');
    return;
  }

  const id = roomId.toUpperCase();

  if (rooms.has(id)) {
    sendError(ws, '이미 존재하는 방 코드입니다');
    return;
  }

  rooms.set(id, new Set([ws]));
  clientRooms.set(ws, id);

  send(ws, {
    event: 'room-created',
    roomId: id,
  });

  console.log(`[방 생성] ${id}`);
}

// --- 방 참가 ---
function handleJoinRoom(ws, roomId) {
  if (!roomId) {
    sendError(ws, '방 코드를 입력해주세요');
    return;
  }

  const id = roomId.toUpperCase();
  const room = rooms.get(id);

  if (!room) {
    sendError(ws, '존재하지 않는 방입니다');
    return;
  }

  if (room.size >= 2) {
    sendError(ws, '방이 가득 찼습니다');
    return;
  }

  room.add(ws);
  clientRooms.set(ws, id);

  // 참가자에게 알림
  send(ws, {
    event: 'room-joined',
    roomId: id,
    playerIndex: 1,
  });

  // 방장(Host)에게 알림
  for (const client of room) {
    if (client !== ws) {
      send(client, {
        event: 'peer-joined',
        roomId: id,
      });
    }
  }

  console.log(`[방 참가] ${id} (${room.size}명)`);
}

// --- 방 나가기 ---
function handleLeaveRoom(ws, roomId) {
  if (!roomId) return;

  const id = roomId.toUpperCase();
  const room = rooms.get(id);
  if (!room) return;

  room.delete(ws);
  clientRooms.delete(ws);

  if (room.size === 0) {
    rooms.delete(id);
    console.log(`[방 삭제] ${id}`);
  } else {
    // 남은 사람에게 상대 퇴장 알림
    for (const client of room) {
      send(client, {
        event: 'peer-left',
        roomId: id,
      });
    }
  }
}

// --- WebRTC 시그널 중계 ---
function handleSignal(ws, msg) {
  const roomId = msg.roomId;
  if (!roomId) return;

  const room = rooms.get(roomId.toUpperCase());
  if (!room) return;

  // 같은 방의 다른 사람에게 시그널 전달
  for (const client of room) {
    if (client !== ws && client.readyState === 1) {
      send(client, {
        event: 'signal',
        ...msg,
      });
    }
  }
}

// --- 랜덤 매칭 ---
function handleJoinMatchmaking(ws) {
  // 이미 대기열에 있으면 무시
  if (matchQueue.includes(ws)) return;

  // 대기열에 누군가 있으면 즉시 매칭
  if (matchQueue.length > 0) {
    const opponent = matchQueue.shift();

    // 둘 다 아직 연결 중인지 확인
    if (opponent.readyState !== 1) {
      // 상대가 끊겼으면 다시 대기열에 넣기
      matchQueue.push(ws);
      return;
    }

    // 방 생성
    const roomId = generateRoomCode();
    const room = new Set([opponent, ws]);
    rooms.set(roomId, room);
    clientRooms.set(opponent, roomId);
    clientRooms.set(ws, roomId);

    // Host (먼저 대기한 사람)
    send(opponent, {
      event: 'match-found',
      roomId,
      isHost: true,
      playerIndex: 0,
    });

    // Client
    send(ws, {
      event: 'match-found',
      roomId,
      isHost: false,
      playerIndex: 1,
    });

    console.log(`[랜덤 매칭] ${roomId}`);
  } else {
    matchQueue.push(ws);
    console.log(`[매칭 대기] 대기열 ${matchQueue.length}명`);
  }
}

function handleCancelMatchmaking(ws) {
  const idx = matchQueue.indexOf(ws);
  if (idx !== -1) {
    matchQueue.splice(idx, 1);
    console.log(`[매칭 취소] 대기열 ${matchQueue.length}명`);
  }
}

// --- 연결 해제 처리 ---
function handleDisconnect(ws) {
  // 매칭 대기열에서 제거
  const queueIdx = matchQueue.indexOf(ws);
  if (queueIdx !== -1) {
    matchQueue.splice(queueIdx, 1);
  }

  // 방에서 제거
  const roomId = clientRooms.get(ws);
  if (roomId) {
    handleLeaveRoom(ws, roomId);
  }
}

// === 유틸리티 ===

function send(ws, data) {
  if (ws.readyState === 1) {
    ws.send(JSON.stringify(data));
  }
}

function sendError(ws, message) {
  send(ws, { event: 'error', message });
}

function generateRoomCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let code = '';
  for (let i = 0; i < 6; i++) {
    code += chars[Math.floor(Math.random() * chars.length)];
  }
  return code;
}

// === 연결 유지 (Heartbeat) ===

const heartbeatInterval = setInterval(() => {
  wss.clients.forEach((ws) => {
    if (!ws.isAlive) {
      ws.terminate();
      return;
    }
    ws.isAlive = false;
    ws.ping();
  });
}, 30000);

wss.on('close', () => {
  clearInterval(heartbeatInterval);
});

// === 서버 시작 ===

httpServer.listen(PORT, () => {
  console.log(`고스톱 시그널링 서버 시작 — ws://localhost:${PORT}`);
  console.log(`헬스체크: http://localhost:${PORT}/health`);
});
