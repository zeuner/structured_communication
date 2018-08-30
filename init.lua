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

minetest.register_on_rightclickplayer(
    function(
        clicked,
        clicker
    )
        minetest.show_formspec(
            clicked:get_player_name(
            ),
            "structured_communication:main",
            "size[7,7]"
        )
        minetest.show_formspec(
            clicker:get_player_name(
            ),
            "structured_communication:main",
            "size[7,7]"
        )
    end
)
