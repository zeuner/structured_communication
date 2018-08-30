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
            "size[7,7]"
        )
        minetest.show_formspec(
            clicker_name,
            "structured_communication:main",
            "size[7,7]"
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
        sessions[
            other
        ] = nil
        sessions[
            name
        ] = nil
    end
)

