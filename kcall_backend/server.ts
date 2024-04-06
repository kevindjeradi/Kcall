// server.ts
import express from 'express';
import { WebSocket, Server as WebSocketServer } from 'ws';

const app = express();
const PORT = process.env.PORT || 3000;
const server = app.listen(PORT, () => console.log(`Server running on port ${PORT}`));

interface ExtendedWebSocket extends WebSocket {
    id: string;
}

const wss = new WebSocketServer({ server });

wss.on('connection', (ws: ExtendedWebSocket) => {
    ws.id = generateUniqueId();
    console.log('Client connected with id:', ws.id);

    ws.on('message', (message: string) => {
        const parsedMessage = JSON.parse(message);
        console.log('Received message:', parsedMessage);

        switch (parsedMessage.type) {
            case 'call':
            case 'call-accepted':
            case 'call-rejected':
                // Targeted messaging for call actions
                broadcastMessage(ws, message, parsedMessage.targetId);
                break;
            case 'call-ended':
                // Broadcast or target the call-ended message as necessary
                broadcastMessage(ws, message, parsedMessage.targetId);
                break;
            case 'offer':
            case 'answer':
            case 'candidate':
                // Broadcast WebRTC signaling messages
                broadcastMessage(ws, message);
                break;
            default:
                console.log('Unknown message type:', parsedMessage.type);
        }
    });

    ws.on('close', () => console.log('Client disconnected'));
});

function broadcastMessage(sender: ExtendedWebSocket, message: string, targetClientId: string | null = null) {
    if (targetClientId) {
        // Directly targeting a specific client based on targetClientId
        wss.clients.forEach(client => {
            const extendedClient = client as ExtendedWebSocket;
            if (extendedClient.id === targetClientId && client.readyState === WebSocket.OPEN) {
                client.send(message);
            }
        });
    } else {
        // Broadcasting to all clients except the sender
        wss.clients.forEach(client => {
            if (client !== sender && client.readyState === WebSocket.OPEN) {
                client.send(message);
            }
        });
    }
}

function generateUniqueId(): string {
    // Simple unique ID generator - i will need a more robust method for production
    return Math.random().toString(36).substr(2, 9);
}
