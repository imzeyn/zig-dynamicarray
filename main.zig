const std = @import("std");

const DynamicArray = struct {
    allocator: std.mem.Allocator,
    chunk_size: usize,
    chunks: std.AutoHashMap(usize, []u8),
    total_elements: usize,
    current_chunk_index: usize,
    array: ?[]u8,

    pub fn init(allocator: std.mem.Allocator, initial_chunk_size: usize) DynamicArray {
        return DynamicArray{
            .allocator = allocator,
            .chunk_size = initial_chunk_size,
            .chunks = std.AutoHashMap(usize, []u8).init(allocator),
            .total_elements = 0,
            .current_chunk_index = 0,
            .array = null,
        };
    }

    pub fn add(self: *DynamicArray, value: u8) !void {
        if (self.total_elements % self.chunk_size == 0) {
            const new_chunk = try self.allocator.alloc(u8, self.chunk_size);
            try self.chunks.put(self.current_chunk_index, new_chunk);
            self.array = new_chunk;
            self.current_chunk_index += 1;
        }
        const index_in_chunk = self.total_elements % self.chunk_size;
        self.array.?[index_in_chunk] = value;
        self.total_elements += 1;
    }

    pub fn get(self: *DynamicArray, index: usize) !u8 {
        const chunk_index = index / self.chunk_size;
        const index_in_chunk = index % self.chunk_size;
        const chunk = self.chunks.get(chunk_index) orelse return error.IndexOutOfBounds;
        return chunk[index_in_chunk];
    }
    pub fn deinit(self: *DynamicArray) void {
        var it = self.chunks.iterator();
        while (it.next()) |entry| {
            self.allocator.free(entry.value_ptr.*);
        }
        self.chunks.deinit();
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var dynamic_array = DynamicArray.init(allocator, 10);

    for (0..30) |i| {
        // i % 256 sonucunu, @truncate ile u8 türüne indiriyoruz.
        const val: u8 = @truncate(i % 256);
        try dynamic_array.add(val);
    }

    for (0..30) |i| {
        const value = try dynamic_array.get(i);
        std.debug.print("Eleman {}: {}\n", .{ i, value });
    }

    dynamic_array.deinit();
}
