# mv.rres

A V wrapper for [rres](https://github.com/raysan5/rres) by raysan5, a simple binary asset archive format designed for use with Raylib. The C library is compiled directly from source: no separate installation required. LZ4 compression and QOI image encoding are both enabled by default.

An `.rres` file is a flat binary container of typed resource chunks, each identified by a CRC32 of its original filename. An optional Central Directory appended to the file maps filename strings back to chunk IDs, allowing named lookup without scanning the file. `.rres` archives are produced externally using [rrespacker](https://raylibtech.itch.io/rrespacker), a graphical tool by raysan5 available on itch.io.

## RresLoader

`RresLoader` is the high-level entry point for loading assets. It opens an `.rres` file once, reads its Central Directory, and exposes named chunk loading through `load_single` and `load_multi`. The low-level C functions are available directly but `RresLoader` handles the repetitive ID lookup, decompression, and decryption steps automatically.

```v
import rres

mut loader := rres.RresLoader.new('assets.rres') or { panic('could not open assets.rres') }
defer { loader.unload() }

// single-chunk resources (image, wave, text, raw data)
if chunk := loader.load_single('textures/hero.png') {
    defer { chunk.unload() }
    img := rres.load_image_from_resource(chunk)      // rl.Image
    // upload to GPU: rl.load_texture_from_image(img)
}

// multi-chunk resources (fonts require image atlas + glyph metrics)
if multi := loader.load_multi('fonts/ui.ttf') {
    defer { multi.unload() }
    font := rres.load_font_from_resource(multi)      // rl.Font
}

// raw bytes (for any format handled at a higher level, e.g. .ptcop)
if chunk := loader.load_single('audio/theme.ptcop') {
    defer { chunk.unload() }
    data, size := rres.load_data_from_resource(chunk)
    bytes := unsafe { data.vbytes(int(size)) }
}

// shader source (TEXT chunks)
if chunk := loader.load_single('shaders/bloom.fs') {
    defer { chunk.unload() }
    src := rres.load_text_from_resource(chunk)       // V string, memory managed
}
```

`load_single` and `load_multi` both automatically unpack compressed or encrypted chunks before returning them. If unpacking fails the function returns `none`. Always call `chunk.unload()` or `multi.unload()` after the data has been consumed.

## Chunk types and loaders

| FourCC | `ResourceDataType` | Loader function | Notes |
|--------|--------------------|-----------------|-------|
| `IMGE` | `.image`           | `load_image_from_resource(chunk)` | Returns `rl.Image`; upload to GPU separately |
| `WAVE` | `.wave`            | `load_wave_from_resource(chunk)` | Returns `rl.Wave`; convert to `rl.Sound` separately |
| `TEXT` | `.text`            | `load_text_from_resource(chunk)` | Returns a V `string`; RL_MALLOC memory freed internally |
| `FNTG` + `IMGE` | `.font_glyphs` + `.image` | `load_font_from_resource(multi)` | Multi-chunk; requires `load_multi` |
| Raw bytes | `.raw` | `load_data_from_resource(chunk)` | Returns `(voidptr, u32)`; caller manages lifetime |

## Compression and encryption

Chunks can be stored compressed (DEFLATE, LZ4) and/or encrypted (XOR, AES-128, AES-256, ChaCha20). `RresLoader` calls `chunk.unpack()` transparently. If working with the low-level API directly, call `chunk.unpack()` before passing the chunk to any loader function: passing a packed chunk produces garbage or a crash. For encrypted archives, set the password before loading: `rres.set_cipher_password('secret')`.

## C sources

Compiled via `rres_ext_c.v` with `RRES_IMPLEMENTATION`, `RRES_RAYLIB_IMPLEMENTATION`, `QOI_IMPLEMENTATION`, and `RRES_SUPPORT_COMPRESSION_LZ4` defined as single-header implementations. The only file included is `rres-raylib.h`, which pulls in `rres.h` and `qoi.h` internally.