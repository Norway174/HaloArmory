HALOARMORY.MsgC("Server HALO AI Tokenizer Loading.")

HALOARMORY.AI = HALOARMORY.AI or {}
HALOARMORY.AI.Tokens = HALOARMORY.AI.Tokens or {}


local TOKENIZER_API_URL = "https://koala.sh/api/tokens/"



function HALOARMORY.AI.Tokens.Tokenize(str, callbackFunc)

    local success = HTTP( {
        url = TOKENIZER_API_URL,
        method = "POST",
        type = "application/json",
        body = util.TableToJSON({["text"] = str}),
        success = function(code, body, headers )

            if code == 200 then
                local josn_body = util.JSONToTable(body)
                
                if josn_body["tokens"] then

                    HALOARMORY.INTERFACE.CallbackFuncCaller(callbackFunc, josn_body["tokens"], true)

                else
                    HALOARMORY.MsgC( Color(255,0,0), "Failed to get token from API. Error: ", Color(255,174,0), body)
                    HALOARMORY.INTERFACE.CallbackFuncCaller(callbackFunc, 0, false)
                end

            else
                HALOARMORY.MsgC( Color(255,0,0), "Failed to get token from API. Error code: ", Color(255,174,0), code)
                HALOARMORY.INTERFACE.CallbackFuncCaller(callbackFunc, 0, false)
            end

        end,
        failed = function(error)
            HALOARMORY.MsgC( Color(255,0,0), "Failed to get token from API. Error: ", Color(255,174,0), error)
            HALOARMORY.INTERFACE.CallbackFuncCaller(callbackFunc, 0, false)
        end
    } )

    return success
end