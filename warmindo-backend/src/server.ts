import express from 'express';
import http from 'http';
import path from 'path';
import fs from 'fs';
import { Server } from 'socket.io';
import cors from 'cors';
import { PrismaClient } from '@prisma/client';
import midtransClient from 'midtrans-client';
import multer from 'multer';

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
    cors: { origin: '*', methods: ['GET', 'POST', 'PUT', 'DELETE'] }
});
const prisma = new PrismaClient();

// Midtrans Snap Client (for transaction creation)
const snap = new midtransClient.Snap({
    isProduction: process.env.MIDTRANS_IS_PRODUCTION === 'true',
    serverKey: process.env.MIDTRANS_SERVER_KEY || '',
    clientKey: process.env.MIDTRANS_CLIENT_KEY || '',
});

// Also create Core API client (for status checks and verification)
const coreApi = new midtransClient.CoreApi({
    isProduction: process.env.MIDTRANS_IS_PRODUCTION === 'true',
    serverKey: process.env.MIDTRANS_SERVER_KEY || '',
    clientKey: process.env.MIDTRANS_CLIENT_KEY || '',
});

// Cache Midtrans data for sandbox simulation
const snapCache = new Map<string, { snapToken: string; redirectUrl: string }>();

app.use(cors());
app.use(express.json());

// Static file serving for uploaded banners
const uploadsDir = path.join(__dirname, '..', 'uploads');
if (!fs.existsSync(uploadsDir)) fs.mkdirSync(uploadsDir, { recursive: true });
app.use('/uploads', express.static(uploadsDir));

// Multer config for banner image upload
const bannerStorage = multer.diskStorage({
    destination: (_req, _file, cb) => cb(null, uploadsDir),
    filename: (_req, file, cb) => {
        const ext = path.extname(file.originalname);
        cb(null, `banner_${Date.now()}${ext}`);
    }
});
const uploadBanner = multer({
    storage: bannerStorage,
    limits: { fileSize: 5 * 1024 * 1024 }, // 5MB max
    fileFilter: (_req, file, cb) => {
        const allowed = /\.(jpg|jpeg|png|gif|webp)$/i;
        if (allowed.test(path.extname(file.originalname))) cb(null, true);
        else cb(new Error('Hanya file gambar yang diperbolehkan'));
    }
});

// ==========================================
// SOCKET.IO REALTIME EVENTS
// ==========================================
io.on('connection', (socket) => {
    console.log('✅ Client connected:', socket.id);

    // Customer joins their order room for status updates
    socket.on('join_order', (orderId: string) => {
        socket.join(`order_${orderId}`);
        console.log(`📌 Socket ${socket.id} joined order room: order_${orderId}`);
    });

    // Admin joins admin room to receive all order events
    socket.on('join_admin', () => {
        socket.join('admin_room');
        console.log(`👨‍💼 Admin joined: ${socket.id}`);
    });

    socket.on('disconnect', () => {
        console.log('❌ Client disconnected:', socket.id);
    });
});

// ==========================================
// UTILITY FUNCTIONS
// ==========================================
const generateOrderNumber = async (): Promise<string> => {
    const date = new Date().toISOString().slice(0, 10).replace(/-/g, '');
    const prefix = `ORD-${date}-`;

    // Find the highest order number for today
    const lastOrder = await prisma.order.findFirst({
        where: { orderNumber: { startsWith: prefix } },
        orderBy: { orderNumber: 'desc' },
        select: { orderNumber: true }
    });

    let nextNum = 1;
    if (lastOrder) {
        const lastNum = parseInt(lastOrder.orderNumber.replace(prefix, ''), 10);
        nextNum = (isNaN(lastNum) ? 0 : lastNum) + 1;
    }

    return `${prefix}${String(nextNum).padStart(4, '0')}`;
};

// ==========================================
// API ROUTES — AUTH
// ==========================================
app.post('/api/auth/login', (req, res) => {
    const { username, password } = req.body;
    // Simple hardcoded admin auth
    if (username === 'admin' && password === 'admin123') {
        res.json({ success: true, user: { name: 'Administrator', role: 'ADMIN' } });
    } else {
        res.status(401).json({ success: false, error: 'Username atau password salah' });
    }
});

