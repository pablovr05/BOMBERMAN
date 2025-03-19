const fs = require('fs');
'use strict';

const COLORS = ['green', 'blue', 'orange', 'red'];
const POSITIONS = [
    { x: 0.1, y: 0.1 },
    { x: 0.9, y: 0.1 },
    { x: 0.1, y: 0.9 },
    { x: 0.9, y: 0.9 }
];

const SPEED = 0.2;
const RADIUS = 0.01;

const DIRECTIONS = {
    "up": { dx: 0, dy: -1 },
    "left": { dx: -1, dy: 0 },
    "down": { dx: 0, dy: 1 },
    "right": { dx: 1, dy: 0 },
    "none": { dx: 0, dy: 0 }
};

class GameLogic {
    constructor() {
        this.players = new Map();
        this.mapData = this.loadMapData();
        this.nextSpawnIndex = 0;
    }

    // Es connecta un client/jugador
    addClient(id) {
        let pos = this.getNextPosition();
        let color = this.getAvailableColor();

        this.players.set(id, {
            id,
            x: pos.x,
            y: pos.y,
            speed: SPEED,
            direction: "none",
            color,
            radius: RADIUS
        });

        return this.players.get(id);
    }

    // Es desconnecta un client/jugador
    removeClient(id) {
        this.players.delete(id);
    }

    // Tractar un missatge d'un client/jugador
    handleMessage(id, msg) {
        try {
            let obj = JSON.parse(msg);
            if (!obj.type) return;
            switch (obj.type) {
                case "direction":
                    if (this.players.has(id) && DIRECTIONS[obj.value]) {
                        this.players.get(id).direction = obj.value;
                    }
                    break;
                default:
                    break;
            }
        } catch (error) {}
    }

    // Blucle de joc (funció que s'executa contínuament)
    updateGame(fps) {
        let deltaTime = 1 / fps;

        // Actualitzar la posició dels clients
        this.players.forEach(client => {
            let moveVector = DIRECTIONS[client.direction];
            client.x = Math.max(0, Math.min(1, client.x + client.speed * moveVector.dx * deltaTime));
            client.y = Math.max(0, Math.min(1, client.y + client.speed * moveVector.dy * deltaTime));
        });
    }

    // Funció para obtener la siguiente posición predefinida
    getNextPosition() {
        if (this.nextSpawnIndex >= POSITIONS.length) {
            this.nextSpawnIndex = 0;  // Resetear al principio si no hay más posiciones disponibles
        }
        let pos = POSITIONS[this.nextSpawnIndex];
        this.nextSpawnIndex++;  // Avanzar al siguiente índice para el próximo jugador
        return pos;
    }

    // Obtener un color aleatorio que no haya sido usado
    getAvailableColor() {
        let assignedColors = new Set(Array.from(this.players.values()).map(client => client.color));
        let availableColors = COLORS.filter(color => !assignedColors.has(color));
        return availableColors.length > 0
            ? availableColors[Math.floor(Math.random() * availableColors.length)]
            : COLORS[Math.floor(Math.random() * COLORS.length)];
    }

    // Retorna el estado del juego (para enviarlo a los clientes/jugadores)
    getGameState() {
        return {
            players: Array.from(this.players.values()),
            map: this.mapData, // Agregar el mapa al estado del juego
        };
    }

    loadMapData() {
        try {
            const rawData = fs.readFileSync('assets/game_data.json', 'utf8');
            const mapData = JSON.parse(rawData);
            return mapData;
        } catch (error) {
            console.error('Error al cargar el mapa:', error);
            return null;
        }
    }
}

module.exports = GameLogic;
