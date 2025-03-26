const fs = require('fs');
'use strict';

const COLORS = ['green', 'blue', 'orange', 'red'];
const POSITIONS = [
    { x: 1.5, y: 1.5 },
    { x: 13.5, y: 13.5 },
    { x: 13.5, y: 1.5 },
    { x: 1.5, y: 13.5 }
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
        console.log(pos)
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

    // Función para verificar si la nueva posición es válida
isValidMove(x, y) {
    // Convertir las coordenadas del jugador a índices de la cuadrícula
    const gridX = Math.floor(x);  // x * 15 y redondeo hacia abajo
    const gridY = Math.floor(y);  // y * 15 y redondeo hacia abajo

    // Agregar un log para ver las coordenadas de la cuadrícula
    console.log(`Posición del jugador en la cuadrícula: (${gridX}, ${gridY})`);

    // Obtener las capas del mapa (suelo, muros, ladrillos)
    const grassLayer = this.mapData.levels[0].layers[0].tileMap || [];
    const wallsLayer = this.mapData.levels[0].layers[1].tileMap || [];
    const bricksLayer = this.mapData.levels[0].layers[2].tileMap || [];

    // Verificar que la nueva posición no colisione con muros o ladrillos
    const isGrass = grassLayer[gridY][gridX] === 0 || grassLayer[gridY][gridX] === 1;
    const isWall = wallsLayer[gridY][gridX] === 2;
    const isBrick = bricksLayer[gridY][gridX] === 0; // -1 indica ladrillo

    // Agregar logs para mostrar el estado de cada capa
    console.log(`¿Es tierra? ${isGrass ? "Sí" : "No"}`);
    console.log(`¿Es muro? ${isWall ? "Sí" : "No"}`);
    console.log(`¿Es ladrillo? ${isBrick ? "Sí" : "No"}`);

    // Permitir movimiento solo si la posición es suelo (0 o 1) y no es un muro ni un ladrillo
    const validMove = isGrass && !isWall && !isBrick;
    console.log(`Movimiento válido: ${validMove ? "Sí" : "No"}`);
    return validMove;
}

// Función para actualizar el estado del juego
updateGame(fps) {
    const deltaTime = 35 / fps;  // Tiempo transcurrido entre fotogramas

    this.players.forEach(client => {
        console.log(client);
        const moveVector = DIRECTIONS[client.direction];

        // Calcular la nueva posición real
        const newX = client.x + client.speed * moveVector.dx * deltaTime;
        const newY = client.y + client.speed * moveVector.dy * deltaTime;

        console.log(`Jugador ${client.id} - Nueva posición tentativa: (${newX}, ${newY})`);

        // Verificar si la nueva posición es válida usando 'isValidMove' sin modificar la posición real
        if (this.isValidMove(Math.floor(newX), Math.floor(newY))) {
            // Si es válida, aplicar la nueva posición sin redondear
            client.x = newX;
            client.y = newY;

            console.log(`Jugador ${client.id} movido a: (${client.x}, ${client.y})`);
        } else {
            console.log(`Movimiento inválido para el jugador ${client.id}. No se movió.`);
        }
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
