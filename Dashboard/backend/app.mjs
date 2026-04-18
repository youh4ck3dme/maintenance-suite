import Fastify from 'fastify';
import fastifyStatic from '@fastify/static';
import fastifyCors from '@fastify/cors';
import { spawn } from 'child_process';
import path from 'path';
import { fileURLToPath } from 'url';
import { EventEmitter } from 'events';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

import fs from 'fs/promises';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

export const logEmitter = new EventEmitter();

export async function buildApp(opts = {}) {
    const fastify = Fastify(opts);

    // Global Error Handler to prevent process crashes
    fastify.setErrorHandler((error, request, reply) => {
        fastify.log.error(error);
        reply.status(500).send({ error: 'Internal Server Error', message: error.message });
    });

    // Enable CORS
    await fastify.register(fastifyCors, { origin: '*' });

    // Serve static frontend files
    await fastify.register(fastifyStatic, {
        root: path.join(__dirname, '../frontend'),
        prefix: '/',
    });

    // GET /api/history - Vráti históriu čistenia
    fastify.get('/api/history', async (request, reply) => {
        try {
            const historyPath = path.join(__dirname, 'history.json');
            const data = await fs.readFile(historyPath, 'utf-8');
            return JSON.parse(data);
        } catch (err) {
            return [];
        }
    });

    // GET /api/stats - Aktuálny stav disku (Windows)
    fastify.get('/api/stats', async (request, reply) => {
        try {
            // Použijeme powershell na zistenie stavu C: disku
            const { stdout } = await execAsync('powershell "Get-PSDrive C | Select-Object Used, Free | ConvertTo-Json"');
            const disk = JSON.parse(stdout);
            return {
                used: Math.round(disk.Used / (1024 ** 3)), // GB
                free: Math.round(disk.Free / (1024 ** 3)), // GB
                total: Math.round((disk.Used + disk.Free) / (1024 ** 3))
            };
        } catch (err) {
            return { used: 0, free: 0, total: 0, error: err.message };
        }
    });

    // SSE endpoint for live logs
    fastify.get('/api/logs', (request, reply) => {
        reply.raw.setHeader('Content-Type', 'text/event-stream');
        reply.raw.setHeader('Cache-Control', 'no-cache');
        reply.raw.setHeader('Connection', 'keep-alive');
        reply.raw.write('retry: 1000\n\n');

        const onLog = (data) => {
            try {
                reply.raw.write(`data: ${JSON.stringify(data)}\n\n`);
            } catch (err) {
                // If the stream is closed, removing the listener is handled by 'close' event
            }
        };

        logEmitter.on('log', onLog);

        request.raw.on('close', () => {
            logEmitter.removeListener('log', onLog);
        });
    });

    // Endpoint to run cleanup scripts
    fastify.post('/api/run/:type', async (request, reply) => {
        const { type } = request.params;
        let scriptPath = '';

        const rootCleanupScript = path.resolve(__dirname, '../../Run-Cleanup.ps1');

        if (type === 'full') {
            scriptPath = rootCleanupScript;
        } else if (type === 'npm') {
            scriptPath = rootCleanupScript; 
        } else if (type === 'pnpm') {
            scriptPath = rootCleanupScript;
        } else {
            return reply.code(400).send({ error: 'Invalid cleanup type' });
        }

        // Feature: Support testing mode to skip actual shell execution
        if (opts.testing) {
            return { status: 'started', type, mode: 'testing' };
        }

        const ps = spawn('powershell.exe', ['-ExecutionPolicy', 'Bypass', '-File', scriptPath]);

        ps.stdout.on('data', (data) => {
            const message = data.toString().trim();
            if (message) {
                logEmitter.emit('log', { message, type: 'info' });
            }
        });

        ps.stderr.on('data', (data) => {
            const message = data.toString().trim();
            if (message) {
                logEmitter.emit('log', { message: `ERROR: ${message}`, type: 'error' });
            }
        });

        ps.on('close', (code) => {
            logEmitter.emit('log', { message: `Proces skončil s kódom ${code}`, type: 'system' });
        });

        return { status: 'started', type };
    });

    return fastify;
}
