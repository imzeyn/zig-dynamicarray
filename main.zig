const std = @import("std");

// Dağılmış Array Yapısı
const DynamicArray = struct {
    allocator: *std.mem.Allocator,
    chunk_size: usize,
    chunks: std.AutoHashMap(i32, *u8),
    total_elements: i32,
    current_chunk_index: i32,
    array: ?[]u8,

    pub fn init(allocator: *std.mem.Allocator, initial_chunk_size: usize) DynamicArray {
        return DynamicArray{
            .allocator = allocator,
            .chunk_size = initial_chunk_size,
            .chunks = std.AutoHashMap(i32, *u8).init(allocator),
            .total_elements = 0,
            .current_chunk_index = 0,
            .array = null,
        };
    }

    // Eleman eklemek için fonksiyon
    pub fn add(self: *DynamicArray, value: i32) !void {
        // Eğer mevcut chunk dolmuşsa, yeni bir chunk tahsis et
        if (self.total_elements % self.chunk_size == 0) {
            const new_chunk = try self.allocator.alloc(u8, self.chunk_size);
            try self.chunks.put(self.current_chunk_index, new_chunk);

            // Mevcut array'i yeni chunk'a yönlendir
            self.array = new_chunk;
            self.current_chunk_index += 1;
        }

        // Array'e elemanı ekle
        const index_in_chunk = self.total_elements % self.chunk_size;
        self.array[index_in_chunk] = value;
        self.total_elements += 1;
    }

    // Eleman almak için fonksiyon
    pub fn get(self: *DynamicArray, index: i32) !i32 {
        const chunk_index = index / self.chunk_size;
        const index_in_chunk = index % self.chunk_size;

        const chunk_ptr = try self.chunks.get(chunk_index);
        return chunk_ptr[index_in_chunk];
    }

    // Belleği temizle
    pub fn deinit(self: *DynamicArray) void {
        // Tüm chunk'ları serbest bırak
        for (self.chunks.items()) |(_, chunk_ptr)| {
            self.allocator.free(chunk_ptr);
        }
    }
};

pub fn main() void {
    const allocator = std.heap.page_allocator;
    var dynamic_array = DynamicArray.init(allocator, 10); // İlk chunk boyutu 10

    // Array'e eleman ekleyelim
    for (i32(0)..30) |i| {
        try dynamic_array.add(i);
    }

    // Array'deki verileri yazdıralım
    for (i32(0)..30) |i| {
        const value = try dynamic_array.get(i);
        std.debug.print("Eleman {}: {}\n", .{i, value});
    }

    // Belleği serbest bırak
    dynamic_array.deinit();
}
