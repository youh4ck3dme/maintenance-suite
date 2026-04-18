import { describe, it, expect, beforeAll } from 'vitest';
import request from 'supertest';
import { buildApp } from '../app.mjs';

describe('Maintenance Suite API', () => {
  let app;

  beforeAll(async () => {
    // Testing mode skips actual shell execution but emits logs
    app = await buildApp({ logger: false, testing: true });
    await app.ready();
  });

  describe('GET /api/history', () => {
    it('1. should return an array', async () => {
      const response = await request(app.server).get('/api/history');
      expect(response.status).toBe(200);
      expect(Array.isArray(response.body)).toBe(true);
    });

    it('2. should handle missing records gracefully (return empty or existing array)', async () => {
      const response = await request(app.server).get('/api/history');
      expect(response.status).toBe(200);
      // Even if file doesn't exist, it returns [] per app.mjs logic
      expect(response.body).toBeInstanceOf(Array);
    });

    it('3. should have valid structure for history entries if any exist', async () => {
      const response = await request(app.server).get('/api/history');
      if (response.body.length > 0) {
        const entry = response.body[0];
        expect(entry).toHaveProperty('timestamp');
        expect(entry).toHaveProperty('totalFreedMB');
      }
    });
  });

  describe('GET /api/stats', () => {
    it('1. should return disk capacity data object', async () => {
      const response = await request(app.server).get('/api/stats');
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('total');
    });

    it('2. should have numerical values for free space', async () => {
      const response = await request(app.server).get('/api/stats');
      expect(typeof response.body.free).toBe('number');
    });

    it('3. should have numerical values for used space', async () => {
      const response = await request(app.server).get('/api/stats');
      expect(typeof response.body.used).toBe('number');
    });
  });

  describe('POST /api/run/:type', () => {
    it('1. should successfully start FULL cleanup', async () => {
      const response = await request(app.server).post('/api/run/full');
      expect(response.status).toBe(200);
      expect(response.body.status).toBe('started');
      expect(response.body.type).toBe('full');
    });

    it('2. should successfully start NPM cleanup', async () => {
      const response = await request(app.server).post('/api/run/npm');
      expect(response.status).toBe(200);
      expect(response.body.type).toBe('npm');
    });

    it('3. should successfully start PNPM cleanup', async () => {
      const response = await request(app.server).post('/api/run/pnpm');
      expect(response.status).toBe(200);
      expect(response.body.type).toBe('pnpm');
    });
  });

  describe('GET /api/logs (SSE)', () => {
    // SSE is persistent, so we check headers and initial response start
    it('1. should use text/event-stream content type', async () => {
      const resp = await request(app.server)
        .get('/api/logs')
        .set('Accept', 'text/event-stream')
        .timeout(2000)
        .then(res => res, err => err.response); // Catch timeout but keep response if headers arrived
      
      // If we got headers before timeout, check them
      if (resp) {
        expect(resp.header['content-type']).toContain('text/event-stream');
      }
    });

    it('2. should include retry parameter in the stream', async () => {
      // Direct fetch to avoid supertest's buffering issues with SSE
      const resp = await request(app.server).get('/api/logs').set('Accept', 'text/event-stream');
      expect(resp.text).toContain('retry: 1000');
    });

    it('3. should return 200 OK status on connection', async () => {
      const response = await request(app.server).get('/api/logs');
      expect(response.status).toBe(200);
    });
  });
});
