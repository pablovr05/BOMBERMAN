const fs = require('fs');
'use strict';

const COLORS = ['green', 'blue', 'orange', 'red'];
const POSITIONS = [
    { x: 1.5, y: 1.5 },
    { x: 13.5, y: 13.5 },
    { x: 13.5, y: 1.5 },
    { x: 1.5, y: 13.5 }
];

const SPEED = 0.075;
const RADIUS = 0.01;

const BOMBS = 1;
const BOMB_POWER = 2;

const DIRECTIONS = {
    "up": { dx: 0, dy: -1 },
    "left": { dx: -1, dy: 0 },
    "down": { dx: 0, dy: 1 },
    "right": { dx: 1, dy: 0 },
    "none": { dx: 0, dy: 0 }
};

class GameLogic {
    constructor(ws) {
        this.ws = ws;
        this.players = new Map();
        this.mapData = this.loadMapData();
        this.nextSpawnIndex = 0;
        this.bombs = []
    }

    addClient(id, ws) {
        let pos = this.getNextPosition();
        let color = this.getAvailableColor();
    
        // Asociar el WebSocket con el ID del jugador
        this.players.set(id, {
            id,
            x: pos.x,
            y: pos.y,
            speed: SPEED,
            direction: "none",
            color,
            radius: RADIUS,
            bombs: BOMBS,
            bomb_power: BOMB_POWER,
            ws: ws,  // Aquí estamos almacenando el WebSocket del jugador
        });
    
        return this.players.get(id);
    }
    

    // Es desconnecta un client/jugador
    removeClient(id) {
        this.players.delete(id);
    }

    updateBombs(fps) {
        const currentTime = Date.now();
        
        // Iterar sobre las bombas activas
        this.bombs.forEach((bomb, index) => {
            // Calcular el tiempo transcurrido desde que se activó la bomba
            const elapsedTime = (currentTime - bomb.timeStamp) / 1000; // en segundos
    
            // Actualizar el estado de la bomba cada 0.25 segundos (aproximadamente)
            if (elapsedTime >= 0.25) {
                bomb.timeStamp = currentTime; // Reiniciar el tiempo de la bomba
                bomb.currentState++; // Incrementar el estado de la bomba
    
                if (bomb.currentState > 12) {
                    // La bomba explota, marcar los efectos de la explosión
                    this.explodeBomb(bomb);
    
                    // Eliminar la bomba de la lista
                    this.bombs.splice(index, 1);
                } else {
                    // Actualizar el estado de la bomba en el mapa
                    this.mapData.levels[0].layers[2].tileMap[bomb.y][bomb.x] = bomb.currentState;
                    console.log(`Bomba en estado ${bomb.currentState} en: (${bomb.x}, ${bomb.y})`);
                }
            }
        });
    }
    
    explodeBomb(bomb) {
        const bombX = bomb.x;
        const bombY = bomb.y;
        const bombPower = BOMB_POWER;  
    
        const directions = [
            { dx: 0, dy: -1 }, // Arriba
            { dx: 0, dy: 1 },  // Abajo
            { dx: -1, dy: 0 }, // Izquierda
            { dx: 1, dy: 0 }   // Derecha
        ];
    
        let explosionTiles = [{ x: bombX, y: bombY }]; // Guardamos todas las casillas afectadas
    
        // Marcar el centro de la explosión
        this.mapData.levels[0].layers[2].tileMap[bombY][bombX] = 13;
    
        // Expandir la explosión en las direcciones
        directions.forEach(direction => {
            let x = bombX;
            let y = bombY;
    
            for (let i = 1; i <= bombPower; i++) {
                x += direction.dx;
                y += direction.dy;
    
                if (x < 0 || x >= this.mapData.levels[0].layers[2].tileMap[0].length || y < 0 || y >= this.mapData.levels[0].layers[2].tileMap.length) {
                    break;
                }
    
                if (this.mapData.levels[0].layers[1].tileMap[y][x] === 2) {
                    break;  
                }
    
                if (this.mapData.levels[0].layers[2].tileMap[y][x] === 0) {
                    this.mapData.levels[0].layers[2].tileMap[y][x] = -1;
                    break;  
                }
    
                this.mapData.levels[0].layers[2].tileMap[y][x] = 13;
                explosionTiles.push({ x, y }); // Guardamos la casilla afectada
            }
        });
    
        console.log(`La bomba explotó en: (${bombX}, ${bombY})`);
    
        // Verificar si algún jugador está en la zona de explosión
        this.checkPlayersHit(explosionTiles);
    
        // Revertir la explosión después de un tiempo
        setTimeout(() => {
            this.clearExplosion(bombX, bombY, bombPower);
        }, 500);
    }
    
