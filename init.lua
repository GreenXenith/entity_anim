local TEST = false

local function get_file_dimensions(path)
    local f = io.open(path, "rb")
    f:seek("set", 1)
    if f:read(3) == "PNG" then
        f:seek("set", 16)
        return {
            w = tonumber(string.format("0x%x%x%x%x", f:read(4):byte(1, 4))),
            h = tonumber(string.format("0x%x%x%x%x", f:read(4):byte(1, 4))),
        }
    end
end

local function find_textures(path, files)
    files = files or {}
    for _, filename in pairs(minetest.get_dir_list(path, false)) do
        if filename:sub(-4) == ".png" then
            files[filename] = get_file_dimensions(path .. "/" .. filename)
        end
    end

    for _, dir in pairs(minetest.get_dir_list(path, true)) do
        files = find_textures(path .. "/" .. dir, files)
    end

    return files
end

-- List of dimensions for all textures
local texturelist = {}
for _, modname in pairs(minetest.get_modnames()) do
    texturelist = find_textures(minetest.get_modpath(modname), texturelist)
end

local old_dynamic_add = minetest.dynamic_add_media
minetest.dynamic_add_media = function(filepath, ...)
    local success = old_dynamic_add(filepath, ...)
    if success then texturelist[filepath:match("[^/\\]+$")] = get_file_dimensions(filepath) end
    return success
end

-- Animation handler
minetest.register_globalstep(function(dtime)
    for _, ent in pairs(minetest.luaentities) do
        -- _tiles and properties must exist
        if ent._tiles and ent.object:get_properties() then
            local textures = ent.object:get_properties().textures
            local tiles = table.copy(ent._tiles)

            for i, tile in pairs(tiles) do
                if type(tile) == "table" then
                    if tile.animation then
                        local anim = tile.animation
                        assert(anim.type and (anim.type == "vertical_frames" or anim.type == "sheet_2d"), ("Invalid animated tile type in entity '%s'."):format(ent.name))

                        tiles[i]._timer = (tile._timer or 0) + dtime
                        tiles[i]._frame = tile._frame or 0

                        local size = texturelist[tile.name] or {w = 16, h = 16}

                        if anim.type == "vertical_frames" then
                            assert(anim.aspect_w and anim.aspect_h and anim.length, ("Invalid vertical_frames animation definition in entity '%s'."):format(ent.name))
                            -- height / frame height (width / aspect ratio)
                            local total_frames = size.h / (size.w * (anim.aspect_h / anim.aspect_w))

                            -- floor(timer / seconds per frame)
                            tile._frame = math.floor(tile._timer / (anim.length / total_frames)) % total_frames
                            tile._timer = tile._timer % anim.length

                            textures[i] = ("%s^[verticalframe:%s:%s"):format(tile.name, total_frames, tile._frame)
                        else -- type == "sheet_2d"
                            assert(anim.frames_w and anim.frames_h and anim.frame_length, ("Invalid sheet_2d animation definition in entity '%s'."):format(ent.name))
                            local total_frames = anim.frames_w * anim.frames_h
                            local tile_w, tile_h = size.w / anim.frames_w, size.h / anim.frames_h

                            tile._frame = math.floor((tile._timer / anim.frame_length)) % total_frames
                            tile._timer = tile._timer % (total_frames * anim.frame_length)

                            textures[i] = ("[combine:%sx%s:%s,%s=%s"):format(tile_w, tile_h, -(tile._frame % anim.frames_w) * tile_h, -math.floor(tile._frame / anim.frames_w) * tile_w, tile.name)
                        end
                    else
                        textures[i] = tile.name
                    end
                else
                    textures[i] = tile
                end
            end

            ent._tiles = tiles
            ent.object:set_properties({textures = textures})
        end
    end
end)

-- Test
if TEST then
    local speed = 1
    minetest.register_entity("entity_anim:verticalframes", {
        _tiles = {{name = "entity_anim_test_verticalframes.png", animation = {type = "vertical_frames", aspect_w = 1, aspect_h = 1, length = speed}}}
    })
    
    minetest.register_entity("entity_anim:sheet2d", {
        _tiles = {{name = "entity_anim_test_sheet2d.png", animation = {type = "sheet_2d", frames_w = 2, frames_h = 2, frame_length = speed / 4}}}
    })
end
