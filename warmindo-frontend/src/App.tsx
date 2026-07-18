import React, { useState, useEffect, useCallback, useRef } from 'react';
import {
    Search, ShoppingCart, Plus, Minus, ChevronLeft, Check, Clock, QrCode,
    Utensils, ArrowRight, X, DollarSign, Trash2, Loader2, Wifi, WifiOff,
    ChevronRight
} from 'lucide-react';
import { io, Socket } from 'socket.io-client';



// ==========================================
// CUSTOMER PORTAL — WARMINDO BAROKAH
// ==========================================
// Mobile-first ordering web app for customers.
// Connects to Backend API (port 8000) via Vite proxy.

// --- TYPES ---
type MenuCategory = 'Semua' | 'Makanan' | 'Minuman' | 'Cemilan';
type OrderStatus = 'WAITING_PAYMENT' | 'PAID' | 'PROCESSING' | 'READY' | 'COMPLETED' | 'CANCELLED' | 'EXPIRED';
type PaymentMethod = 'CASH' | 'QRIS';

interface Category {
    id: string;
    name: string;
}

interface Menu {
    id: string;
    name: string;
    category: Category;
    categoryId: string;
    price: number;
    image: string;
    description: string;
    hasSpicyLevel?: boolean;
    hasTempLevel?: boolean;
    isActive: boolean;
    isFavorite?: boolean;
}

interface CartItem {
    cartId: string;
    menuId: string;
    name: string;
    price: number;
    image: string;
    quantity: number;
    variantName?: string;
    notes?: string;
}

interface OrderItem {
    id: string;
    menuId: string;
    quantity: number;
    price: number;
    variantName?: string;
    notes?: string;
    menu: Menu;
}

interface Order {
    id: string;
    orderNumber: string;
    tableId: string;
    table?: { number: number };
    customerName?: string;
    items: OrderItem[];
    totalAmount: number;
    status: OrderStatus;
    paymentMethod: PaymentMethod;
    createdAt: string;
}

interface Banner {
    id: string;
    title: string;
    subtitle?: string;
    imageUrl: string;
    isActive: boolean;
    sortOrder: number;
}

// --- UTILS ---
const formatRp = (value: number) => {
    return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(value);
};

const API_BASE = '/api';

// --- SOCKET CONNECTION ---
let socket: Socket | null = null;
const getSocket = (): Socket => {
    if (!socket) {
        socket = io(window.location.origin, {
            transports: ['websocket', 'polling'],
            reconnection: true,
            reconnectionDelay: 1000,
        });
    }
    return socket;
};

// ==========================================
// MAIN APPLICATION ROOT
// ==========================================
export default function App() {
    const [currentView, setCurrentView] = useState<'LANDING' | 'CUSTOMER'>('LANDING');
    const [tableNumber, setTableNumber] = useState<string>('');

    if (currentView === 'LANDING') {
        return (
            <LandingPage
                onEnterCustomer={(table) => {
                    setTableNumber(table);
                    setCurrentView('CUSTOMER');
                }}
            />
        );
    }

    return (
        <CustomerPortal
            tableNumber={tableNumber}
            onBackToHome={() => setCurrentView('LANDING')}
        />
    );
}

// ==========================================
// 1. LANDING PAGE (Mobile-First)
// ==========================================
function LandingPage({ onEnterCustomer }: { onEnterCustomer: (t: string) => void }) {
    const [table, setTable] = useState('');
    const [isAnimating, setIsAnimating] = useState(false);

    useEffect(() => {
        setIsAnimating(true);
    }, []);

    return (
        <div className="min-h-screen min-h-[100dvh] bg-warmindo-gradient-soft flex flex-col items-center justify-center p-4 font-sans text-warmindo-brown">
            <div className={`w-full max-w-sm bg-white rounded-3xl shadow-2xl shadow-orange-900/15 overflow-hidden transition-all duration-700 ${isAnimating ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-8'}`}>
                {/* Hero Header */}
                <div className="bg-warmindo-hero p-8 text-center relative overflow-hidden">
                    <div className="absolute top-0 right-0 w-32 h-32 bg-white/10 rounded-full -translate-y-1/2 translate-x-1/2"></div>
                    <div className="absolute bottom-0 left-0 w-24 h-24 bg-white/10 rounded-full translate-y-1/2 -translate-x-1/2"></div>
                    <div className="absolute top-3 left-5 text-white/20 text-2xl animate-wiggle">🍜</div>
                    <div className="absolute bottom-4 right-6 text-white/15 text-xl">🥢</div>
                    <div className="w-24 h-24 bg-white rounded-2xl flex items-center justify-center mx-auto mb-4 shadow-lg shadow-orange-900/30 rotate-3 hover:rotate-0 transition-transform pulse-warmindo overflow-hidden">
                        <img src="/logo.png" alt="Warmindo Barokah" className="w-full h-full object-cover" />
                    </div>
                    <h1 className="text-2xl font-display font-extrabold text-white tracking-wide drop-shadow-sm">WARMINDO BAROKAH</h1>
                    <p className="text-orange-100/90 text-sm mt-1.5 font-medium tracking-wider">Enak • Nikmat • Barokah</p>
                </div>

                <div className="p-6 space-y-6">
                    <div className="space-y-4">
                        <h2 className="text-base font-bold text-warmindo-brown text-center flex items-center justify-center gap-2">
                            <QrCode className="w-5 h-5 text-orange-500" />
                            Masukkan Nomor Meja
                        </h2>
                        <input
                            type="number"
                            inputMode="numeric"
                            placeholder="Contoh: 12"
                            className="w-full px-4 py-4 rounded-2xl border-2 border-warmindo-100 focus:border-orange-500 focus:ring-4 focus:ring-orange-500/10 outline-none transition-all text-center text-2xl font-bold text-warmindo-brown placeholder:text-warmindo-200 placeholder:text-lg placeholder:font-normal"
                            value={table}
                            onChange={(e) => setTable(e.target.value)}
                            onKeyDown={(e) => e.key === 'Enter' && table && onEnterCustomer(table)}
                        />
                        <button
                            onClick={() => table && onEnterCustomer(table)}
                            disabled={!table}
                            className="w-full bg-gradient-to-r from-orange-500 to-amber-500 hover:from-orange-600 hover:to-amber-600 text-white font-bold py-4 rounded-2xl transition-all disabled:opacity-40 disabled:cursor-not-allowed flex items-center justify-center gap-2 text-base shadow-lg shadow-orange-500/25 active:scale-[0.98]"
                        >
                            Mulai Pesan <ArrowRight className="w-5 h-5" />
                        </button>
                    </div>
                </div>
            </div>
            <p className="text-xs text-warmindo-300 mt-6">© 2026 Warmindo Barokah — Digital Order</p>
        </div>
    );
}