// ==========================================
// API ROUTES — CATEGORIES
// ==========================================

// GET all categories
app.get('/api/categories', async (_req, res) => {
    try {
        const categories = await prisma.category.findMany({
            where: { isActive: true },
            orderBy: { name: 'asc' }
        });
        res.json(categories);
    } catch (error) {
        console.error('Error fetching categories:', error);
        res.status(500).json({ error: 'Gagal mengambil kategori' });
    }
});

// ==========================================
// API ROUTES — MENUS
// ==========================================

// GET all menus with availability status (for Customer — includes "Habis" items)
app.get('/api/menus', async (_req, res) => {
    try {
        const menus = await prisma.menu.findMany({
            include: { category: true, variants: true },
            orderBy: { createdAt: 'desc' }
        });
        res.json(menus);
    } catch (error) {
        console.error('Error fetching menus:', error);
        res.status(500).json({ error: 'Gagal mengambil menu' });
    }
});

// GET all menus including inactive (for Admin)
app.get('/api/menus/all', async (_req, res) => {
    try {
        const menus = await prisma.menu.findMany({
            include: { category: true, variants: true },
            orderBy: { createdAt: 'desc' }
        });
        res.json(menus);
    } catch (error) {
        console.error('Error fetching all menus:', error);
        res.status(500).json({ error: 'Gagal mengambil semua menu' });
    }
});

// POST create new menu (Admin)
app.post('/api/menus', async (req, res) => {
    const { name, categoryId, price, description, image, hasSpicyLevel, hasTempLevel } = req.body;
    try {
        const menu = await prisma.menu.create({
            data: {
                name,
                categoryId,
                price,
                description: description || '',
                image: image || '',
                hasSpicyLevel: hasSpicyLevel || false,
                hasTempLevel: hasTempLevel || false,
            },
            include: { category: true, variants: true }
        });
        io.to('admin_room').emit('menu:created', menu);
        res.json(menu);
    } catch (error) {
        console.error('Error creating menu:', error);
        res.status(500).json({ error: 'Gagal membuat menu' });
    }
});

// PUT update menu (Admin)
app.put('/api/menus/:id', async (req, res) => {
    const { id } = req.params;
    const { name, categoryId, price, description, image, hasSpicyLevel, hasTempLevel } = req.body;
    try {
        const menu = await prisma.menu.update({
            where: { id },
            data: { name, categoryId, price, description, image, hasSpicyLevel, hasTempLevel },
            include: { category: true, variants: true }
        });
        io.to('admin_room').emit('menu:updated', menu);
        res.json(menu);
    } catch (error) {
        console.error('Error updating menu:', error);
        res.status(500).json({ error: 'Gagal update menu' });
    }
});

// PUT toggle menu active status (Admin)
app.put('/api/menus/:id/toggle', async (req, res) => {
    const { id } = req.params;
    try {
        const current = await prisma.menu.findUnique({ where: { id } });
        if (!current) return res.status(404).json({ error: 'Menu tidak ditemukan' });

        const menu = await prisma.menu.update({
            where: { id },
            data: { isActive: !current.isActive },
            include: { category: true, variants: true }
        });
        // Emit to ALL clients (admin + customers) for realtime stock update
        io.emit('menu:toggled', menu);
        io.to('admin_room').emit('menu:updated', menu);
        console.log(`📦 Menu ${menu.name} → ${menu.isActive ? 'Tersedia' : 'Habis'}`);
        res.json(menu);
    } catch (error) {
        console.error('Error toggling menu:', error);
        res.status(500).json({ error: 'Gagal toggle menu' });
    }
});

