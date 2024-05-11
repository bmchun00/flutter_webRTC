import asyncio
import websockets
import json

connected = set()

async def server(websocket, path):
    # 클라이언트 연결 추가
    connected.add(websocket)
    try:
        # 클라이언트로부터 메시지를 기다림
        async for message in websocket:
            data = json.loads(message)  # JSON 형태의 메시지 파싱

            # SDP 또는 ICE 후보 정보 교환 처리
            if data["type"] == "offer":
                print("offer 들어옴 : ", data)
                # 수신한 offer를 저장하고 다른 클라이언트에게 전달
                # 이 예에서는 단방향 스트리밍을 위해 특정 클라이언트를 대상으로 전달하며,
                # 실제 구현에서는 클라이언트 식별자를 기반으로 대상을 선별할 필요가 있음
                for conn in connected:
                    if conn != websocket:
                        await conn.send(json.dumps(data))
            elif data["type"] == "answer":
                # 수신한 answer를 해당 offer를 보낸 클라이언트에게 전달
                for conn in connected:
                    if conn != websocket:
                        await conn.send(json.dumps(data))
            elif data["type"] == "candidate":
                # ICE 후보 정보 교환
                for conn in connected:
                    if conn != websocket:
                        await conn.send(json.dumps(data))
            elif data["type"] == "streamers":
                # 현재 offer상태의 클라이언트 정보 제공

    finally:
        # 클라이언트 연결 제거
        connected.remove(websocket)

# 서버 시작
start_server = websockets.serve(server, "localhost", 6789)

asyncio.get_event_loop().run_until_complete(start_server)
asyncio.get_event_loop().run_forever()