// ==========================================
// 2. BANNER CAROUSEL (Image-only)
// ==========================================
function BannerCarousel({ banners }: { banners: Banner[] }) {
    const [activeIndex, setActiveIndex] = useState(0);
    const scrollRef = useRef<HTMLDivElement>(null);
    const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);

    // Auto-slide
    useEffect(() => {
        if (banners.length <= 1) return;
        timerRef.current = setInterval(() => {
            setActiveIndex(prev => {
                const next = (prev + 1) % banners.length;
                scrollRef.current?.children[next]?.scrollIntoView({ behavior: 'smooth', block: 'nearest', inline: 'start' });
                return next;
            });
        }, 4000);
        return () => { if (timerRef.current) clearInterval(timerRef.current); };
    }, [banners.length]);

    // Track scroll position for dots
    const handleScroll = () => {
        if (!scrollRef.current) return;
        const scrollLeft = scrollRef.current.scrollLeft;
        const width = scrollRef.current.offsetWidth;
        const newIndex = Math.round(scrollLeft / width);
        if (newIndex !== activeIndex && newIndex >= 0 && newIndex < banners.length) {
            setActiveIndex(newIndex);
            // Reset timer on manual scroll
            if (timerRef.current) clearInterval(timerRef.current);
            timerRef.current = setInterval(() => {
                setActiveIndex(prev => {
                    const next = (prev + 1) % banners.length;
                    scrollRef.current?.children[next]?.scrollIntoView({ behavior: 'smooth', block: 'nearest', inline: 'start' });
                    return next;
                });
            }, 4000);
        }
    };

    if (banners.length === 0) return null;

    return (
        <div className="relative animate-float-up">
            {/* Carousel */}
            <div
                ref={scrollRef}
                onScroll={handleScroll}
                className="flex overflow-x-auto snap-x scrollbar-hide gap-0 rounded-2xl"
                style={{ scrollBehavior: 'smooth' }}
            >
                {banners.map((banner, idx) => (
                    <div
                        key={banner.id}
                        className="w-full flex-shrink-0 snap-start"
                    >
                        <div className="relative h-40 rounded-2xl overflow-hidden mx-0">
                            <img
                                src={banner.imageUrl}
                                alt={banner.title}
                                className="w-full h-full object-cover"
                                loading={idx === 0 ? 'eager' : 'lazy'}
                            />
                            {/* Gradient overlay with text */}
                            <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-black/20 to-transparent"></div>
                            <div className="absolute bottom-0 left-0 right-0 p-4">
                                <h3 className="text-white font-display font-bold text-base drop-shadow-md">{banner.title}</h3>
                                {banner.subtitle && (
                                    <p className="text-white/80 text-xs mt-0.5 drop-shadow-md">{banner.subtitle}</p>
                                )}
                            </div>
                        </div>
                    </div>
                ))}
            </div>

            {/* Dots indicator */}
            {banners.length > 1 && (
                <div className="flex justify-center gap-1.5 mt-3">
                    {banners.map((_, idx) => (
                        <button
                            key={idx}
                            onClick={() => {
                                setActiveIndex(idx);
                                scrollRef.current?.children[idx]?.scrollIntoView({ behavior: 'smooth', block: 'nearest', inline: 'start' });
                            }}
                            className={`rounded-full transition-all duration-300 ${idx === activeIndex
                                ? 'w-6 h-2 bg-orange-500'
                                : 'w-2 h-2 bg-warmindo-200 hover:bg-warmindo-300'
                                }`}
                        />
                    ))}
                </div>
            )}
        </div>
    );
}