// PUT toggle menu favorite (Admin)
app.put('/api/menus/:id/favorite', async (req, res) => {
    const { id } = req.params;
    try {
        const current = await prisma.menu.findUnique({ where: { id } });
        if (!current) return res.status(404).json({ error: 'Menu tidak ditemukan' });

        const menu = await prisma.menu.update({
            where: { id },
            data: { isFavorite: !current.isFavorite },
            include: { category: true, variants: true }
        });
        io.to('admin_room').emit('menu:updated', menu);
        console.log(`⭐ Menu ${menu.name} → ${menu.isFavorite ? 'Favorit' : 'Normal'}`);
        res.json(menu);
    } catch (error) {
        console.error('Error toggling favorite:', error);
        res.status(500).json({ error: 'Gagal toggle favorit' });
    }
});

// DELETE menu (Admin)
app.delete('/api/menus/:id', async (req, res) => {
    const { id } = req.params;
    try {
        await prisma.menu.delete({ where: { id } });
        io.to('admin_room').emit('menu:deleted', { id });
        res.json({ success: true });
    } catch (error) {
        console.error('Error deleting menu:', error);
        res.status(500).json({ error: 'Gagal hapus menu' });
    }
});

// ==========================================
// API ROUTES — ORDERS
// ==========================================

// GET all orders (Admin)
app.get('/api/orders', async (_req, res) => {
    try {
        const orders = await prisma.order.findMany({
            include: {
                items: { include: { menu: true } },
                table: true
            },
            orderBy: { createdAt: 'desc' }
        });
        res.json(orders);
    } catch (error) {
        console.error('Error fetching orders:', error);
        res.status(500).json({ error: 'Gagal mengambil pesanan' });
    }
});

// GET single order (Customer tracking)
app.get('/api/orders/:id', async (req, res) => {
    const { id } = req.params;
    try {
        const order = await prisma.order.findUnique({
            where: { id },
            include: {
                items: { include: { menu: true } },
                table: true
            }
        });
        if (!order) return res.status(404).json({ error: 'Pesanan tidak ditemukan' });
        res.json(order);
    } catch (error) {
        console.error('Error fetching order:', error);
        res.status(500).json({ error: 'Gagal mengambil pesanan' });
    }
});

// POST create order (Customer)
app.post('/api/orders', async (req, res) => {
    const { tableNumber, items, paymentMethod, totalAmount, customerName } = req.body;
    try {
        // Find or create the table
        let table = await prisma.restaurantTable.findUnique({
            where: { number: parseInt(tableNumber) }
        });
        if (!table) {
            table = await prisma.restaurantTable.create({
                data: { number: parseInt(tableNumber) }
            });
        }

        const orderNumber = await generateOrderNumber();

        const newOrder = await prisma.order.create({
            data: {
                orderNumber,
                tableId: table.id,
                customerName: customerName || null,
                paymentMethod,
                totalAmount,
                status: 'WAITING_PAYMENT',
                items: {
                    create: (items || []).map((item: any) => ({
                        menuId: item.menuId,
                        quantity: item.quantity,
                        price: item.price,
                        variantName: item.variantName || null,
                        notes: item.notes || null
                    }))
                }
            },
            include: {
                items: { include: { menu: true } },
                table: true
            }
        });

        // EMIT REALTIME — Admin receives new order
        io.to('admin_room').emit('order:new', newOrder);
        console.log(`🆕 New order: ${orderNumber} from table ${tableNumber}`);

        // If QRIS, create Midtrans Snap token (embedded iframe, not popup)
        let snapToken: string | null = null;
        let snapRedirectUrl: string | null = null;
        if (paymentMethod === 'QRIS') {
            try {
                const parameter = {
                    transaction_details: {
                        order_id: newOrder.id,
                        gross_amount: Math.round(Number(totalAmount)),
                    },
                    customer_details: {
                        first_name: customerName || 'Customer',
                    },
                    item_details: newOrder.items.map((item: any) => ({
                        id: item.menuId,
                        price: Math.round(Number(item.price)),
                        quantity: item.quantity,
                        name: item.menu?.name?.substring(0, 50) || 'Menu Item',
                    })),
                    enabled_payments: ['gopay', 'shopeepay', 'other_qris'],
                };

                const snapResponse = await snap.createTransaction(parameter);
                snapToken = snapResponse.token;
                snapRedirectUrl = snapResponse.redirect_url;
                console.log(`💳 Snap token created for ${orderNumber}: ${snapToken}`);

                // Cache for sandbox simulation
                snapCache.set(newOrder.id, {
                    snapToken: snapToken || '',
                    redirectUrl: snapRedirectUrl || '',
                });
            } catch (midtransError) {
                console.error('Midtrans Snap token creation error:', midtransError);
            }
        }

        const orderResponse: any = JSON.parse(JSON.stringify(newOrder));
        orderResponse.snapToken = snapToken;
        orderResponse.snapRedirectUrl = snapRedirectUrl;
        res.json(orderResponse);
    } catch (error) {
        console.error('Error creating order:', error);
        res.status(500).json({ error: 'Gagal membuat pesanan' });
    }
});

