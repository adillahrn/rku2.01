import struct
import zlib
import os
import sys
from PIL import Image

def export_aseprite(filepath, output_dir=None):
    if not os.path.exists(filepath):
        print(f"File not found: {filepath}")
        return False
        
    if output_dir is None:
        output_dir = os.path.dirname(filepath)
    os.makedirs(output_dir, exist_ok=True)
    
    filename = os.path.splitext(os.path.basename(filepath))[0]
    
    with open(filepath, 'rb') as f:
        data = f.read()
        
    if len(data) < 128:
        print("File too short to be an Aseprite file.")
        return False
        
    # Header parsing
    file_size, magic, frames_count, width, height, color_depth = struct.unpack_from('<IHHHHI', data, 0)[:6]
    
    # color_depth: 32 = RGBA, 16 = Grayscale, 8 = Indexed
    if magic != 0xA5E0:
        print(f"Invalid Aseprite magic number: {hex(magic)}")
        return False
        
    print(f"Aseprite File: {filename}")
    print(f"  Size: {width}x{height}, Frames: {frames_count}, Color Depth: {color_depth}bpp")
    
    offset = 128
    frame_idx = 0
    
    # Read Palette if indexed
    palette = {}
    
    while offset < len(data) and frame_idx < frames_count:
        if offset + 16 > len(data):
            break
            
        frame_size, frame_magic, old_chunks, duration, _, new_chunks = struct.unpack_from('<IHHHHI', data, offset)
        if frame_magic != 0xF1FA:
            print(f"Invalid frame magic: {hex(frame_magic)} at {offset}")
            break
            
        chunk_count = new_chunks if new_chunks != 0 else old_chunks
        # print(f"Frame {frame_idx}: size={frame_size}, chunks={chunk_count}")
        
        frame_end = offset + frame_size
        offset += 16 # Skip frame header
        
        cel_images = [] # Store tuple of (x, y, image) for merging
        
        for _ in range(chunk_count):
            if offset + 6 > frame_end:
                break
            chunk_size, chunk_type = struct.unpack_from('<IH', data, offset)
            chunk_data_end = offset + chunk_size
            chunk_payload = data[offset+6:chunk_data_end]
            
            # Palette Chunk
            if chunk_type == 0x2019:
                # Palette chunk
                pal_size, first, last = struct.unpack_from('<III', chunk_payload, 0)
                pal_offset = 12
                for i in range(first, last + 1):
                    flags, r, g, b, a = struct.unpack_from('<HBBBB', chunk_payload, pal_offset)
                    palette[i] = (r, g, b, a)
                    pal_offset += 6
                    if flags & 1: # Has name
                        name_len = struct.unpack_from('<H', chunk_payload, pal_offset)[0]
                        pal_offset += 2 + name_len
                        
            # Cel Chunk
            elif chunk_type == 0x2016:
                layer_idx, cel_x, cel_y, opacity, cel_type = struct.unpack_from('<HhhBH', chunk_payload, 0)
                # cel_type: 0 = Raw, 1 = Linked, 2 = Compressed
                if cel_type == 2:
                    cel_w, cel_h = struct.unpack_from('<HH', chunk_payload, 10)
                    compressed_pixels = chunk_payload[14:]
                    try:
                        raw_pixels = zlib.decompress(compressed_pixels)
                        
                        # Create PIL image for this Cel
                        if color_depth == 32:
                            cel_img = Image.frombytes('RGBA', (cel_w, cel_h), raw_pixels)
                        elif color_depth == 16:
                            # Grayscale + Alpha
                            cel_img = Image.frombytes('LA', (cel_w, cel_h), raw_pixels)
                        elif color_depth == 8:
                            # Indexed. Convert to RGBA using our palette
                            rgba_pixels = bytearray()
                            for idx in raw_pixels:
                                r, g, b, a = palette.get(idx, (0, 0, 0, 0))
                                rgba_pixels.extend([r, g, b, a])
                            cel_img = Image.frombytes('RGBA', (cel_w, cel_h), bytes(rgba_pixels))
                        else:
                            cel_img = None
                            
                        if cel_img:
                            # Apply cel opacity
                            if opacity < 255:
                                # Multiply alpha channel by opacity
                                if cel_img.mode == 'RGBA':
                                    r, g, b, a = cel_img.split()
                                    a = a.point(lambda p: int(p * opacity / 255.0))
                                    cel_img = Image.merge('RGBA', (r, g, b, a))
                            cel_images.append((cel_x, cel_y, cel_img))
                    except Exception as e:
                        print(f"Error decompressing cel: {e}")
                        
            offset = chunk_data_end
            
        # Compose frame image
        if cel_images:
            frame_img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
            for cx, cy, c_img in cel_images:
                # Paste cel_img onto frame_img at (cx, cy)
                # Need to handle transparent paste
                frame_img.alpha_composite(c_img, (cx, cy))
                
            out_path = os.path.join(output_dir, f"{filename}.png" if frames_count == 1 else f"{filename}_{frame_idx}.png")
            frame_img.save(out_path)
            print(f"  Saved: {out_path}")
            
        offset = frame_end
        frame_idx += 1
        
    return True

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python3 extract_aseprite.py <path_to_aseprite> [output_dir]")
    else:
        export_aseprite(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else None)