// ==========================================
// 3. CUSTOMER PORTAL
// ==========================================
function CustomerPortal({ tableNumber, onBackToHome }: { tableNumber: string; onBackToHome: () => void }) {
    const [view, setView] = useState<'HOME' | 'FULL_MENU' | 'CART' | 'TRACKER'>('HOME');
    const [menus, setMenus] = useState<Menu[]>([]);
    const [banners, setBanners] = useState<Banner[]>([]);
    const [cart, setCart] = useState<CartItem[]>([]);
    const [search, setSearch] = useState('');
    const [activeCategory, setActiveCategory] = useState<MenuCategory>('Semua');
    const [selectedMenu, setSelectedMenu] = useState<Menu | null>(null);
    const [activeOrder, setActiveOrder] = useState<Order | null>(null);
    const [loading, setLoading] = useState(true);
    const [isConnected, setIsConnected] = useState(false);
    const [orderLoading, setOrderLoading] = useState(false);
    const [initialCategory, setInitialCategory] = useState<MenuCategory>('Semua');

    // Fetch menus from API
    useEffect(() => {
        const fetchMenus = async () => {
            try {
                const res = await fetch(`${API_BASE}/menus`);
                const data = await res.json();
                setMenus(data);
            } catch (err) {
                console.error('Failed to fetch menus:', err);
            } finally {
                setLoading(false);
            }
        };
        fetchMenus();
    }, []);

    // Fetch banners from API
    useEffect(() => {
        const fetchBanners = async () => {
            try {
                const res = await fetch(`${API_BASE}/banners`);
                const data = await res.json();
                setBanners(data);
            } catch (err) {
                console.error('Failed to fetch banners:', err);
            }
        };
        fetchBanners();
    }, []);

    // Socket.IO connection for real-time order tracking + menu stock
    useEffect(() => {
        const s = getSocket();

        s.on('connect', () => {
            setIsConnected(true);
            console.log('🔌 Socket connected');
        });
        s.on('disconnect', () => {
            setIsConnected(false);
            console.log('🔌 Socket disconnected');
        });

        // Listen for menu stock changes (realtime)
        s.on('menu:toggled', (updatedMenu: Menu) => {
            console.log(`📦 Menu ${updatedMenu.name} → ${updatedMenu.isActive ? 'Tersedia' : 'Habis'}`);
            setMenus(prev => prev.map(m => m.id === updatedMenu.id ? { ...m, isActive: updatedMenu.isActive } : m));
        });

        return () => {
            s.off('connect');
            s.off('disconnect');
            s.off('menu:toggled');
        };
    }, []);

    // Listen for order status changes
    useEffect(() => {
        if (!activeOrder) return;

        const s = getSocket();
        s.emit('join_order', activeOrder.id);

        const handleStatusChange = (updatedOrder: Order) => {
            console.log('📡 Order status updated:', updatedOrder.status);
            setActiveOrder(updatedOrder);
        };

        s.on('order:statusChanged', handleStatusChange);

        return () => {
            s.off('order:statusChanged', handleStatusChange);
        };
    }, [activeOrder?.id]);

    // Cart Handlers
    const addToCart = (item: CartItem) => {
        setCart([...cart, item]);
        setSelectedMenu(null);
    };
    const updateCartQty = (cartId: string, delta: number) => {
        setCart(prev => prev.map(item => {
            if (item.cartId === cartId) {
                const newQty = item.quantity + delta;
                return newQty > 0 ? { ...item, quantity: newQty } : item;
            }
            return item;
        }));
    };
    const removeFromCart = (cartId: string) => setCart(prev => prev.filter(item => item.cartId !== cartId));
    const cartTotal = cart.reduce((sum, item) => sum + (item.price * item.quantity), 0);

    // Filter Menus
    const filteredMenus = menus.filter((m: Menu) =>
        m.isActive &&
        (activeCategory === 'Semua' || m.category?.name === activeCategory) &&
        m.name.toLowerCase().includes(search.toLowerCase())
    );

    // Favorite menus (first 6 active menus)
    // Favorite menus (admin-controlled via isFavorite flag, fallback to first 6)
    const markedFavorites = menus.filter(m => m.isActive && m.isFavorite);
    const favoriteMenus = markedFavorites.length > 0 ? markedFavorites : menus.filter(m => m.isActive).slice(0, 6);

    // Navigate to full menu with optional category preset
    const goToFullMenu = (category?: MenuCategory) => {
        if (category) {
            setActiveCategory(category);
            setInitialCategory(category);
        } else {
            setActiveCategory('Semua');
        }
        setSearch('');
        setView('FULL_MENU');
    };

    // Checkout — POST to API, then open Midtrans Snap for QRIS
    const handleCheckout = async (paymentMethod: PaymentMethod, customerName: string) => {
        setOrderLoading(true);
        try {
            const res = await fetch(`${API_BASE}/orders`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    tableNumber,
                    paymentMethod,
                    totalAmount: cartTotal,
                    customerName,
                    items: cart.map(item => ({
                        menuId: item.menuId,
                        quantity: item.quantity,
                        price: item.price,
                        variantName: item.variantName || null,
                        notes: item.notes || null,
                    }))
                })
            });
            const order = await res.json();
            setActiveOrder(order);
            setCart([]);
            setView('TRACKER');


        } catch (err) {
            console.error('Checkout failed:', err);
            alert('Gagal memproses pesanan. Coba lagi.');
        } finally {
            setOrderLoading(false);
        }
    };

    // Category icons for visual flair
    const categoryIcons: Record<string, string> = {
        'Semua': '🍽️',
        'Makanan': '🍜',
        'Minuman': '🥤',
        'Cemilan': '🍢'
    };

    return (
        <div className="min-h-screen min-h-[100dvh] bg-warmindo-50 font-sans text-warmindo-brown pb-28">
            {/* Header */}
            <header className="bg-white border-b border-warmindo-100 sticky top-0 z-30 px-4 py-3 shadow-sm shadow-orange-100/50">
                <div className="max-w-lg mx-auto flex items-center justify-between">
                    <div className="flex items-center gap-3">
                        {view === 'FULL_MENU' ? (
                            <button onClick={() => setView('HOME')} className="text-warmindo-300 hover:text-warmindo-600 active:scale-90 transition-all p-1 -ml-1">
                                <ChevronLeft className="w-6 h-6" />
                            </button>
                        ) : (
                            <button onClick={onBackToHome} className="text-warmindo-300 hover:text-warmindo-600 active:scale-90 transition-all p-1 -ml-1">
                                <ChevronLeft className="w-6 h-6" />
                            </button>
                        )}
                        <div>
                            <h1 className="font-display font-extrabold text-lg text-warmindo-brown leading-tight">
                                {view === 'FULL_MENU' ? 'Menu' : 'Warmindo Barokah'}
                            </h1>
                            <p className="text-[11px] text-orange-600 font-semibold flex items-center gap-1">
                                <span className="w-1.5 h-1.5 bg-orange-500 rounded-full inline-block animate-pulse"></span>
                                Meja {tableNumber}
                            </p>
                        </div>
                    </div>
                    <div className="flex items-center gap-2">
                        {isConnected ?
                            <Wifi className="w-4 h-4 text-green-500" /> :
                            <WifiOff className="w-4 h-4 text-red-400" />
                        }
                        {view === 'TRACKER' && (
                            <button onClick={() => setView('HOME')} className="text-sm font-bold text-orange-600 bg-orange-50 px-3 py-1.5 rounded-xl active:scale-95 transition-all border border-orange-100">
                                Pesan Lagi
                            </button>
                        )}
                    </div>
                </div>
            </header>

            {/* Main Content Area */}
            <main className="max-w-lg mx-auto w-full">
                {/* ========== HOME VIEW ========== */}
                {view === 'HOME' && (
                    <div className="p-4 space-y-5 animate-in">
                        {/* Search */}
                        <div className="relative">
                            <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 text-warmindo-300 w-5 h-5" />
                            <input
                                type="text"
                                placeholder="Cari nasi, mie, minuman..."
                                className="w-full bg-white border border-warmindo-100 rounded-2xl py-3.5 pl-11 pr-4 outline-none focus:ring-2 focus:ring-orange-500/20 focus:border-orange-400 shadow-sm text-sm transition-all"
                                value={search}
                                onChange={e => setSearch(e.target.value)}
                                onFocus={() => goToFullMenu()}
                            />
                        </div>

                        {/* Banner Carousel */}
                        {banners.length > 0 && (
                            <BannerCarousel banners={banners} />
                        )}

                        {/* Kategori Section */}
                        <div>
                            <div className="flex items-center justify-between mb-3">
                                <h2 className="font-display font-bold text-base text-warmindo-brown">Kategori</h2>
                                <button
                                    onClick={() => goToFullMenu()}
                                    className="text-xs font-semibold text-orange-600 flex items-center gap-0.5 active:scale-95 transition-all"
                                >
                                    Lihat Semua <ChevronRight className="w-3.5 h-3.5" />
                                </button>
                            </div>
                            <div className="grid grid-cols-4 gap-3">
                                {(['Semua', 'Makanan', 'Minuman', 'Cemilan'] as MenuCategory[]).map(cat => (
                                    <button
                                        key={cat}
                                        onClick={() => goToFullMenu(cat)}
                                        className="flex flex-col items-center gap-2 p-3 rounded-2xl bg-white border border-warmindo-100/80 hover:bg-warmindo-50 hover:border-warmindo-200 active:scale-95 transition-all shadow-sm"
                                    >
                                        <div className="w-11 h-11 rounded-xl bg-gradient-to-br from-orange-50 to-amber-50 flex items-center justify-center text-2xl">
                                            {categoryIcons[cat]}
                                        </div>
                                        <span className="text-xs font-semibold text-warmindo-brown/80">{cat}</span>
                                    </button>
                                ))}
                            </div>
                        </div>

                        {/* Menu Favorit Section */}
                        <div>
                            <div className="flex items-center justify-between mb-3">
                                <h2 className="font-display font-bold text-base text-warmindo-brown">Menu Favorit</h2>
                                <button
                                    onClick={() => goToFullMenu()}
                                    className="text-xs font-semibold text-orange-600 flex items-center gap-0.5 active:scale-95 transition-all"
                                >
                                    Lihat Semua <ChevronRight className="w-3.5 h-3.5" />
                                </button>
                            </div>

                            {loading ? (
                                <div className="flex items-center justify-center py-12">
                                    <Loader2 className="w-6 h-6 text-orange-500 animate-spin" />
                                </div>
                            ) : (
                                <div className="flex gap-3 overflow-x-auto scrollbar-hide -mx-4 px-4 pb-2">
                                    {favoriteMenus.map((menu, index) => (
                                        <div
                                            key={menu.id}
                                            onClick={() => setSelectedMenu(menu)}
                                            className="flex-shrink-0 w-36 bg-white rounded-2xl shadow-sm border border-warmindo-100/80 overflow-hidden cursor-pointer hover:shadow-lg hover:shadow-orange-500/10 hover:-translate-y-0.5 active:scale-[0.98] transition-all animate-float-up"
                                            style={{ animationDelay: `${index * 60}ms` }}
                                        >
                                            <div className="h-24 bg-warmindo-50 relative overflow-hidden">
                                                <img src={menu.image} alt={menu.name} className="w-full h-full object-cover" loading="lazy" />
                                                {index < 2 && (
                                                    <span className="absolute top-2 left-2 bg-warmindo-red text-white text-[9px] font-bold px-2 py-0.5 rounded-full shadow-sm">
                                                        Best Seller
                                                    </span>
                                                )}
                                            </div>
                                            <div className="p-2.5">
                                                <h3 className="font-bold text-xs line-clamp-2 leading-tight text-warmindo-brown">{menu.name}</h3>
                                                <p className="font-extrabold text-orange-600 text-xs mt-1.5">{formatRp(Number(menu.price))}</p>
                                            </div>
                                        </div>
                                    ))}
                                </div>
                            )}
                        </div>
                    </div>
                )}

                {/* ========== FULL MENU VIEW (List Layout) ========== */}
                {view === 'FULL_MENU' && (
                    <div className="p-4 space-y-4 animate-in">
                        {/* Search */}
                        <div className="relative">
                            <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 text-warmindo-300 w-5 h-5" />
                            <input
                                type="text"
                                placeholder="Cari menu favorit..."
                                className="w-full bg-white border border-warmindo-100 rounded-2xl py-3.5 pl-11 pr-4 outline-none focus:ring-2 focus:ring-orange-500/20 focus:border-orange-400 shadow-sm text-sm transition-all"
                                value={search} onChange={e => setSearch(e.target.value)}
                                autoFocus
                            />
                        </div>

                        {/* Category Filter */}
                        <div className="flex gap-2 overflow-x-auto pb-1 scrollbar-hide -mx-4 px-4">
                            {['Semua', 'Makanan', 'Minuman', 'Cemilan'].map(cat => (
                                <button
                                    key={cat}
                                    onClick={() => setActiveCategory(cat as MenuCategory)}
                                    className={`whitespace-nowrap px-5 py-2.5 rounded-xl text-sm font-semibold transition-all active:scale-95 flex items-center gap-1.5 ${activeCategory === cat
                                        ? 'bg-gradient-to-r from-orange-500 to-amber-500 text-white shadow-md shadow-orange-500/25'
                                        : 'bg-white text-warmindo-brown/70 border border-warmindo-100 hover:bg-warmindo-50 hover:border-warmindo-200'
                                        }`}
                                >
                                    <span className="text-base">{categoryIcons[cat]}</span>
                                    {cat}
                                </button>
                            ))}
                        </div>

                        {/* Loading State */}
                        {loading && (
                            <div className="flex flex-col items-center justify-center py-16 gap-3">
                                <div className="w-12 h-12 rounded-full bg-gradient-to-r from-orange-500 to-amber-500 flex items-center justify-center animate-bounce-in">
                                    <Loader2 className="w-6 h-6 text-white animate-spin" />
                                </div>
                                <p className="text-warmindo-300 text-sm font-medium">Memuat menu...</p>
                            </div>
                        )}

                        {/* Menu List (Vertical List Layout) */}
                        {!loading && (
                            <div className="space-y-3">
                                {filteredMenus.map((menu: Menu, index: number) => (
                                    <div
                                        key={menu.id}
                                        onClick={() => menu.isActive && setSelectedMenu(menu)}
                                        className={`bg-white rounded-2xl shadow-sm border border-warmindo-100/80 overflow-hidden flex transition-all animate-float-up ${menu.isActive
                                            ? 'cursor-pointer hover:shadow-lg hover:shadow-orange-500/10 active:scale-[0.99]'
                                            : 'opacity-60 grayscale cursor-not-allowed'
                                            }`}
                                        style={{ animationDelay: `${index * 40}ms` }}
                                    >
                                        {/* Image */}
                                        <div className="w-28 h-28 bg-warmindo-50 relative overflow-hidden flex-shrink-0">
                                            <img src={menu.image} alt={menu.name} className="w-full h-full object-cover" loading="lazy" />
                                            {!menu.isActive && (
                                                <div className="absolute inset-0 bg-warmindo-brown/50 flex items-center justify-center backdrop-blur-[1px]">
                                                    <span className="bg-warmindo-red text-white text-[9px] font-extrabold px-2 py-1 rounded-full shadow-lg tracking-wide">
                                                        HABIS
                                                    </span>
                                                </div>
                                            )}
                                            {index < 3 && menu.isActive && (
                                                <span className="absolute top-2 left-2 bg-warmindo-red text-white text-[8px] font-bold px-1.5 py-0.5 rounded-full shadow-sm">
                                                    Best Seller
                                                </span>
                                            )}
                                        </div>

                                        {/* Info */}
                                        <div className="flex-grow p-3 flex flex-col justify-between min-w-0">
                                            <div>
                                                <h3 className="font-bold text-sm leading-tight text-warmindo-brown line-clamp-2">{menu.name}</h3>
                                                {menu.description && (
                                                    <p className="text-warmindo-brown/50 text-xs mt-1 line-clamp-2 leading-relaxed">{menu.description}</p>
                                                )}
                                            </div>
                                            <div className="flex items-center justify-between mt-2">
                                                <p className={`font-extrabold text-sm ${menu.isActive ? 'text-orange-600' : 'text-warmindo-300'}`}>
                                                    {formatRp(Number(menu.price))}
                                                </p>
                                                {menu.isActive && (
                                                    <div className="bg-gradient-to-r from-orange-500 to-amber-500 text-white p-1.5 rounded-lg shadow-sm shadow-orange-500/20">
                                                        <Plus className="w-3.5 h-3.5" />
                                                    </div>
                                                )}
                                            </div>
                                        </div>
                                    </div>
                                ))}
                            </div>
                        )}

                        {!loading && filteredMenus.length === 0 && (
                            <div className="text-center py-12 text-warmindo-300">
                                <div className="text-5xl mb-3 opacity-30">🍜</div>
                                <p className="font-medium">Menu tidak ditemukan</p>
                                <p className="text-sm mt-1 opacity-70">Coba kata kunci lain</p>
                            </div>
                        )}
                    </div>
                )}

                {view === 'CART' && (
                    <CartPage
                        cart={cart}
                        total={cartTotal}
                        onUpdate={updateCartQty}
                        onRemove={removeFromCart}
                        onBack={() => setView('FULL_MENU')}
                        onCheckout={handleCheckout}
                        isLoading={orderLoading}
                    />
                )}

                {view === 'TRACKER' && activeOrder && (
                    <OrderTracker order={activeOrder} tableNumber={tableNumber} onOrderUpdate={setActiveOrder} />
                )}
            </main>

            {/* Floating Cart Button */}
            {(view === 'HOME' || view === 'FULL_MENU') && cart.length > 0 && (
                <div className="fixed bottom-0 left-0 right-0 p-4 pb-5 z-40 bg-gradient-to-t from-warmindo-50 via-warmindo-50/95 to-transparent pt-8">
                    <div className="max-w-lg mx-auto">
                        <button
                            onClick={() => setView('CART')}
                            className="w-full bg-gradient-to-r from-orange-500 to-amber-500 text-white rounded-2xl p-4 shadow-xl shadow-orange-500/25 flex items-center justify-between active:scale-[0.98] transition-all hover:shadow-2xl hover:shadow-orange-500/30"
                        >
                            <div className="flex items-center gap-3">
                                <div className="bg-white/20 p-2 rounded-xl relative">
                                    <ShoppingCart className="w-5 h-5" />
                                    <span className="absolute -top-1.5 -right-1.5 bg-warmindo-red text-white text-[10px] font-bold w-5 h-5 rounded-full flex items-center justify-center shadow-sm animate-bounce-in">
                                        {cart.reduce((a, b) => a + b.quantity, 0)}
                                    </span>
                                </div>
                                <span className="font-bold">{cart.length} item</span>
                            </div>
                            <div className="flex items-center gap-2">
                                <span className="font-extrabold text-base">{formatRp(cartTotal)}</span>
                                <ChevronLeft className="w-5 h-5 rotate-180 opacity-70" />
                            </div>
                        </button>
                    </div>
                </div>
            )}

            {/* Menu Detail Modal */}
            {selectedMenu && (
                <MenuDetailModal
                    menu={selectedMenu}
                    onClose={() => setSelectedMenu(null)}
                    onAdd={addToCart}
                />
            )}
        </div>
    );
}