// PUT update order status (Admin)
app.put('/api/orders/:id/status', async (req, res) => {
    const { id } = req.params;
    const { status } = req.body;
    try {
        const updatedOrder = await prisma.order.update({
            where: { id },
            data: { status },
            include: {
                items: { include: { menu: true } },
                table: true
            }
        });

        // EMIT to customer watching this order
        io.to(`order_${id}`).emit('order:statusChanged', updatedOrder);
        // EMIT to all admins
        io.to('admin_room').emit('order:updated', updatedOrder);

        console.log(`📝 Order ${updatedOrder.orderNumber} status → ${status}`);
        res.json(updatedOrder);
    } catch (error) {
        console.error('Error updating order status:', error);
        res.status(500).json({ error: 'Update status gagal' });
    }
});

// ==========================================
// API ROUTES — BANNERS (Promo)
// ==========================================

// GET active banners (Customer — sorted by sortOrder)
app.get('/api/banners', async (_req, res) => {
    try {
        const banners = await prisma.banner.findMany({
            where: { isActive: true },
            orderBy: { sortOrder: 'asc' }
        });
        res.json(banners);
    } catch (error) {
        console.error('Error fetching banners:', error);
        res.status(500).json({ error: 'Gagal mengambil banner' });
    }
});

// GET all banners (Admin — including inactive)
app.get('/api/banners/all', async (_req, res) => {
    try {
        const banners = await prisma.banner.findMany({
            orderBy: { sortOrder: 'asc' }
        });
        res.json(banners);
    } catch (error) {
        console.error('Error fetching all banners:', error);
        res.status(500).json({ error: 'Gagal mengambil semua banner' });
    }
});

// POST create banner with file upload (Admin)
app.post('/api/banners', uploadBanner.single('image'), async (req, res) => {
    const { title, subtitle, sortOrder } = req.body;
    try {
        let imageUrl = req.body.imageUrl || '';
        if (req.file) {
            imageUrl = `/uploads/${req.file.filename}`;
        }
        const banner = await prisma.banner.create({
            data: {
                title: title || '',
                subtitle: subtitle || null,
                imageUrl,
                sortOrder: parseInt(sortOrder) || 0,
            }
        });
        res.json(banner);
    } catch (error) {
        console.error('Error creating banner:', error);
        res.status(500).json({ error: 'Gagal membuat banner' });
    }
});

// PUT update banner (Admin)
app.put('/api/banners/:id', async (req, res) => {
    const { id } = req.params;
    const { title, subtitle, imageUrl, isActive, sortOrder } = req.body;
    try {
        const banner = await prisma.banner.update({
            where: { id },
            data: { title, subtitle, imageUrl, isActive, sortOrder }
        });
        res.json(banner);
    } catch (error) {
        console.error('Error updating banner:', error);
        res.status(500).json({ error: 'Gagal update banner' });
    }
});

// DELETE banner (Admin)
app.delete('/api/banners/:id', async (req, res) => {
    const { id } = req.params;
    try {
        await prisma.banner.delete({ where: { id } });
        res.json({ success: true });
    } catch (error) {
        console.error('Error deleting banner:', error);
        res.status(500).json({ error: 'Gagal hapus banner' });
    }
});

