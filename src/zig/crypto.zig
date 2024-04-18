const std = @import("std");

const crypto = std.crypto;
const hasher = crypto.hash;
const signer = crypto.sign.Ed25519;

pub fn Hasher() type {
    return struct {
        pub fn Blake3(input: []const u8, options: hash_options) [hasher.Blake3.block_length]u8 {
            return Hash(hasher.Blake3, input, options);
        }
        pub fn Sha256(input: []const u8, options: hash_options) [hasher.sha2.Sha256.block_length]u8 {
            return Hash(hasher.sha2.Sha256, input, options);
        }

        const hash_options = struct { case: std.fmt.Case };

        fn Hash(context: anytype, input: []const u8, options: hash_options) [context.block_length]u8 {
            var hash3 = context.init(.{});
            var index: usize = 0;
            const chunkSize = context.block_length;

            while (index < input.len) : (index += chunkSize) {
                const chunkEnd = @min(index + chunkSize, input.len);
                const chunk = input[index..chunkEnd];
                hash3.update(chunk);
            }

            var out: [context.digest_length]u8 = undefined;
            hash3.final(&out);

            const hex = std.fmt.bytesToHex(out, options.case);
            return hex;
        }

        pub fn verify_hash(algo: enum { blake3, sha256 }, to_hash: []const u8, _hash: []const u8) bool {
            switch (algo) {
                .blake3 => {
                    const computed_hash = Hash(hasher.Blake3, to_hash, .{ .case = .lower });

                    if (std.mem.eql(u8, &computed_hash, _hash)) {
                        return true;
                    } else {
                        const computed_hash_upper = Hash(hasher.Blake3, to_hash, .{ .case = .upper });
                        if (std.mem.eql(u8, &computed_hash_upper, _hash)) return true else return false;
                    }
                },
                .sha256 => {
                    const computed_hash = Hash(hasher.sha2.Sha256, to_hash, .{ .case = .lower });

                    if (std.mem.eql(u8, &computed_hash, _hash)) {
                        return true;
                    } else {
                        const computed_hash_upper = Hash(hasher.Blake3, to_hash, .{ .case = .upper });
                        if (std.mem.eql(u8, &computed_hash_upper, _hash)) return true else return false;
                    }
                },
            }
        }
    };
}
