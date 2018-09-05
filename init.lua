local die

local fatal = function(
    message
)
    print(
        "FATAL: " .. message
    )
    die(
    )
end

local S

if minetest.get_modpath(
    "intllib"
) then
    S = intllib.Getter(
    )
else
    S = function(
        translated
    )
        return translated
    end
end

local sessions = {
}

minetest.register_on_rightclickplayer(
    function(
        clicked,
        clicker
    )
        local clicked_name = clicked:get_player_name(
        )
        local clicker_name = clicker:get_player_name(
        )
        if sessions[
            clicker_name
        ] then
            fatal(
                "right-clicking players should not be possible right now"
            )
        end
        if sessions[
            clicked_name
        ] then
            minetest.chat_send_player(
                clicker_name,
                string.format(
                    S(
                        "player %s is busy"
                    ),
                    clicked_name
                )
            )
            return
        end
        sessions[
            clicked_name
        ] = clicker_name
        sessions[
            clicker_name
        ] = clicked_name
        minetest.show_formspec(
            clicked_name,
            "structured_communication:main",
            "size[8,9]list[detached:offer_" .. clicked_name .. ";main;0,2;8,1;]list[detached:offer_" .. clicker_name .. ";main;0,2;8,1;]list[current_player;main;0,5;8,4;]listring[]"
        )
        minetest.show_formspec(
            clicker_name,
            "structured_communication:main",
            "size[8,9]list[detached:offer_" .. clicker_name .. ";main;0,0;8,1;]list[detached:offer_" .. clicked_name .. ";main;0,2;8,1;]list[current_player;main;0,5;8,4;]listring[]"
        )
    end
)

minetest.register_on_player_receive_fields(
    function(
        player,
        formname,
        fields
    )
        if "structured_communication:main" ~= formname then
            return false
        end
        local name = player:get_player_name(
        )
        local other = sessions[
            name
        ]
        if not other then
            fatal(
                "no other player registered"
            )
        end
        if not fields.quit then
            return true
        end
        minetest.close_formspec(
            other,
            "structured_communication:main"
        )
        minetest.chat_send_player(
            other,
            string.format(
                S(
                    "session closed by %s"
                ),
                name
            )
        )
        sessions[
            other
        ] = nil
        sessions[
            name
        ] = nil
    end
)

minetest.register_on_joinplayer(
    function(
        player
    )
        local name = player:get_player_name(
        )
        local detached = minetest.create_detached_inventory(
            "offer_" .. name,
            {
                allow_move = function(
                    inv,
                    from_list,
                    from_index,
                    to_list,
                    to_index,
                    count,
                    action_player
                )
                    return 0
                end,
                allow_put = function(
                    inv,
                    to_list,
                    to_index,
                    stack,
                    action_player
                )
                    local action_name = action_player:get_player_name(
                    )
                    if name == action_name then
                        return stack:get_count(
                        )
                    end
                    return 0
                end,
                allow_take = function(
                    inv,
                    from_list,
                    from_index,
                    stack,
                    action_player
                )
                    local action_name = action_player:get_player_name(
                    )
                    if name == action_name then
                        return stack:get_count(
                        )
                    end
                    return 0
                end,
            }
        )
        detached:set_size(
            "main",
            8
        )
    end
)