// --- Menu Detail Modal Component ---
function MenuDetailModal({ menu, onClose, onAdd }: { menu: Menu; onClose: () => void; onAdd: (item: CartItem) => void }) {
    const [qty, setQty] = useState(1);
    const [variant, setVariant] = useState(menu.hasSpicyLevel ? 'Sedang' : menu.hasTempLevel ? 'Dingin' : '');
    const [notes, setNotes] = useState('');

    return (
        <div className="fixed inset-0 z-50 flex items-end justify-center bg-warmindo-brown/50 backdrop-blur-sm animate-in" onClick={onClose}>
            <div className="bg-white w-full max-w-lg rounded-t-3xl overflow-hidden flex flex-col max-h-[85vh] animate-slide-up" onClick={e => e.stopPropagation()}>
                {/* Image */}
                <div className="relative h-44 bg-warmindo-50 shrink-0">
                    <img src={menu.image} alt={menu.name} className="w-full h-full object-cover" />
                    <div className="absolute inset-0 bg-gradient-to-t from-black/30 to-transparent"></div>
                    <button onClick={onClose} className="absolute top-3 right-3 bg-white/80 backdrop-blur-md p-2 rounded-full text-warmindo-brown active:scale-90 transition-all">
                        <X className="w-5 h-5" />
                    </button>
                </div>

                {/* Content */}
                <div className="p-5 overflow-y-auto flex-grow scrollbar-hide">
                    <h2 className="text-xl font-display font-extrabold text-warmindo-brown">{menu.name}</h2>
                    <p className="text-orange-600 font-extrabold text-lg mt-1">{formatRp(Number(menu.price))}</p>
                    <p className="text-warmindo-brown/60 text-sm mt-3 leading-relaxed">{menu.description}</p>

                    <div className="my-5 h-px bg-warmindo-100"></div>

                    {/* Spicy Level */}
                    {menu.hasSpicyLevel && (
                        <div className="mb-5">
                            <h4 className="font-bold text-sm mb-3 text-warmindo-brown">🌶️ Level Pedas</h4>
                            <div className="flex gap-2">
                                {['Tidak Pedas', 'Sedang', 'Pedas'].map(v => (
                                    <button
                                        key={v}
                                        onClick={() => setVariant(v)}
                                        className={`flex-1 py-2.5 text-sm rounded-xl border-2 font-semibold transition-all active:scale-95 ${variant === v ? 'bg-gradient-to-r from-orange-500 to-amber-500 border-orange-500 text-white shadow-md shadow-orange-500/20' : 'bg-white border-warmindo-100 text-warmindo-brown/70'}`}
                                    >
                                        {v}
                                    </button>
                                ))}
                            </div>
                        </div>
                    )}

                    {/* Temperature */}
                    {menu.hasTempLevel && (
                        <div className="mb-5">
                            <h4 className="font-bold text-sm mb-3 text-warmindo-brown">🧊 Penyajian</h4>
                            <div className="flex gap-2">
                                {['Panas', 'Dingin'].map(v => (
                                    <button
                                        key={v}
                                        onClick={() => setVariant(v)}
                                        className={`flex-1 py-2.5 text-sm rounded-xl border-2 font-semibold transition-all active:scale-95 ${variant === v ? 'bg-gradient-to-r from-orange-500 to-amber-500 border-orange-500 text-white shadow-md shadow-orange-500/20' : 'bg-white border-warmindo-100 text-warmindo-brown/70'}`}
                                    >
                                        {v}
                                    </button>
                                ))}
                            </div>
                        </div>
                    )}

                    {/* Notes */}
                    <div className="mb-5">
                        <h4 className="font-bold text-sm mb-3 text-warmindo-brown">📝 Catatan (Opsional)</h4>
                        <input
                            type="text"
                            placeholder="Contoh: Jangan pakai bawang..."
                            className="w-full p-3.5 rounded-xl border-2 border-warmindo-100 focus:border-orange-500 focus:ring-2 focus:ring-orange-500/10 outline-none text-sm transition-colors"
                            value={notes}
                            onChange={e => setNotes(e.target.value)}
                        />
                    </div>

                    {/* Quantity */}
                    <div className="flex items-center justify-between">
                        <h4 className="font-bold text-sm text-warmindo-brown">Jumlah</h4>
                        <div className="flex items-center gap-4 bg-warmindo-50 rounded-full p-1.5">
                            <button onClick={() => qty > 1 && setQty(qty - 1)} className="bg-white p-2 rounded-full shadow-sm text-warmindo-brown/60 active:scale-90 transition-all">
                                <Minus className="w-4 h-4" />
                            </button>
                            <span className="font-extrabold text-lg w-6 text-center text-warmindo-brown">{qty}</span>
                            <button onClick={() => setQty(qty + 1)} className="bg-white p-2 rounded-full shadow-sm text-orange-600 active:scale-90 transition-all">
                                <Plus className="w-4 h-4" />
                            </button>
                        </div>
                    </div>
                </div>

                {/* Add Button */}
                <div className="p-4 bg-white border-t border-warmindo-100 shrink-0">
                    {menu.isActive ? (
                        <button
                            onClick={() => onAdd({
                                cartId: Math.random().toString(36).substr(2, 9),
                                menuId: menu.id,
                                name: menu.name,
                                price: Number(menu.price),
                                image: menu.image,
                                quantity: qty,
                                variantName: variant,
                                notes
                            })}
                            className="w-full bg-gradient-to-r from-orange-500 to-amber-500 text-white py-4 rounded-2xl font-bold flex justify-between items-center px-5 shadow-lg shadow-orange-500/25 active:scale-[0.98] transition-all hover:from-orange-600 hover:to-amber-600"
                        >
                            <span className="text-base">Tambah ke Keranjang</span>
                            <span className="text-base">{formatRp(Number(menu.price) * qty)}</span>
                        </button>
                    ) : (
                        <div className="w-full bg-warmindo-100 text-warmindo-300 py-4 rounded-2xl font-bold text-center text-base">
                            ⚠️ Menu Sedang Habis
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
}

// --- Cart Page Component ---
function CartPage({ cart, total, onUpdate, onRemove, onBack, onCheckout, isLoading }: {
    cart: CartItem[]; total: number; onUpdate: (id: string, d: number) => void;
    onRemove: (id: string) => void; onBack: () => void;
    onCheckout: (p: PaymentMethod, name: string) => void; isLoading: boolean;
}) {
    const [payment, setPayment] = useState<PaymentMethod>('QRIS');
    const [customerName, setCustomerName] = useState('');

    if (cart.length === 0) {
        return (
            <div className="p-6 text-center mt-16">
                <div className="w-20 h-20 bg-warmindo-50 rounded-full flex items-center justify-center mx-auto mb-4">
                    <ShoppingCart className="w-10 h-10 text-warmindo-200" />
                </div>
                <h2 className="text-lg font-bold text-warmindo-brown">Keranjang Kosong</h2>
                <p className="text-warmindo-300 mt-2 mb-6 text-sm">Silakan pilih menu makanan terlebih dahulu.</p>
                <button onClick={onBack} className="bg-orange-50 text-orange-600 font-bold px-6 py-2.5 rounded-xl text-sm active:scale-95 transition-all border border-orange-100">Kembali ke Menu</button>
            </div>
        );
    }

    return (
        <div className="p-4 space-y-5 animate-in">
            {/* Back Button */}
            <button onClick={onBack} className="flex items-center gap-1 text-sm font-semibold text-warmindo-300 active:scale-95 transition-all">
                <ChevronLeft className="w-4 h-4" /> Kembali
            </button>

            <h2 className="font-display font-extrabold text-xl text-warmindo-brown">Pesanan Anda</h2>

            {/* Cart Items */}
            <div className="bg-white rounded-2xl shadow-sm border border-warmindo-100/80 divide-y divide-warmindo-50">
                {cart.map((item: CartItem) => (
                    <div key={item.cartId} className="flex gap-3 p-4">
                        <div className="w-14 h-14 rounded-xl bg-warmindo-50 overflow-hidden shrink-0">
                            <img src={item.image} alt="" className="w-full h-full object-cover" />
                        </div>
                        <div className="flex-grow min-w-0">
                            <h4 className="font-bold text-sm leading-tight truncate text-warmindo-brown">{item.name}</h4>
                            <p className="text-[11px] text-warmindo-300 mt-0.5 truncate">{item.variantName} {item.notes && `- ${item.notes}`}</p>
                            <p className="font-extrabold text-orange-600 text-sm mt-1">{formatRp(item.price)}</p>
                        </div>
                        <div className="flex flex-col items-end justify-between shrink-0">
                            <button onClick={() => onRemove(item.cartId)} className="text-red-400 active:scale-90 transition-all p-1">
                                <Trash2 className="w-4 h-4" />
                            </button>
                            <div className="flex items-center gap-2 bg-warmindo-50 rounded-lg p-1 border border-warmindo-100">
                                <button onClick={() => onUpdate(item.cartId, -1)} className="p-1 active:scale-90 transition-all">
                                    <Minus className="w-3 h-3 text-warmindo-brown/60" />
                                </button>
                                <span className="text-xs font-extrabold w-4 text-center text-warmindo-brown">{item.quantity}</span>
                                <button onClick={() => onUpdate(item.cartId, 1)} className="p-1 active:scale-90 transition-all">
                                    <Plus className="w-3 h-3 text-orange-600" />
                                </button>
                            </div>
                        </div>
                    </div>
                ))}
            </div>

            {/* Customer Name */}
            <div className="bg-white rounded-2xl shadow-sm border border-warmindo-100/80 p-4 space-y-3">
                <h3 className="font-bold text-sm text-warmindo-brown">👤 Nama Pemesan</h3>
                <input
                    type="text"
                    placeholder="Masukkan nama Anda..."
                    className="w-full p-3.5 rounded-xl border-2 border-warmindo-100 focus:border-orange-500 focus:ring-4 focus:ring-orange-500/10 outline-none text-sm transition-all"
                    value={customerName}
                    onChange={e => setCustomerName(e.target.value)}
                />
                {customerName.trim() === '' && (
                    <p className="text-xs text-warmindo-red flex items-center gap-1">
                        <span className="inline-block w-1 h-1 bg-warmindo-red rounded-full"></span>
                        Nama wajib diisi untuk memproses pesanan
                    </p>
                )}
            </div>

            {/* Payment Method */}
            <div className="bg-white rounded-2xl shadow-sm border border-warmindo-100/80 p-4 space-y-3">
                <h3 className="font-bold text-sm text-warmindo-brown">Metode Pembayaran</h3>
                <div className="grid grid-cols-2 gap-3">
                    <div
                        onClick={() => setPayment('QRIS')}
                        className={`p-4 rounded-xl border-2 text-center cursor-pointer transition-all active:scale-95 ${payment === 'QRIS' ? 'border-orange-500 bg-orange-50 shadow-sm shadow-orange-100' : 'border-warmindo-100 bg-white'}`}
                    >
                        <QrCode className={`w-7 h-7 mx-auto mb-2 ${payment === 'QRIS' ? 'text-orange-600' : 'text-warmindo-300'}`} />
                        <span className="text-xs font-bold block text-warmindo-brown">QRIS</span>
                        <span className="text-[10px] text-warmindo-300">Bayar Online</span>
                    </div>
                    <div
                        onClick={() => setPayment('CASH')}
                        className={`p-4 rounded-xl border-2 text-center cursor-pointer transition-all active:scale-95 ${payment === 'CASH' ? 'border-orange-500 bg-orange-50 shadow-sm shadow-orange-100' : 'border-warmindo-100 bg-white'}`}
                    >
                        <DollarSign className={`w-7 h-7 mx-auto mb-2 ${payment === 'CASH' ? 'text-orange-600' : 'text-warmindo-300'}`} />
                        <span className="text-xs font-bold block text-warmindo-brown">Kasir</span>
                        <span className="text-[10px] text-warmindo-300">Bayar Tunai</span>
                    </div>
                </div>
            </div>

            {/* Total */}
            <div className="bg-white p-5 rounded-2xl shadow-sm border border-warmindo-100/80">
                <div className="flex justify-between items-center mb-2">
                    <span className="text-warmindo-300 text-sm">Subtotal</span>
                    <span className="font-semibold text-sm text-warmindo-brown">{formatRp(total)}</span>
                </div>
                <div className="flex justify-between items-center">
                    <span className="text-warmindo-300 text-sm">Pajak (PB1)</span>
                    <span className="text-warmindo-300 text-sm">Sudah Termasuk</span>
                </div>
                <div className="h-px bg-warmindo-100 my-3"></div>
                <div className="flex justify-between items-center">
                    <span className="font-extrabold text-base text-warmindo-brown">Total</span>
                    <span className="font-extrabold text-lg text-orange-600">{formatRp(total)}</span>
                </div>
            </div>

            {/* 5-Minute Payment Warning */}
            <div className="bg-amber-50 border border-amber-200 rounded-xl p-3 flex items-start gap-2">
                <Clock className="w-4 h-4 text-amber-500 mt-0.5 shrink-0" />
                <p className="text-xs text-amber-700">
                    <strong>Penting:</strong> Pembayaran harus diselesaikan dalam <strong>5 menit</strong> setelah pesanan dibuat. Jika melebihi batas waktu, pesanan akan otomatis dibatalkan dan Anda harus membuat pesanan baru.
                </p>
            </div>

            {/* Checkout Button */}
            <button
                onClick={() => onCheckout(payment, customerName.trim())}
                disabled={isLoading || customerName.trim() === ''}
                className="w-full bg-gradient-to-r from-orange-500 to-amber-500 hover:from-orange-600 hover:to-amber-600 text-white font-bold py-4 rounded-2xl shadow-lg shadow-orange-500/25 active:scale-[0.98] transition-all disabled:opacity-60 flex items-center justify-center gap-2 mb-6"
            >
                {isLoading ? (
                    <><Loader2 className="w-5 h-5 animate-spin" /> Memproses...</>
                ) : (
                    'Proses Pesanan Sekarang'
                )}
            </button>
        </div>
    );
}

// --- Order Tracker Page (Real-time via Socket.IO) ---
function OrderTracker({ order, tableNumber, onOrderUpdate }: { order: Order; tableNumber: string; onOrderUpdate: (o: Order) => void }) {
    const [timeLeft, setTimeLeft] = useState<number>(0);

    // Countdown timer for WAITING_PAYMENT orders (5 min = 300 sec)
    useEffect(() => {
        if (order.status !== 'WAITING_PAYMENT') {
            setTimeLeft(0);
            return;
        }

        const orderTime = new Date(order.createdAt).getTime();
        const expiryTime = orderTime + 5 * 60 * 1000; // 5 minutes

        const updateTimer = () => {
            const remaining = Math.max(0, Math.floor((expiryTime - Date.now()) / 1000));
            setTimeLeft(remaining);
        };

        updateTimer();
        const interval = setInterval(updateTimer, 1000);
        return () => clearInterval(interval);
    }, [order.status, order.createdAt]);

    const [simulateLoading, setSimulateLoading] = useState(false);

    const formatCountdown = (seconds: number) => {
        const m = Math.floor(seconds / 60);
        const s = seconds % 60;
        return `${m}:${s.toString().padStart(2, '0')}`;
    };

    const steps = [
        { status: 'WAITING_PAYMENT', label: 'Pembayaran', icon: '💳' },
        { status: 'PAID', label: 'Diterima', icon: '✅' },
        { status: 'PROCESSING', label: 'Dimasak', icon: '👨‍🍳' },
        { status: 'READY', label: 'Siap!', icon: '🎉' }
    ];

    const currentStepIndex = steps.findIndex(s => s.status === order.status) !== -1
        ? steps.findIndex(s => s.status === order.status)
        : (order.status === 'COMPLETED' ? 3 : 0);

    // Show expired screen
    if ((order as any).status === 'EXPIRED' || (order.status === 'WAITING_PAYMENT' && timeLeft === 0 && new Date(order.createdAt).getTime() + 5 * 60 * 1000 < Date.now())) {
        return (
            <div className="p-4 space-y-5 animate-in">
                <div className="text-center mt-8">
                    <div className="w-20 h-20 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-4">
                        <Clock className="w-10 h-10 text-red-500" />
                    </div>
                    <h2 className="font-display font-extrabold text-xl text-warmindo-brown mb-2">Pesanan Kedaluwarsa</h2>
                    <p className="text-sm text-warmindo-300 mb-1">Pesanan <strong className="font-mono">{order.orderNumber}</strong> telah dibatalkan</p>
                    <p className="text-sm text-warmindo-300 mb-6">karena pembayaran tidak diselesaikan dalam 5 menit.</p>
                    <button
                        onClick={() => window.location.reload()}
                        className="bg-gradient-to-r from-orange-500 to-amber-500 hover:from-orange-600 hover:to-amber-600 text-white font-bold px-8 py-3.5 rounded-xl shadow-lg shadow-orange-500/25 active:scale-[0.98] transition-all"
                    >
                        Buat Pesanan Baru
                    </button>
                </div>
            </div>
        );
    }

    return (
        <div className="p-4 space-y-5 animate-in">
            {/* Order Number */}
            <div className="text-center mt-2">
                <div className="inline-block px-3 py-1 bg-orange-100 text-orange-700 rounded-full text-xs font-bold mb-3">Pesanan Aktif</div>
                <h2 className="font-mono font-extrabold text-2xl text-warmindo-brown">{order.orderNumber}</h2>
                <p className="text-warmindo-300 text-sm mt-1">Meja {order.table?.number || tableNumber}{order.customerName ? ` — ${order.customerName}` : ''}</p>
            </div>

            {/* Countdown Timer (WAITING_PAYMENT only) */}
            {order.status === 'WAITING_PAYMENT' && timeLeft > 0 && (
                <div className={`text-center p-3 rounded-xl border-2 ${timeLeft <= 60 ? 'bg-red-50 border-red-200' : timeLeft <= 120 ? 'bg-amber-50 border-amber-200' : 'bg-warmindo-50 border-warmindo-200'
                    }`}>
                    <p className={`text-xs font-medium ${timeLeft <= 60 ? 'text-red-600' : timeLeft <= 120 ? 'text-amber-600' : 'text-warmindo-300'
                        }`}>Batas waktu pembayaran</p>
                    <p className={`font-mono font-extrabold text-2xl ${timeLeft <= 60 ? 'text-red-600 animate-pulse' : timeLeft <= 120 ? 'text-amber-600' : 'text-warmindo-brown'
                        }`}>{formatCountdown(timeLeft)}</p>
                </div>
            )}

            {/* QRIS Payment — Midtrans Snap Embedded + Test Button */}
            {order.status === 'WAITING_PAYMENT' && order.paymentMethod === 'QRIS' && (
                <div className="bg-white p-5 rounded-2xl shadow-sm border-2 border-orange-200 text-center relative overflow-hidden">
                    <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-orange-400 to-amber-500"></div>

                    <h3 className="font-extrabold text-warmindo-brown mb-1 text-base">Scan QRIS untuk Bayar</h3>
                    <p className="text-orange-600 font-extrabold text-xl mb-3">{formatRp(Number(order.totalAmount))}</p>

                    {/* Midtrans Snap Page in Iframe */}
                    {(order as any).snapRedirectUrl ? (
                        <div className="rounded-xl overflow-hidden border border-warmindo-200 mb-4" style={{ height: '420px' }}>
                            <iframe
                                src={(order as any).snapRedirectUrl}
                                title="Midtrans Payment"
                                className="w-full h-full border-0"
                                allow="payment"
                            />
                        </div>
                    ) : (
                        <div className="bg-warmindo-50 p-8 rounded-xl mb-4 flex flex-col items-center justify-center" style={{ height: '200px' }}>
                            <QrCode className="w-16 h-16 text-warmindo-200 mb-2" />
                            <p className="text-xs text-warmindo-300">QRIS sedang dimuat...</p>
                        </div>
                    )}

                    {/* Test Sudah Bayar Button (Sandbox Only) */}
                    <button
                        disabled={simulateLoading}
                        onClick={async () => {
                            setSimulateLoading(true);
                            try {
                                const res = await fetch(`${API_BASE}/payments/simulate/${order.id}`, { method: 'POST' });
                                const updated = await res.json();
                                if (updated.status) onOrderUpdate(updated);
                            } catch (e) {
                                console.error('Simulate failed:', e);
                                alert('Gagal simulasi.');
                            } finally {
                                setSimulateLoading(false);
                            }
                        }}
                        className="w-full bg-gradient-to-r from-orange-500 to-amber-500 hover:from-orange-600 hover:to-amber-600 text-white font-bold py-3.5 rounded-xl shadow-lg shadow-orange-500/25 active:scale-[0.98] transition-all flex items-center justify-center gap-2 mb-3 disabled:opacity-60"
                    >
                        {simulateLoading ? (
                            <><Loader2 className="w-5 h-5 animate-spin" /> Memproses Pembayaran...</>
                        ) : (
                            <><Check className="w-5 h-5" /> Test Sudah Bayar</>
                        )}
                    </button>

                    {/* Check Status Button */}
                    <button
                        onClick={async () => {
                            try {
                                const res = await fetch(`${API_BASE}/payments/verify/${order.id}`, { method: 'POST' });
                                const updated = await res.json();
                                if (updated.status) onOrderUpdate(updated);
                            } catch (e) {
                                console.error('Check status failed:', e);
                            }
                        }}
                        className="w-full bg-white text-warmindo-brown/70 font-semibold py-3 rounded-xl border-2 border-warmindo-200 active:scale-[0.98] transition-all flex items-center justify-center gap-2 text-sm mb-3 hover:bg-warmindo-50"
                    >
                        <Clock className="w-4 h-4" />
                        Cek Status Pembayaran
                    </button>

                    <p className="text-xs text-warmindo-300 flex items-center justify-center gap-2">
                        <Loader2 className="w-3 h-3 animate-spin" />
                        Status akan update otomatis setelah pembayaran
                    </p>
                </div>
            )}

            {/* Cash Waiting */}
            {order.status === 'WAITING_PAYMENT' && order.paymentMethod === 'CASH' && (
                <div className="bg-amber-50 p-6 rounded-2xl border-2 border-amber-200 text-center">
                    <Clock className="w-12 h-12 text-amber-500 mx-auto mb-3" />
                    <h3 className="font-extrabold text-amber-800 mb-2">Bayar di Kasir</h3>
                    <p className="text-sm text-amber-700">Tunjukkan kode pesanan <strong className="font-mono bg-amber-100 px-2 py-0.5 rounded">{order.orderNumber}</strong> ke kasir.</p>
                    <p className="text-xs text-amber-600 mt-2">Segera bayar sebelum batas waktu habis.</p>
                </div>
            )}

            {/* Progress Tracker */}
            {order.status !== 'WAITING_PAYMENT' && (
                <div className="bg-white p-5 rounded-2xl shadow-sm border border-warmindo-100/80">
                    <h3 className="font-bold text-sm mb-5 text-warmindo-brown">Status Pesanan</h3>
                    <div className="relative">
                        {/* Background Line */}
                        <div className="absolute left-[15px] top-4 bottom-4 w-0.5 bg-warmindo-100"></div>
                        {/* Active Line */}
                        <div
                            className="absolute left-[15px] top-4 w-0.5 bg-orange-500 transition-all duration-700 ease-out"
                            style={{ height: `${Math.min((currentStepIndex / (steps.length - 1)) * 100, 100)}%` }}
                        ></div>

                        <div className="space-y-6">
                            {steps.map((step, idx) => {
                                const isPast = idx <= currentStepIndex;
                                const isCurrent = idx === currentStepIndex && order.status !== 'COMPLETED';
                                return (
                                    <div key={step.status} className="relative flex items-center gap-4">
                                        <div className={`w-8 h-8 rounded-full flex items-center justify-center shrink-0 relative z-10 transition-all duration-500 ${isPast ? 'bg-gradient-to-r from-orange-500 to-amber-500 text-white shadow-md shadow-orange-500/30 scale-110' : 'bg-warmindo-100 text-warmindo-300'}`}>
                                            {isPast ? <Check className="w-4 h-4" /> : <div className="w-2 h-2 rounded-full bg-warmindo-300"></div>}
                                        </div>
                                        <div>
                                            <h4 className={`font-bold text-sm ${isCurrent ? 'text-orange-600' : isPast ? 'text-warmindo-brown' : 'text-warmindo-300'}`}>
                                                {step.icon} {step.label}
                                            </h4>
                                            {isCurrent && <p className="text-xs text-orange-500 mt-0.5 flex items-center gap-1"><Loader2 className="w-3 h-3 animate-spin" /> Sedang berlangsung...</p>}
                                        </div>
                                    </div>
                                );
                            })}
                        </div>
                    </div>
                </div>
            )}

            {/* Order Completed Banner */}
            {order.status === 'COMPLETED' && (
                <div className="bg-gradient-to-r from-orange-500 to-amber-500 p-5 rounded-2xl text-center text-white shadow-lg shadow-orange-500/25">
                    <div className="text-4xl mb-2">🎉</div>
                    <h3 className="font-display font-extrabold text-lg">Pesanan Selesai!</h3>
                    <p className="text-sm text-orange-100 mt-1">Terima kasih telah memesan di Warmindo Barokah</p>
                </div>
            )}

            {/* Order Detail */}
            <div className="bg-white rounded-2xl p-5 shadow-sm border border-warmindo-100/80">
                <h3 className="font-bold text-sm border-b border-warmindo-100 pb-3 mb-3 text-warmindo-brown">Detail Pesanan</h3>
                <div className="space-y-3">
                    {(order.items || []).map((item: OrderItem) => (
                        <div key={item.id} className="flex justify-between text-sm">
                            <div className="flex gap-2">
                                <span className="font-bold text-orange-600">{item.quantity}x</span>
                                <div>
                                    <p className="text-warmindo-brown font-medium">{item.menu?.name || 'Menu'}</p>
                                    {(item.variantName || item.notes) && <p className="text-xs text-warmindo-300">{item.variantName} {item.notes && `(${item.notes})`}</p>}
                                </div>
                            </div>
                            <span className="font-semibold text-warmindo-brown/80">{formatRp(Number(item.price) * item.quantity)}</span>
                        </div>
                    ))}
                </div>
                <div className="mt-4 pt-4 border-t border-warmindo-100 flex justify-between font-extrabold text-warmindo-brown">
                    <span>Total</span>
                    <span className="text-orange-600">{formatRp(Number(order.totalAmount))}</span>
                </div>
            </div>
        </div>
    );
}
