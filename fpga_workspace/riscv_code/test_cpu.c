typedef unsigned int uint32_t;
typedef int int32_t;

int main() {
    // V?n là cái hòm thu chân ái 0x0804 d? con ARM canh ch?ng
    volatile uint32_t *status_addr = (volatile uint32_t *)0x00000804;

    // --- B?T Ð?U CÂU CHUY?N ---
    
    // 1. Linh luong d?u tháng: 10,000k
    volatile int32_t tien_luong = 10000;
    
    // 2. V? thu ti?n nhà c?a, b?m s?a: 8,000k
    volatile int32_t bi_vo_thu = 8000;
    int32_t quy_den = tien_luong - bi_vo_thu; // Qu? den còn: 2000
    
    // 3. Cu?i tu?n r? b?n thân di nh?u h?t 500k
    volatile int32_t tien_nhau = 500;
    quy_den = quy_den - tien_nhau;            // Qu? den còn: 1500
    
    // 4. Nh?t du?c t? vé s? trúng gi?i khuy?n khích: 34k
    volatile int32_t trung_so = 34;
    quy_den = quy_den + trung_so;             // Qu? den v?t vát du?c: 1534
    
    // 5. Ði xe máy quên b?t xi-nhan b? m?y anh áo vàng g?i vào: 300k
    volatile int32_t tien_phat = 300;
    int32_t tong_ket = quy_den - tien_phat;   // Ch?t s?: Còn dúng 1234k

    // --------------------------

    // G?i s? ti?n còm cõi 1234 vào hòm thu báo cáo
    *status_addr = tong_ket;

    // CPU ng?t x?u vì viêm màng túi, khóa ch?t PC t?i dây
    __asm__ volatile (".align 2\n1: j 1b\n\t");

    return 0;
}