local convert = require("lib.convert")

describe("convert: basic conversions", function()
    it("dec2hex small values", function()
        assert.are.equal("0",    convert.dec2hex("0"))
        assert.are.equal("a",    convert.dec2hex("10"))
        assert.are.equal("ff",   convert.dec2hex("255"))
        assert.are.equal("100",  convert.dec2hex("256"))
        assert.are.equal("dead", convert.dec2hex("57005"))
    end)

    it("hex2dec small values", function()
        assert.are.equal("0",     convert.hex2dec("0"))
        assert.are.equal("10",    convert.hex2dec("a"))
        assert.are.equal("255",   convert.hex2dec("ff"))
        assert.are.equal("57005", convert.hex2dec("dead"))
    end)

    it("hex2dec accepts uppercase", function()
        assert.are.equal("255",   convert.hex2dec("FF"))
        assert.are.equal("57005", convert.hex2dec("DEAD"))
    end)

    it("dec2bin small values", function()
        assert.are.equal("0",     convert.dec2bin("0"))
        assert.are.equal("101",   convert.dec2bin("5"))
        assert.are.equal("11111111", convert.dec2bin("255"))
    end)

    it("bin2dec small values", function()
        assert.are.equal("0",   convert.bin2dec("0"))
        assert.are.equal("5",   convert.bin2dec("101"))
        assert.are.equal("255", convert.bin2dec("11111111"))
    end)

    it("dec2oct and oct2dec", function()
        assert.are.equal("77", convert.dec2oct("63"))
        assert.are.equal("63", convert.oct2dec("77"))
    end)

    it("hex2bin and bin2hex", function()
        assert.are.equal("11111111", convert.hex2bin("ff"))
        assert.are.equal("ff",       convert.bin2hex("11111111"))
    end)

    it("oct2bin and bin2oct", function()
        assert.are.equal("111111", convert.oct2bin("77"))
        assert.are.equal("77",     convert.bin2oct("111111"))
    end)

    it("hex2oct and oct2hex", function()
        assert.are.equal("377", convert.hex2oct("ff"))
        assert.are.equal("ff",  convert.oct2hex("377"))
    end)
end)

describe("convert: roundtrip identity", function()
    local pairs_to_test = {
        {convert.dec2hex, convert.hex2dec, {"0", "10", "255", "1024", "65535"}},
        {convert.dec2bin, convert.bin2dec, {"0", "5", "255", "1024"}},
        {convert.dec2oct, convert.oct2dec, {"0", "8", "63", "1024"}},
        {convert.hex2bin, convert.bin2hex, {"0", "ff", "dead"}},
    }
    for _, triple in ipairs(pairs_to_test) do
        local forward, backward, inputs = triple[1], triple[2], triple[3]
        for _, input in ipairs(inputs) do
            it("roundtrips " .. input, function()
                local converted = forward(input)
                assert.are.equal(input, backward(converted))
            end)
        end
    end
end)

describe("convert: negative numbers", function()
    it("dec2hex preserves negative sign", function()
        assert.are.equal("-ff",   convert.dec2hex("-255"))
        assert.are.equal("-100",  convert.dec2hex("-256"))
    end)

    it("hex2dec preserves negative sign", function()
        assert.are.equal("-255",   convert.hex2dec("-ff"))
    end)

    it("bin2dec preserves negative sign", function()
        assert.are.equal("-5", convert.bin2dec("-101"))
    end)
end)

describe("convert: empty selection", function()
    it("returns nil for empty input", function()
        assert.is_nil(convert.dec2hex(""))
        assert.is_nil(convert.hex2dec(""))
        assert.is_nil(convert.bin2dec(""))
    end)
end)

describe("convert: invalid input returns literal nil string", function()
    it("non-digit characters in dec input", function()
        assert.are.equal("nil", convert.dec2hex("abc"))
        assert.are.equal("nil", convert.dec2hex("xyz"))
    end)

    it("non-digit characters in hex input", function()
        assert.are.equal("nil", convert.hex2dec("xyz"))
        assert.are.equal("nil", convert.hex2dec("g"))
    end)

    it("non-digit characters in bin input", function()
        assert.are.equal("nil", convert.bin2dec("2"))
        assert.are.equal("nil", convert.bin2dec("abc"))
    end)
end)

describe("convert: whitespace handling", function()
    it("tonumber trims leading and trailing whitespace", function()
        assert.are.equal("255", convert.hex2dec("  ff  "))
        assert.are.equal("ff",  convert.dec2hex(" 255 "))
    end)
end)

describe("convert: prefix handling when matching from-base", function()
    it("hex2dec strips 0x prefix", function()
        assert.are.equal("255", convert.hex2dec("0xff"))
    end)

    it("hex2dec accepts uppercase 0X prefix", function()
        assert.are.equal("255", convert.hex2dec("0XFF"))
    end)

    it("bin2dec strips 0b prefix", function()
        assert.are.equal("5", convert.bin2dec("0b101"))
    end)

    it("oct2dec strips 0o prefix", function()
        assert.are.equal("63", convert.oct2dec("0o77"))
    end)

    it("sign is preserved across prefix strip", function()
        assert.are.equal("-255", convert.hex2dec("-0xff"))
        assert.are.equal("-5",   convert.bin2dec("-0b101"))
        assert.are.equal("-63",  convert.oct2dec("-0o77"))
    end)
end)

describe("convert: prefix not stripped when mismatching from-base", function()
    it("bin2dec rejects 0xff because 0x is not a binary prefix", function()
        assert.are.equal("nil", convert.bin2dec("0xff"))
    end)

    it("hex2dec on 0bff parses as hex 0xbff", function()
        -- 0b is not stripped (base is 16, not 2). All chars are valid
        -- hex digits, so tonumber parses the literal as base-16 0xbff.
        assert.are.equal("3071", convert.hex2dec("0bff"))
    end)

    it("dec2hex rejects 0x10 because base 10 has no prefix", function()
        assert.are.equal("nil", convert.dec2hex("0x10"))
    end)

    it("oct2dec rejects 0xff because 0x is not an octal prefix", function()
        assert.are.equal("nil", convert.oct2dec("0xff"))
    end)
end)
