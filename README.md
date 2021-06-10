# Animated Entity Textures
Created as an exercise in entity and texture handling for a Discord challenge.  

The `_tiles` key should be a table of [tiles](https://github.com/minetest/minetest/blob/5.4.1/doc/lua_api.txt#L7124-L7144). Animated tiles should use the [tile animation definition](https://github.com/minetest/minetest/blob/5.4.1/doc/lua_api.txt#L7146-L7173) (optional).  

### Minimum Example
```lua
minetest.register_entity("modname:verticalframes", {
    _tiles = {{
        name = "vertical_frames.png",
        animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 1}
    }},
})

minetest.register_entity("modname:sheet2d", {
    _tiles = {{
        name = "sheet_2d.png",
        animation = {type = "sheet_2d", frames_w = 4, frames_h = 2, frame_length = 0.25}
    }},
})
```

Set `TEST` to `true` in `init.lua` to register these testing entities.
