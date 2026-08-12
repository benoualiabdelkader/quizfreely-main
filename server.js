import { handler } from './build/handler.js';
import express from 'express';
import { createProxyMiddleware } from 'http-proxy-middleware';
import dotenv from 'dotenv';

dotenv.config();

const app = express();

// Proxy API requests
app.use('/api', createProxyMiddleware({
    target: process.env.API_URL || 'https://quizfreely.org/api',
    changeOrigin: true,
    pathRewrite: {
        '^/api': '', // remove /api prefix
    },
    onProxyRes: function (proxyRes, req, res) {
        // Remove Secure flag from cookies so they work over HTTP on Render if needed
        const setCookie = proxyRes.headers['set-cookie'];
        if (setCookie) {
            const cookies = Array.isArray(setCookie) ? setCookie : [setCookie];
            proxyRes.headers['set-cookie'] = cookies.map(cookie => cookie.replace(/;\s*Secure/gi, ''));
        }
    }
}));

// Proxy Realtime requests
app.use('/realtime', createProxyMiddleware({
    target: process.env.REALTIME_SERVER_URL || 'https://quizfreely.org/realtime',
    changeOrigin: true,
    ws: true,
    pathRewrite: {
        '^/realtime': '',
    }
}));

// Let SvelteKit handle everything else
app.use(handler);

const port = process.env.PORT || 10000;
app.listen(port, () => {
    console.log(`Server listening on port ${port}`);
});
