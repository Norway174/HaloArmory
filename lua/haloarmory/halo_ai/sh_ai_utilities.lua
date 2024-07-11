HALOARMORY.MsgC("Shared HALO AI Utilities Loading.")


HALOARMORY.AI = HALOARMORY.AI or {}
HALOARMORY.AI.Tokens = HALOARMORY.AI.Tokens or {}

// Tokens: HALOARMORY.AI.Tokens.cl100_base

// Encode takes a string and returns the amount of tokens, and a table of tokens.
// First, check if string is a token. If it is, we add it to the table of tokens.
// If the word is not a token, we remove the last character from the word, and check if it is a token. Repeat until the word is a token, or the word is empty.
// Then we take the removed characters, and check if they are tokens. If they are, we add them to the table of tokens, and remove them from the table of words.
// Repeat until the table of words is empty.
function HALOARMORY.AI.Tokens.Encode(str)
    local tokens = {}
    local startIndex = 1

    while startIndex <= #str do
        local wordFound = false
        local maxWordLength = #str - startIndex + 1

        for i = maxWordLength, 1, -1 do
            local word = string.sub(str, startIndex, startIndex + i - 1)
            local encodedWord = util.Base64Encode(word)

            if HALOARMORY.AI.Tokens.cl100_base[encodedWord] then
                local token = {
                    [word] = HALOARMORY.AI.Tokens.cl100_base[encodedWord],
                }
                table.insert(tokens, token)
                startIndex = startIndex + i
                wordFound = true
                break
            end
        end

        if not wordFound then
            -- No matching word found, add the character as a token
            local char = string.sub(str, startIndex, startIndex)
            print("No matching word found, adding character as token: " .. char)
            table.insert(tokens, char)
            startIndex = startIndex + 1
        end
    end

    return #tokens, tokens
end



