#!/usr/bin/env python3
"""
Parse Signal sticker pack manifest (protobuf format)
Usage: parse-sticker-manifest.py <manifest.proto>
"""
import sys
import json

def parse_manifest(filepath):
    with open(filepath, 'rb') as f:
        data = f.read()

    manifest = {'title': '', 'author': '', 'stickers': []}
    i = 0

    while i < len(data):
        if i >= len(data):
            break

        tag = data[i] >> 3
        wire = data[i] & 0x7
        i += 1

        if tag == 1 and wire == 2:  # title
            if i >= len(data):
                break
            length = data[i]
            i += 1
            if i + length <= len(data):
                manifest['title'] = data[i:i+length].decode('utf-8', errors='ignore')
            i += length
        elif tag == 2 and wire == 2:  # author
            if i >= len(data):
                break
            length = data[i]
            i += 1
            if i + length <= len(data):
                manifest['author'] = data[i:i+length].decode('utf-8', errors='ignore')
            i += length
        elif tag == 4 and wire == 2:  # sticker
            if i >= len(data):
                break
            length = data[i]
            i += 1
            end = i + length
            sticker = {'id': 0, 'emoji': ''}

            while i < end and i < len(data):
                st = data[i] >> 3
                sw = data[i] & 0x7
                i += 1

                if st == 1 and sw == 0:  # sticker id
                    if i < len(data):
                        sticker['id'] = data[i]
                        i += 1
                elif st == 2 and sw == 2:  # emoji
                    if i < len(data):
                        el = data[i]
                        i += 1
                        if i + el <= len(data):
                            sticker['emoji'] = data[i:i+el].decode('utf-8', errors='ignore')
                        i += el
                else:
                    # Skip unknown fields
                    break

            manifest['stickers'].append(sticker)
            i = end
        else:
            # Skip unknown fields
            if wire == 0:
                i += 1
            elif wire == 2:
                if i < len(data):
                    length = data[i]
                    i += 1 + length
                else:
                    break
            else:
                break

    if manifest['stickers']:
        manifest['cover'] = manifest['stickers'][0]

    return manifest

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: parse-sticker-manifest.py <manifest.proto>", file=sys.stderr)
        sys.exit(1)

    try:
        manifest = parse_manifest(sys.argv[1])
        print(json.dumps(manifest))
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
