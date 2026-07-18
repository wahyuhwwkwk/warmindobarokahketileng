import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
    console.log('🌱 Seeding database...');

    // --- Categories ---
    const makanan = await prisma.category.upsert({
        where: { name: 'Makanan' },
        update: {},
        create: { name: 'Makanan' }
    });
    const minuman = await prisma.category.upsert({
        where: { name: 'Minuman' },
        update: {},
        create: { name: 'Minuman' }
    });
    const cemilan = await prisma.category.upsert({
        where: { name: 'Cemilan' },
        update: {},
        create: { name: 'Cemilan' }
    });

    console.log('✅ Categories seeded:', makanan.name, minuman.name, cemilan.name);

    // --- Menus ---
    const menus = [
        {
            name: 'Indomie Goreng Spesial',
            categoryId: makanan.id,
            price: 15000,
            image: 'https://images.unsplash.com/photo-1612929633738-8fe44f7ec841?auto=format&fit=crop&w=400&q=80',
            description: 'Indomie goreng double dengan telur mata sapi, sosis, dan sayuran segar.',
            hasSpicyLevel: true,
            hasTempLevel: false,
        },
        {
            name: 'Nasi Telur Pontianak',
            categoryId: makanan.id,
            price: 18000,
            image: 'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?auto=format&fit=crop&w=400&q=80',
            description: 'Nasi hangat disajikan dengan telur ceplok krispi dan siraman kecap bumbu spesial.',
            hasSpicyLevel: true,
            hasTempLevel: false,
        },
        {
            name: 'Magelangan Warmindo',
            categoryId: makanan.id,
            price: 20000,
            image: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=400&q=80',
            description: 'Nasi goreng campur mie dengan suwiran ayam, telur, dan kerupuk.',
            hasSpicyLevel: true,
            hasTempLevel: false,
        },
        {
            name: 'Es Teh Manis',
            categoryId: minuman.id,
            price: 5000,
            image: 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?auto=format&fit=crop&w=400&q=80',
            description: 'Teh melati seduh segar dengan gula asli.',
            hasSpicyLevel: false,
            hasTempLevel: true,
        },
        {
            name: 'Kopi Susu Gula Aren',
            categoryId: minuman.id,
            price: 12000,
            image: 'https://images.unsplash.com/photo-1536935338788-846bb9981813?auto=format&fit=crop&w=400&q=80',
            description: 'Kopi espresso dengan susu segar dan sirup gula aren pilihan.',
            hasSpicyLevel: false,
            hasTempLevel: true,
        },
        {
            name: 'Mendoan Anget',
            categoryId: cemilan.id,
            price: 10000,
            image: 'https://images.unsplash.com/photo-1621506289937-a8e4df240d0b?auto=format&fit=crop&w=400&q=80',
            description: 'Tempe mendoan digoreng setengah matang disajikan dengan sambal kecap. (Isi 4)',
            hasSpicyLevel: false,
            hasTempLevel: false,
        },
    ];

    for (const menuData of menus) {
        const existing = await prisma.menu.findFirst({ where: { name: menuData.name } });
        if (!existing) {
            await prisma.menu.create({ data: menuData });
            console.log(`  ✅ Menu created: ${menuData.name}`);
        } else {
            console.log(`  ⏭️ Menu already exists: ${menuData.name}`);
        }
    }

    // --- Restaurant Tables (1-20) ---
    for (let i = 1; i <= 20; i++) {
        await prisma.restaurantTable.upsert({
            where: { number: i },
            update: {},
            create: { number: i }
        });
    }
    console.log('✅ 20 tables seeded');

    // --- Default Banners ---
    const banners = [
        {
            title: 'Promo Spesial Hari Ini',
            subtitle: 'Diskon 20% untuk semua menu mie!',
            imageUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=800&q=80',
            sortOrder: 1,
        },
        {
            title: 'Menu Baru: Kopi Susu',
            subtitle: 'Coba kopi susu gula aren kami!',
            imageUrl: 'https://images.unsplash.com/photo-1536935338788-846bb9981813?auto=format&fit=crop&w=800&q=80',
            sortOrder: 2,
        },
        {
            title: 'Gratis Mendoan',
            subtitle: 'Setiap pembelian min. Rp 30.000',
            imageUrl: 'https://images.unsplash.com/photo-1612929633738-8fe44f7ec841?auto=format&fit=crop&w=800&q=80',
            sortOrder: 3,
        },
    ];

    const existingBanners = await prisma.banner.count();
    if (existingBanners === 0) {
        for (const bannerData of banners) {
            await prisma.banner.create({ data: bannerData });
            console.log(`  ✅ Banner created: ${bannerData.title}`);
        }
    } else {
        console.log(`  ⏭️ Banners already exist (${existingBanners})`);
    }

    console.log('\n🎉 Seed completed successfully!');
}

main()
    .catch((e) => {
        console.error('❌ Seed failed:', e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
