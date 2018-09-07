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

local agreements = {
}

local last_session = {
}

local agreement_key = function(
    clicker,
    clicked
)
    if clicker < clicked then
        return clicker .. " " .. clicked
    else
        return clicked .. " " .. clicker
    end
end

local temporary_inventory = minetest.create_detached_inventory(
    "temporary",
    {
        allow_move = function(
        )
            return 0
        end,
        allow_put = function(
        )
            return 0
        end,
        allow_take = function(
        )
            return 0
        end,
    }
)

local move_items = function(
    from,
    to
)
    for index = 1, from:get_size(
        "main"
    ) do
        local copy = from:get_stack(
            "main",
            index
        )
        if copy then
            if not to:room_for_item(
                "main",
                copy
            ) then
                return false
            end
            local taken = from:remove_item(
                "main",
                copy
            )
            to:add_item(
                "main",
                taken
            )
        end
    end
    return true
end

minetest.register_on_rightclickplayer(
    function(
        clicked,
        clicker
    )
        local clicked_name = clicked:get_player_name(
        )
        local clicker_name = clicker:get_player_name(
        )
        local clicked_offer = minetest.get_inventory(
            {
                type = "detached",
                name = "offer_" .. clicked_name,
            }
        )
        if not clicked_offer then
            fatal(
                "clicked player does not have an offer inventory"
            )
        end
        local clicker_offer = minetest.get_inventory(
            {
                type = "detached",
                name = "offer_" .. clicker_name,
            }
        )
        if not clicker_offer then
            fatal(
                "clicking player does not have an offer inventory"
            )
        end
        print(
            "clicking player offer size " .. clicker_offer:get_size(
                "main"
            )
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
        if last_session[
            clicker_name
        ] ~= clicked_name then
            if not move_items(
                clicker_offer,
                minetest.get_inventory(
                    {
                        type = "player",
                        name = clicker_name,
                    }
                )
            ) then
                minetest.chat_send_player(
                    clicker_name,
                    S(
                        "please make room in your inventory"
                    )
                )
                return
            end
            last_session[
                clicker_name
            ] = clicked_name
        end
        if last_session[
            clicked_name
        ] ~= clicker_name then
            if not move_items(
                clicked_offer,
                minetest.get_inventory(
                    {
                        type = "player",
                        name = clicked_name,
                    }
                )
            ) then
                minetest.chat_send_player(
                    clicked_name,
                    S(
                        "please make room in your inventory"
                    )
                )
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
            last_session[
                clicker_name
            ] = clicked_name
        end
        agreements[
            agreement_key(
                clicker_name,
                clicked_name
            )
        ] = {
        }
        sessions[
            clicked_name
        ] = clicker_name
        sessions[
            clicker_name
        ] = clicked_name
        local formspec
        formspec = ""
        formspec = formspec .. "size[8,9]"
        formspec = formspec .. "list[detached:offer_" .. clicked_name .. ";main;0,0;8,1;]"
        formspec = formspec .. "list[detached:offer_" .. clicker_name .. ";main;0,2;8,1;]"
        formspec = formspec .. "button[0,3.5;3,1;accept;Accept]"
        formspec = formspec .. "button[4,3.5;3,1;retract;Retract]"
        formspec = formspec .. "list[current_player;main;0,5;8,4;]"
        minetest.show_formspec(
            clicked_name,
            "structured_communication:main",
            formspec
        )
        formspec = ""
        formspec = formspec .. "list[detached:offer_" .. clicker_name .. ";main;0,0;8,1;]"
        formspec = formspec .. "list[detached:offer_" .. clicked_name .. ";main;0,2;8,1;]"
        formspec = formspec .. "button[0,3.5;3,1;accept;Accept]"
        formspec = formspec .. "button[4,3.5;3,1;retract;Retract]"
        formspec = formspec .. "list[current_player;main;0,5;8,4;]"
        minetest.show_formspec(
            clicker_name,
            "structured_communication:main",
            formspec
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
        if fields.quit then
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
            agreements[
                agreement_key(
                    name,
                    other
                )
            ] = nil
            sessions[
                other
            ] = nil
            sessions[
                name
            ] = nil
            return true
        end
        if fields.accept then
            if not agreements[
                agreement_key(
                    name,
                    other
                )
            ][
                name
            ] then
                agreements[
                    agreement_key(
                        name,
                        other
                    )
                ][
                    name
                ] = true
                minetest.chat_send_player(
                    other,
                    string.format(
                        S(
                            "%s has accepted your offer"
                        ),
                        name
                    )
                )
                if agreements[
                    agreement_key(
                        name,
                        other
                    )
                ][
                    other
                ] then
                    local own_offer = minetest.get_inventory(
                        {
                            type = "detached",
                            name = "offer_" .. name,
                        }
                    )
                    local other_offer = minetest.get_inventory(
                        {
                            type = "detached",
                            name = "offer_" .. other,
                        }
                    )
                    temporary_inventory:set_list(
                        "main",
                        own_offer:get_list(
                            "main"
                        )
                    )
                    own_offer:set_list(
                        "main",
                        other_offer:get_list(
                            "main"
                        )
                    )
                    other_offer:set_list(
                        "main",
                        temporary_inventory:get_list(
                            "main"
                        )
                    )
                    minetest.chat_send_player(
                        name,
                        S(
                            "the trade has been completed"
                        )
                    )
                    minetest.chat_send_player(
                        other,
                        S(
                            "the trade has been completed"
                        )
                    )
                    agreements[
                        agreement_key(
                            name,
                            other
                        )
                    ] = {
                    }
                end
            end
            return true
        end
        if fields.retract then
            if agreements[
                agreement_key(
                    name,
                    other
                )
            ][
                name
            ] then
                agreements[
                    agreement_key(
                        name,
                        other
                    )
                ][
                    name
                ] = nil
                minetest.chat_send_player(
                    other,
                    string.format(
                        S(
                            "offer by %s has been retracted"
                        ),
                        name
                    )
                )
            end
            return true
        end
        return false
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
                on_take = function(
                    inv,
                    from_list,
                    from_index,
                    stack,
                    action_player
                )
                    local other = sessions[
                        name
                    ]
                    if agreements[
                        agreement_key(
                            name,
                            other
                        )
                    ][
                        other
                    ] then
                        agreements[
                            agreement_key(
                                name,
                                other
                            )
                        ][
                            other
                        ] = nil
                        minetest.chat_send_player(
                            name,
                            string.format(
                                S(
                                    "offer acceptance by %s invalidated"
                                ),
                                other
                            )
                        )
                    end
                end,
            }
        )
        detached:set_size(
            "main",
            8
        )
    end
)