    checkPlayersHit(explosionTiles) {
        this.players.forEach((player, playerId) => {
            let playerX = Math.floor(player.x);
            let playerY = Math.floor(player.y);
    
            // Comprobar si la posición del jugador está en la lista de explosión
            if (explosionTiles.some(tile => tile.x === playerX && tile.y === playerY)) {
                console.log(`¡Jugador ${playerId} fue alcanzado por la explosión en (${playerX}, ${playerY})!`);
                let ws = player.ws;
                console.log(ws)
                if (ws) {
                    // Enviar un mensaje al jugador
                    ws.send(JSON.stringify({
                        type: "explosionHit",
                        message: `¡Fuiste alcanzado por la explosión!`
                    }));
                }
            }
        });
    }
    
    
    // Función para revertir la explosión
    clearExplosion(bombX, bombY, bombPower) {
        // Direcciones de la explosión (arriba, abajo, izquierda, derecha)
        const directions = [
            { dx: 0, dy: -1 }, // Arriba
            { dx: 0, dy: 1 },  // Abajo
            { dx: -1, dy: 0 }, // Izquierda
            { dx: 1, dy: 0 }   // Derecha
        ];
        
        // Primero, revertir el centro de la explosión
        this.mapData.levels[0].layers[2].tileMap[bombY][bombX] = -1;  // Revertir la explosión en el centro
        
        // Revertir las explosiones en las cuatro direcciones
        directions.forEach(direction => {
            let x = bombX;
            let y = bombY;
            
            // Propagar la reversión hasta el alcance de la bomba (bombPower)
            for (let i = 1; i <= bombPower; i++) {
                x += direction.dx;
                y += direction.dy;
    
                // Comprobar si las coordenadas están dentro de los límites del mapa
                if (x < 0 || x >= this.mapData.levels[0].layers[2].tileMap[0].length || y < 0 || y >= this.mapData.levels[0].layers[2].tileMap.length) {
                    break; // Si está fuera de los límites, detener la explosión
                }
    
                // Revertir la explosión en esas casillas
                if (this.mapData.levels[0].layers[2].tileMap[y][x] === 13) {
                    this.mapData.levels[0].layers[2].tileMap[y][x] = -1;  // Revertir la explosión a -1 (ladrillo o vacío)
                }
            }
        });
    
        console.log(`La explosión fue revertida en: (${bombX}, ${bombY})`);
    }
    
    
    
    handleMessage(id, msg) {
        try {
            let obj = JSON.parse(msg);
            if (!obj.type) return;
            switch (obj.type) {
                case "direction":
                    if (this.players.has(id) && DIRECTIONS[obj.value]) {
                        this.players.get(id).direction = obj.value;
                        if (obj.isSpace === true) {
                            let posX = Math.floor(this.players.get(id).x);
                            let posY = Math.floor(this.players.get(id).y);
    
                            // Comprobar si la posición es válida para poner una bomba
                            if (this.mapData.levels[0].layers[2].tileMap[posY][posX] === -1) {
                                console.log(`Se procede a poner una bomba en: ${posX},${posY}`);
                                this.mapData.levels[0].layers[2].tileMap[posY][posX] = 3; // Estado inicial de la bomba
                                
                                // Guardar la bomba activa con el tiempo de inicio
                                this.bombs.push({
                                    x: posX,
                                    y: posY,
                                    currentState: 3,  // Estado inicial de la bomba
                                    timeStamp: Date.now(), // Guardamos el tiempo actual
                                });
                            } else {
                                console.log(`No se puede poner bomba, ya existe una en: ${posX}, ${posY}`);
                            }
                        }
                    }
                    break;
                default:
                    break;
            }
        } catch (error) {
            console.error("Error al manejar el mensaje:", error);
        }
    }
    

    // Función para verificar si la nueva posición es válida
isValidMove(x, y) {
    // Convertir las coordenadas del jugador a índices de la cuadrícula
    const gridX = Math.floor(x);  // x * 15 y redondeo hacia abajo
    const gridY = Math.floor(y);  // y * 15 y redondeo hacia abajo

    // Agregar un log para ver las coordenadas de la cuadrícula
    //console.log(`Posición del jugador en la cuadrícula: (${gridX}, ${gridY})`);

    // Obtener las capas del mapa (suelo, muros, ladrillos)
    const grassLayer = this.mapData.levels[0].layers[0].tileMap || [];
    const wallsLayer = this.mapData.levels[0].layers[1].tileMap || [];
    const bricksLayer = this.mapData.levels[0].layers[2].tileMap || [];

    // Verificar que la nueva posición no colisione con muros o ladrillos
    const isGrass = grassLayer[gridY][gridX] === 0 || grassLayer[gridY][gridX] === 1;
    const isWall = wallsLayer[gridY][gridX] === 2;
    const isBrick = bricksLayer[gridY][gridX] === 0; // -1 indica ladrillo

    // Agregar logs para mostrar el estado de cada capa
    //console.log(`¿Es tierra? ${isGrass ? "Sí" : "No"}`);
    //console.log(`¿Es muro? ${isWall ? "Sí" : "No"}`);
    //console.log(`¿Es ladrillo? ${isBrick ? "Sí" : "No"}`);

    // Permitir movimiento solo si la posición es suelo (0 o 1) y no es un muro ni un ladrillo
    const validMove = isGrass && !isWall && !isBrick;
    //console.log(`Movimiento válido: ${validMove ? "Sí" : "No"}`);
    return validMove;
}

// Función para actualizar el estado del juego
updateGame(fps) {
    const deltaTime = 35 / fps;  // Tiempo transcurrido entre fotogramas

    this.players.forEach(client => {
        const moveVector = DIRECTIONS[client.direction];

        // Calcular la nueva posición real
        const newX = client.x + client.speed * moveVector.dx * deltaTime;
        const newY = client.y + client.speed * moveVector.dy * deltaTime;

        // Verificar si la nueva posición es válida usando 'isValidMove' sin modificar la posición real
        if (this.isValidMove(Math.floor(newX), Math.floor(newY))) {
            client.x = newX;
            client.y = newY;
        }
    });

    // Actualizar el estado de las bombas
    this.updateBombs(fps);
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
