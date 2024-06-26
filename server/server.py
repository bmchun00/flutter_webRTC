import asyncio
import websockets
import json
import uuid

connected = {}
offers = {}

async def server(websocket, path):
    # 클라이언트 연결 추가
    session_key = str(uuid.uuid4())
    connected[session_key] = websocket
    await connected[session_key].send(json.dumps({'type' : 'sessionId', 'sessionId' : session_key})) #첫 연결시 세션 키 전달
    try:
        # 클라이언트로부터 메시지를 기다림
        async for message in websocket:
            data = json.loads(message)  # JSON 형태의 메시지 파싱

            # SDP 또는 ICE 후보 정보 교환 처리
            if data["type"] == "offer":
                print("offer 들어옴 : ")
                offers[session_key] = data
                # 현재 offer를 저장
                
            elif data["type"] == "answer":
                # 수신한 answer를 해당 offer를 보낸 클라이언트에게 전달
                print("앤서 받음")
                streamer = data["target_id"]
                if streamer in connected:
                    if connected[streamer] != websocket:
                        await connected[streamer].send(json.dumps(data))
                
            elif data["type"] == "candidate":
                # ICE 후보 정보 교환
                print("캔디 들어옴 : ")
                id = data["target_id"]
                if id in connected:
                    await connected[id].send(json.dumps(data))
                        
            elif data["type"] == "streamers":
                # 현재 offer상태의 클라이언트 정보 제공
                idList = []
                sdpList = []
                for i in offers:
                    idList.append(i)
                    sdpList.append(offers[i]['sdp'])
                clients = {'type':'streamers', 'id':idList, 'sdp':sdpList}
                await websocket.send(json.dumps(clients))

                print('offers 보냄')

    finally:
        # 클라이언트 연결 제거
        connected.pop(session_key, None)
        if session_key in offers: #만약 해당 클라이언트가 스트리머였다면
            offers.pop(session_key,None)

# 서버 시작
start_server = websockets.serve(server, "192.168.35.159", 6789)

asyncio.get_event_loop().run_until_complete(start_server)
asyncio.get_event_loop().run_forever()
