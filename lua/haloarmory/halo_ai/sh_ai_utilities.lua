HALOARMORY.MsgC("Shared HALO AI Utilities Loading.")


HALOARMORY.AI = HALOARMORY.AI or {}
HALOARMORY.AI.Tokens = HALOARMORY.AI.Tokens or {}

if CLIENT then
    HALOARMORY.AI.CallBackFuncs = {}

    function HALOARMORY.AI.Tokens.EncodeClientCallback( SHA, tokens, success )
        local callbackFunc = HALOARMORY.AI.CallBackFuncs[SHA]
        if callbackFunc then
            HALOARMORY.INTERFACE.CallbackFuncCaller(callbackFunc, tokens, success)
            HALOARMORY.AI.CallBackFuncs[SHA] = nil
        end
    end

end


// Use this website to count the token: https://koala.sh/tools/free-gpt-tokenizer
// It only returns a number, not the tokens.
function HALOARMORY.AI.Tokens.Encode(str, callbackFunc)

    if CLIENT then
        // We need to use the server to get the tokens.
        // First, save the callback function so we can call it later.
        local SHA = util.SHA256(str)
        HALOARMORY.AI.CallBackFuncs[SHA] = callbackFunc

        net.Start("HALOARMORY.AI")
            net.WriteString("Tokenize")
            net.WriteString(str)
            net.WriteString(SHA)
        net.SendToServer()
    end


    if SERVER then
        return HALOARMORY.AI.Tokens.Tokenize(str, function(tokens, success)
            HALOARMORY.INTERFACE.CallbackFuncCaller(callbackFunc, tokens, success)
        end)
    end
end



