from collections import defaultdict
from typing import Any, DefaultDict, List, Optional, Tuple

from fastapi import WebSocket


class ChatWebSocketManager:
    def __init__(self) -> None:
        self._connections: DefaultDict[int, List[Tuple[int, WebSocket]]] = defaultdict(list)
        self._admin_connections: DefaultDict[int, List[WebSocket]] = defaultdict(list)

    async def connect(self, conversation_id: int, user_id: int, websocket: WebSocket) -> None:
        await websocket.accept()
        self._connections[conversation_id].append((user_id, websocket))

    def disconnect(self, conversation_id: int, websocket: WebSocket) -> None:
        sockets = self._connections.get(conversation_id, [])
        self._connections[conversation_id] = [
            (uid, ws) for uid, ws in sockets if ws != websocket
        ]
        if not self._connections[conversation_id]:
            self._connections.pop(conversation_id, None)

    def has_user_connection(self, conversation_id: int, user_id: int) -> bool:
        sockets = self._connections.get(conversation_id, [])
        return any(uid == user_id for uid, _ in sockets)

    async def connect_admin(self, admin_id: int, websocket: WebSocket) -> None:
        await websocket.accept()
        self._admin_connections[admin_id].append(websocket)

    def disconnect_admin(self, admin_id: int, websocket: WebSocket) -> None:
        sockets = self._admin_connections.get(admin_id, [])
        self._admin_connections[admin_id] = [ws for ws in sockets if ws != websocket]
        if not self._admin_connections[admin_id]:
            self._admin_connections.pop(admin_id, None)

    async def send_personal(self, websocket: WebSocket, payload: Any) -> None:
        await websocket.send_json(payload)

    async def broadcast(
        self,
        conversation_id: int,
        payload: Any,
        exclude_user_id: Optional[int] = None,
    ) -> None:
        sockets = list(self._connections.get(conversation_id, []))
        disconnected: List[WebSocket] = []
        for uid, ws in sockets:
            if exclude_user_id is not None and uid == exclude_user_id:
                continue
            try:
                await ws.send_json(payload)
            except Exception:
                disconnected.append(ws)

        for ws in disconnected:
            self.disconnect(conversation_id, ws)

    async def broadcast_admin(self, admin_id: int, payload: Any) -> None:
        sockets = list(self._admin_connections.get(admin_id, []))
        disconnected: List[WebSocket] = []
        for ws in sockets:
            try:
                await ws.send_json(payload)
            except Exception:
                disconnected.append(ws)

        for ws in disconnected:
            self.disconnect_admin(admin_id, ws)


chat_ws_manager = ChatWebSocketManager()