// ==========================================
// API ROUTES — DASHBOARD STATS (Admin)
// ==========================================
app.get('/api/dashboard/stats', async (_req, res) => {
    try {
        const todayStart = new Date();
        todayStart.setHours(0, 0, 0, 0);

        const todayOrders = await prisma.order.findMany({
            where: { createdAt: { gte: todayStart } }
        });

        const totalRevenue = todayOrders
            .filter(o => o.status !== 'CANCELLED' && o.status !== 'WAITING_PAYMENT')
            .reduce((sum, o) => sum + Number(o.totalAmount), 0);

        const completedOrders = todayOrders.filter(o => o.status === 'COMPLETED').length;
        const activeOrders = todayOrders.filter(o =>
            ['PAID', 'PROCESSING', 'READY'].includes(o.status)
        ).length;

        const totalActiveMenus = await prisma.menu.count({ where: { isActive: true } });

        res.json({
            totalRevenue,
            completedOrders,
            activeOrders,
            totalActiveMenus,
            totalOrdersToday: todayOrders.length
        });
    } catch (error) {
        console.error('Error fetching dashboard stats:', error);
        res.status(500).json({ error: 'Gagal mengambil statistik' });
    }
});

// ==========================================
// API ROUTES — EXPORT CSV (Admin)
// ==========================================
app.get('/api/orders/export/csv', async (_req, res) => {
    try {
        const orders = await prisma.order.findMany({
            include: { items: { include: { menu: true } }, table: true },
            orderBy: { createdAt: 'desc' }
        });

        const headers = 'Order ID,Meja,Waktu,Total Tagihan,Status,Metode Bayar\n';
        const rows = orders.map(o =>
            `${o.orderNumber},${o.table?.number || '-'},${o.createdAt.toLocaleString()},${o.totalAmount},${o.status},${o.paymentMethod}`
        ).join('\n');

        res.setHeader('Content-Type', 'text/csv; charset=utf-8');
        res.setHeader('Content-Disposition', `attachment; filename=Laporan_Penjualan_${new Date().toISOString().slice(0, 10)}.csv`);
        res.send(headers + rows);
    } catch (error) {
        console.error('Error exporting CSV:', error);
        res.status(500).json({ error: 'Gagal export CSV' });
    }
});

// ==========================================
// API ROUTES — MIDTRANS
// ==========================================

// GET Midtrans client key (for frontend Snap.js)
app.get('/api/midtrans/client-key', (_req, res) => {
    res.json({ clientKey: process.env.MIDTRANS_CLIENT_KEY || '' });
});

// POST verify payment status (called from frontend after Snap success)
// This checks payment status directly with Midtrans API — works without webhook/ngrok
app.post('/api/payments/verify/:orderId', async (req, res) => {
    const { orderId } = req.params;
    try {
        const order = await prisma.order.findUnique({
            where: { id: orderId },
            include: { items: { include: { menu: true } }, table: true }
        });

        if (!order) {
            return res.status(404).json({ error: 'Order tidak ditemukan' });
        }

        if (order.status !== 'WAITING_PAYMENT') {
            return res.json(order); // Already updated
        }

        // Check payment status with Midtrans API
        let statusResponse;
        try {
            statusResponse = await coreApi.transaction.status(orderId);
        } catch (e: any) {
            console.error('Midtrans status check failed:', e.message);
            return res.status(400).json({ error: 'Gagal verifikasi pembayaran', detail: e.message });
        }

        const txStatus = statusResponse.transaction_status;
        const fraudStatus = statusResponse.fraud_status;
        console.log(`🔍 Verify order ${order.orderNumber}: status=${txStatus}, fraud=${fraudStatus}`);

        let newStatus: string | null = null;
        if (txStatus === 'capture' || txStatus === 'settlement') {
            if (fraudStatus === 'accept' || !fraudStatus) {
                newStatus = 'PAID';
            }
        } else if (txStatus === 'cancel' || txStatus === 'deny' || txStatus === 'expire') {
            newStatus = 'CANCELLED';
        }

        if (newStatus) {
            const updatedOrder = await prisma.order.update({
                where: { id: orderId },
                data: { status: newStatus as any },
                include: { items: { include: { menu: true } }, table: true }
            });

            // Save payment record
            await prisma.payment.upsert({
                where: { orderId: orderId },
                update: {
                    status: txStatus,
                    midtransTrxId: statusResponse.transaction_id || null,
                    paidAt: newStatus === 'PAID' ? new Date() : null,
                },
                create: {
                    orderId: orderId,
                    amount: order.totalAmount,
                    method: order.paymentMethod as any,
                    status: txStatus,
                    midtransTrxId: statusResponse.transaction_id || null,
                    paidAt: newStatus === 'PAID' ? new Date() : null,
                }
            });

            // EMIT realtime updates
            io.to(`order_${orderId}`).emit('order:statusChanged', updatedOrder);
            io.to('admin_room').emit('order:updated', updatedOrder);
            console.log(`✅ Order ${order.orderNumber} → ${newStatus} (verified via API)`);

            return res.json(updatedOrder);
        }

        res.json(order); // No status change
    } catch (error) {
        console.error('Error verifying payment:', error);
        res.status(500).json({ error: 'Gagal verifikasi pembayaran' });
    }
});

