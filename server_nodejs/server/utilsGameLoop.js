'use strict';

const TARGET_FPS = 35;
const TARGET_MS = 1000 / TARGET_FPS;

class GameLoop {
    constructor() {
        this.running = false;
        this.frameCount = 0;
        this.fpsStartTime = Date.now();
        this.currentFPS = 0;
        this.run = (fps) => { console.log(`${parseInt(fps)}fps. Remember to overrite GameLoop' "run" method!`) };
    }

    start() {
        if (!this.running) {
            this.running = true;
            this.loop();
        }
    }

    stop() {
        this.running = false;
    }

    loop() {
        const startTime = Date.now();

        if (!this.running) return;

        if (this.currentFPS >= 1 && typeof this.run === "function") {
            this.run(this.currentFPS);
        }

        const endTime = Date.now();
        const elapsedTime = endTime - startTime;
        const remainingTime = Math.max(1, TARGET_MS - elapsedTime);

        this.frameCount++;
        const fpsElapsedTime = endTime - this.fpsStartTime;
        if (fpsElapsedTime >= 500) {
            this.currentFPS = (this.frameCount / fpsElapsedTime) * 1000;
            this.frameCount = 0;
            this.fpsStartTime = endTime;
        }

        setTimeout(() => setImmediate(() => this.loop()), remainingTime);
    }
}

module.exports = GameLoop;