#!/bin/bash
# Signal Sticker Decryption Script
# Usage: sticker-decrypt.sh <hex_key> <input_file> <output_file>
#
# Signal stickers are encrypted with AES-256-CBC.
# The encryption key is derived using HKDF from the pack key.
# Format: [16-byte IV][ciphertext][32-byte HMAC]

set -e

HEX_KEY="$1"
INPUT_FILE="$2"
OUTPUT_FILE="$3"

if [ -z "$HEX_KEY" ] || [ -z "$INPUT_FILE" ] || [ -z "$OUTPUT_FILE" ]; then
    echo "Usage: sticker-decrypt.sh <hex_key> <input_file> <output_file>" >&2
    exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file not found: $INPUT_FILE" >&2
    exit 1
fi

# Create temp directory for intermediate files
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Python helper for hex/binary operations (avoids xxd dependency)
hex_to_bin() {
    python3 -c "import sys; sys.stdout.buffer.write(bytes.fromhex('$1'))"
}

bin_to_hex() {
    python3 -c "import sys; print(sys.stdin.buffer.read().hex())"
}

# HKDF Implementation using OpenSSL
hkdf_derive() {
    local hex_key="$1"
    local info="$2"
    local out_file="$3"

    # Salt is 32 zero bytes
    local salt_hex=$(printf '%064d' 0)

    # Convert hex key to binary for HMAC
    hex_to_bin "$hex_key" > "$TEMP_DIR/ikm.bin"
    hex_to_bin "$salt_hex" > "$TEMP_DIR/salt.bin"

    # HKDF-Extract: PRK = HMAC-SHA256(salt, IKM)
    PRK_HEX=$(openssl dgst -sha256 -mac HMAC -macopt hexkey:"$salt_hex" -hex "$TEMP_DIR/ikm.bin" 2>/dev/null | awk '{print $2}')

    # HKDF-Expand to 64 bytes (32 for AES key, 32 for HMAC key)
    local info_hex=$(echo -n "$info" | bin_to_hex)

    # T(1) = HMAC-SHA256(PRK, info || 0x01)
    hex_to_bin "${info_hex}01" > "$TEMP_DIR/t1_input.bin"
    T1_HEX=$(openssl dgst -sha256 -mac HMAC -macopt hexkey:"$PRK_HEX" -hex "$TEMP_DIR/t1_input.bin" 2>/dev/null | awk '{print $2}')

    # T(2) = HMAC-SHA256(PRK, T(1) || info || 0x02)
    hex_to_bin "${T1_HEX}${info_hex}02" > "$TEMP_DIR/t2_input.bin"
    T2_HEX=$(openssl dgst -sha256 -mac HMAC -macopt hexkey:"$PRK_HEX" -hex "$TEMP_DIR/t2_input.bin" 2>/dev/null | awk '{print $2}')

    # OKM = T(1) || T(2) = 64 bytes
    echo -n "${T1_HEX}${T2_HEX}" > "$out_file"
}

# Derive keys using HKDF
hkdf_derive "$HEX_KEY" "Sticker Pack" "$TEMP_DIR/okm.hex"
OKM=$(cat "$TEMP_DIR/okm.hex")

# Split into AES key (first 32 bytes = 64 hex chars) and HMAC key (last 32 bytes)
AES_KEY_HEX="${OKM:0:64}"
HMAC_KEY_HEX="${OKM:64:64}"

# Get file size
FILE_SIZE=$(stat -c%s "$INPUT_FILE")

# Extract components from encrypted data:
# - First 16 bytes: IV
# - Last 32 bytes: HMAC
# - Middle: Ciphertext

IV_SIZE=16
HMAC_SIZE=32
CIPHERTEXT_SIZE=$((FILE_SIZE - IV_SIZE - HMAC_SIZE))

if [ $CIPHERTEXT_SIZE -le 0 ]; then
    echo "Error: Input file too small" >&2
    exit 1
fi

# Extract IV (first 16 bytes)
dd if="$INPUT_FILE" of="$TEMP_DIR/iv.bin" bs=1 count=$IV_SIZE 2>/dev/null
IV_HEX=$(cat "$TEMP_DIR/iv.bin" | bin_to_hex)

# Extract ciphertext (middle portion)
dd if="$INPUT_FILE" of="$TEMP_DIR/ciphertext.bin" bs=1 skip=$IV_SIZE count=$CIPHERTEXT_SIZE 2>/dev/null

# Extract their HMAC (last 32 bytes)
dd if="$INPUT_FILE" of="$TEMP_DIR/their_mac.bin" bs=1 skip=$((IV_SIZE + CIPHERTEXT_SIZE)) count=$HMAC_SIZE 2>/dev/null
THEIR_MAC_HEX=$(cat "$TEMP_DIR/their_mac.bin" | bin_to_hex)

# Verify HMAC: compute HMAC over IV + ciphertext
dd if="$INPUT_FILE" of="$TEMP_DIR/data_to_verify.bin" bs=1 count=$((FILE_SIZE - HMAC_SIZE)) 2>/dev/null
OUR_MAC_HEX=$(openssl dgst -sha256 -mac HMAC -macopt hexkey:"$HMAC_KEY_HEX" -hex "$TEMP_DIR/data_to_verify.bin" 2>/dev/null | awk '{print $2}')

if [ "$THEIR_MAC_HEX" != "$OUR_MAC_HEX" ]; then
    echo "Error: HMAC verification failed" >&2
    echo "Expected: $THEIR_MAC_HEX" >&2
    echo "Got: $OUR_MAC_HEX" >&2
    exit 1
fi

# Decrypt using OpenSSL AES-256-CBC
openssl enc -d -aes-256-cbc -K "$AES_KEY_HEX" -iv "$IV_HEX" -in "$TEMP_DIR/ciphertext.bin" -out "$OUTPUT_FILE" 2>/dev/null

echo "Decryption successful: $OUTPUT_FILE"