// POST simulate payment (SANDBOX ONLY — attempts to trigger Midtrans simulator)
app.post('/api/payments/simulate/:orderId', async (req, res) => {
    if (process.env.MIDTRANS_IS_PRODUCTION === 'true') {
        return res.status(403).json({ error: 'Simulasi tidak tersedia di mode production' });
    }

    const { orderId } = req.params;
    try {
        const order = await prisma.order.findUnique({
            where: { id: orderId },
            include: { items: { include: { menu: true } }, table: true }
        });

        if (!order) return res.status(404).json({ error: 'Order tidak ditemukan' });
        if (order.status !== 'WAITING_PAYMENT') return res.json(order);

        let midtransSimulated = false;

        // Try to simulate via Midtrans Sandbox simulator
        const cached = snapCache.get(orderId);
        if (cached?.redirectUrl) {
            try {
                console.log('🧪 Attempting Midtrans Sandbox simulation...');

                // Step 1: Fetch the Snap redirect page to find the QRIS transaction
                const pageResponse = await fetch(cached.redirectUrl, {
                    redirect: 'follow',
                    headers: { 'Accept': 'text/html,application/xhtml+xml' }
                });
                const html = await pageResponse.text();

                // Step 2: Try to find GoPay simulator deeplink in the page
                const deeplinkMatch = html.match(/simulator\.sandbox\.midtrans\.com[^"'\s]*/i);
                if (deeplinkMatch) {
                    const simulatorUrl = deeplinkMatch[0].startsWith('http') ? deeplinkMatch[0] : `https://${deeplinkMatch[0]}`;
                    console.log(`🧪 Found simulator URL: ${simulatorUrl}`);

                    // Step 3: Fetch the simulator page
                    const simPageRes = await fetch(simulatorUrl, {
                        redirect: 'follow',
                        headers: { 'Accept': 'text/html,application/xhtml+xml' }
                    });
                    const simHtml = await simPageRes.text();

                    // Step 4: Find and submit the payment form
                    const formActionMatch = simHtml.match(/form[^>]*action="([^"]+)"[^>]*/i);
                    if (formActionMatch) {
                        let formAction = formActionMatch[1];
                        if (!formAction.startsWith('http')) {
                            formAction = `https://simulator.sandbox.midtrans.com${formAction}`;
                        }

                        const hiddenFields: Record<string, string> = {};
                        const fieldRegex = /<input[^>]*name=["']([^"']+)["'][^>]*value=["']([^"']*)["'][^>]*\/?>/gi;
                        let fieldMatch;
                        while ((fieldMatch = fieldRegex.exec(simHtml)) !== null) {
                            hiddenFields[fieldMatch[1]] = fieldMatch[2];
                        }
                        const fieldRegex2 = /<input[^>]*value=["']([^"']*)["'][^>]*name=["']([^"']+)["'][^>]*\/?>/gi;
                        while ((fieldMatch = fieldRegex2.exec(simHtml)) !== null) {
                            if (!hiddenFields[fieldMatch[2]]) {
                                hiddenFields[fieldMatch[2]] = fieldMatch[1];
                            }
                        }

                        const formData = new URLSearchParams(hiddenFields);
                        const submitRes = await fetch(formAction, {
                            method: 'POST',
                            headers: {
                                'Content-Type': 'application/x-www-form-urlencoded',
                                'Accept': 'text/html,application/xhtml+xml',
                            },
                            body: formData.toString(),
                            redirect: 'follow',
                        });
                        console.log(`🧪 Simulator form submitted: HTTP ${submitRes.status}`);

                        await new Promise(resolve => setTimeout(resolve, 3000));

                        try {
                            const statusResponse = await coreApi.transaction.status(orderId);
                            if (statusResponse.transaction_status === 'settlement' || statusResponse.transaction_status === 'capture') {
                                midtransSimulated = true;
                                console.log('✅ Midtrans simulation verified — recorded in dashboard!');
                            }
                        } catch (statusErr) {
                            console.log('⚠️ Status check after simulation:', statusErr);
                        }
                    }
                } else {
                    console.log('⚠️ No simulator URL found in Snap redirect page');
                }
            } catch (simError) {
                console.error('⚠️ Midtrans simulator attempt failed:', simError);
            }
        }

        // Update local order status to PAID
        const updatedOrder = await prisma.order.update({
            where: { id: orderId },
            data: { status: 'PAID' },
            include: { items: { include: { menu: true } }, table: true }
        });

        // Save payment record
        await prisma.payment.upsert({
            where: { orderId },
            update: { status: 'settlement', paidAt: new Date() },
            create: {
                orderId,
                amount: order.totalAmount,
                method: order.paymentMethod as any,
                status: 'settlement',
                midtransTrxId: `SIM-${Date.now()}`,
                paidAt: new Date(),
            }
        });

        // EMIT realtime updates
        io.to(`order_${orderId}`).emit('order:statusChanged', updatedOrder);
        io.to('admin_room').emit('order:updated', updatedOrder);
        console.log(`🧪 Payment simulated for ${order.orderNumber} → PAID ${midtransSimulated ? '(Midtrans ✓)' : '(Local)'}`);

        const result: any = JSON.parse(JSON.stringify(updatedOrder));
        result.midtransSimulated = midtransSimulated;
        res.json(result);
    } catch (error) {
        console.error('Error simulating payment:', error);
        res.status(500).json({ error: 'Gagal simulasi pembayaran' });
    }
});

// GET Snap redirect page proxy (for embedding QRIS in iframe)
app.get('/api/payments/snap-redirect/:orderId', async (req, res) => {
    const { orderId } = req.params;
    const cached = snapCache.get(orderId);
    if (!cached?.redirectUrl) {
        return res.status(404).json({ error: 'Snap redirect not found' });
    }
    res.json({ redirectUrl: cached.redirectUrl, snapToken: cached.snapToken });
});

// POST Midtrans webhook notification handler
app.post('/api/payments/notification', async (req, res) => {
    try {
        const notification = req.body;
        console.log(`🔔 Midtrans notification received:`, JSON.stringify(notification, null, 2));

        const orderId = notification.order_id;
        const transactionStatus = notification.transaction_status;
        const fraudStatus = notification.fraud_status;

        // Verify notification authenticity via Midtrans API
        let statusResponse;
        try {
            statusResponse = await coreApi.transaction.status(orderId);
        } catch (e) {
            console.error('Failed to verify transaction status:', e);
            // Use the notification data as fallback
            statusResponse = notification;
        }

        const verifiedStatus = statusResponse.transaction_status;
        const verifiedFraud = statusResponse.fraud_status;

        console.log(`📋 Order ${orderId}: status=${verifiedStatus}, fraud=${verifiedFraud}`);

        // Find the order
        const order = await prisma.order.findUnique({
            where: { id: orderId },
            include: { items: { include: { menu: true } }, table: true }
        });

        if (!order) {
            console.error(`❌ Order not found: ${orderId}`);
            return res.status(404).json({ error: 'Order not found' });
        }

        let newStatus: string | null = null;

        if (verifiedStatus === 'capture' || verifiedStatus === 'settlement') {
            if (verifiedFraud === 'accept' || !verifiedFraud) {
                newStatus = 'PAID';
            }
        } else if (verifiedStatus === 'cancel' || verifiedStatus === 'deny' || verifiedStatus === 'expire') {
            newStatus = 'CANCELLED';
        } else if (verifiedStatus === 'pending') {
            // Still waiting, no status change
            console.log(`⏳ Order ${orderId} still pending`);
        }

        if (newStatus && order.status === 'WAITING_PAYMENT') {
            const updatedOrder = await prisma.order.update({
                where: { id: orderId },
                data: { status: newStatus as any },
                include: { items: { include: { menu: true } }, table: true }
            });

            // Save payment record
            await prisma.payment.upsert({
                where: { orderId: orderId },
                update: {
                    status: verifiedStatus,
                    midtransTrxId: statusResponse.transaction_id || null,
                    paidAt: newStatus === 'PAID' ? new Date() : null,
                },
                create: {
                    orderId: orderId,
                    amount: order.totalAmount,
                    method: order.paymentMethod as any,
                    status: verifiedStatus,
                    midtransTrxId: statusResponse.transaction_id || null,
                    paidAt: newStatus === 'PAID' ? new Date() : null,
                }
            });

            // EMIT realtime updates
            io.to(`order_${orderId}`).emit('order:statusChanged', updatedOrder);
            io.to('admin_room').emit('order:updated', updatedOrder);
            console.log(`✅ Order ${order.orderNumber} → ${newStatus} via Midtrans`);
        }

        // Midtrans expects HTTP 200 response
        res.status(200).json({ status: 'ok' });
    } catch (error) {
        console.error('Error handling Midtrans notification:', error);
        res.status(500).json({ error: 'Notification handling failed' });
    }
});

// ==========================================
// AUTO-CLEANUP: Expire unpaid orders after 5 minutes
// ==========================================
const ORDER_EXPIRY_MINUTES = 5;

const cleanupExpiredOrders = async () => {
    try {
        const expiryTime = new Date(Date.now() - ORDER_EXPIRY_MINUTES * 60 * 1000);

        // Find orders that are WAITING_PAYMENT and older than 5 minutes
        const expiredOrders = await prisma.order.findMany({
            where: {
                status: 'WAITING_PAYMENT',
                createdAt: { lt: expiryTime }
            },
            include: { items: { include: { menu: true } }, table: true }
        });

        for (const order of expiredOrders) {
            // Notify customer that order expired
            io.to(`order_${order.id}`).emit('order:statusChanged', {
                ...JSON.parse(JSON.stringify(order)),
                status: 'EXPIRED'
            });

            // Delete the order (cascade deletes order items too)
            await prisma.order.delete({ where: { id: order.id } });

            // Notify admin to remove from list
            io.to('admin_room').emit('order:expired', { id: order.id, orderNumber: order.orderNumber });

            console.log(`⏰ Order ${order.orderNumber} expired & deleted (unpaid > ${ORDER_EXPIRY_MINUTES} min)`);
        }

        if (expiredOrders.length > 0) {
            console.log(`🧹 Cleaned up ${expiredOrders.length} expired order(s)`);
        }
    } catch (error) {
        console.error('Error cleaning up expired orders:', error);
    }
};

// Run cleanup every 30 seconds
setInterval(cleanupExpiredOrders, 30 * 1000);

// ==========================================
// START SERVER
// ==========================================
const PORT = process.env.PORT || 8000;
server.listen(PORT, '0.0.0.0', () => {
    console.log(`\n🚀 ====================================`);
    console.log(`   Warmindo Backend API`);
    console.log(`   Running on port ${PORT}`);
    console.log(`   API: http://localhost:${PORT}/api`);
    console.log(`   Socket.IO: ws://localhost:${PORT}`);
    console.log(`   Midtrans: ${process.env.MIDTRANS_IS_PRODUCTION === 'true' ? 'PRODUCTION' : 'SANDBOX'}`);
    console.log(`   Order expiry: ${ORDER_EXPIRY_MINUTES} minutes`);
    console.log(`======================================\n`);

    // Run cleanup once on startup
    cleanupExpiredOrders();
});
