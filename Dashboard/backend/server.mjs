import { buildApp } from './app.mjs';

const start = async () => {
    const app = await buildApp({ logger: true });
    try {
        await app.listen({ port: 3456, host: '0.0.0.0' });
        console.log('Maintenance Suite Server beží na http://localhost:3456');
    } catch (err) {
        app.log.error(err);
        process.exit(1);
    }
};

start();
