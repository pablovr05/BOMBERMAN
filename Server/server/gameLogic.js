'use strict';

const BLOCK_TYPES = {
    EMPTY: 0,
    DESTRUCTIBLE: 1,
    INDESTRUCTIBLE: 2
};

const OBJECT_WIDTH = 0.075;
const OBJECT_HEIGHT = 0.025;
const SPEED = 0.2;
const INITIAL_RADIUS = 0.05;

const OBJECT_POSITIONS = {
    "position0": { x: 48, y: 48 },
    "position1": { x: 464, y: 48 },
    "position2": { x: 48, y: 464 },
    "position3": { x: 464, y: 464 },
};

const DIRECTIONS = {
    "up":         { dx: 0, dy: -1 },
    "upLeft":     { dx: -1, dy: -1 },
    "left":       { dx: -1, dy: 0 },
    "downLeft":   { dx: -1, dy: 1 },
    "down":       { dx: 0, dy: 1 },
    "downRight":  { dx: 1, dy: 1 },
    "right":      { dx: 1, dy: 0 },
    "upRight":    { dx: 1, dy: -1 },
    "none":       { dx: 0, dy: 0 }
};

class GameLogic {
    constructor() {
        this.objects = [];
        this.players = new Map();

        for (let i = 0; i < 10; i++) {
            this.objects.push({
                x: Math.random() * (1 - OBJECT_WIDTH),
                y: Math.random() * (1 - OBJECT_HEIGHT),
                width: OBJECT_WIDTH,
                height: OBJECT_HEIGHT,
                speed: SPEED,
                direction: Math.random() > 0.5 ? 1 : -1
            });
        }
    }

    addClient(id) {
        let positionKeys = Object.keys(OBJECT_POSITIONS);
        let randomPositionKey = positionKeys[Math.floor(Math.random() * positionKeys.length)];
        let pos = OBJECT_POSITIONS[randomPositionKey];

        this.players.set(id, {
            id,
            x: pos.x / 500,
            y: pos.y / 500,
            speed: SPEED,
            direction: "none",
            radius: INITIAL_RADIUS
        });

        return this.players.get(id);
    }

    removeClient(id) {
        this.players.delete(id);
    }

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

    updateGame(fps) {
        let deltaTime = 1 / fps;

        this.players.forEach(client => {
            let moveVector = DIRECTIONS[client.direction];
            client.x = Math.max(0, Math.min(1, client.x + client.speed * moveVector.dx * deltaTime));
            client.y = Math.max(0, Math.min(1, client.y + client.speed * moveVector.dy * deltaTime));
        });
    }

    getGameState() {
        return {
            objects: this.objects,
            players: Array.from(this.players.values())
        };
    }
}

module.exports = GameLogic;
